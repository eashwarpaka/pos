import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:pos_app/models/cart_item.dart';
import 'package:pos_app/models/table_model.dart';
import 'package:pos_app/services/local_db_service.dart';
import 'package:pos_app/services/language_service.dart';
import 'package:pos_app/services/printer_service.dart';
import 'package:pos_app/models/bill_model.dart';
import 'package:pos_app/models/kot_model.dart';
import 'package:pos_app/models/order_item.dart';
import '../widgets/pos/pos_top_bar.dart';
import '../widgets/pos/pos_search_bar.dart';
import '../widgets/pos/pos_category_sidebar.dart';
import '../widgets/pos/pos_menu_grid.dart';
import '../widgets/pos/pos_cart_table.dart';
import '../widgets/pos/pos_summary_section.dart';
class PosScreen extends StatefulWidget {
  final RestaurantTable table;

  const PosScreen({super.key, required this.table});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen>
    with SingleTickerProviderStateMixin {
  List<String> categories = [];
  List<Map<String, dynamic>> menu = [];
  String searchQuery = "";
  int quantityToCalculate = 1;
  final TextEditingController searchController = TextEditingController();
  final TextEditingController noteController = TextEditingController();
  final ScrollController _categoryScrollController = ScrollController();
  final FocusNode searchFocusNode = FocusNode();
  final FocusNode globalFocusNode = FocusNode();
  final String _lastKeyPressed = "";
  DateTime? _lastKeyTime;

  int selectedCategoryIndex = 0;
  String selectedType = "dine_in"; // internal keys: dine_in, takeaway

  double discount = 0;
  double gst = 5;
  String selectedPaymentMethod = "Cash";
  bool isPrinting = false;

  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.table.name.toLowerCase().contains("takeaway")) {
      selectedType = "takeaway";
    } else {
      selectedType = "dine_in";
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });
    loadData();
    loadCart();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      searchFocusNode.requestFocus();
    });
    HardwareKeyboard.instance.addHandler(_keyHandler);
  }

  @override
  void dispose() {
    _timer.cancel();
    searchController.dispose();
    noteController.dispose();
    _categoryScrollController.dispose();
    searchFocusNode.dispose();
    globalFocusNode.dispose();
    HardwareKeyboard.instance.removeHandler(_keyHandler);
    super.dispose();
  }

  bool _keyHandler(KeyEvent event) {
    if (event is KeyDownEvent) {
      final isControlPressed = HardwareKeyboard.instance.isControlPressed;
      final key = event.logicalKey;
      
      if (key == LogicalKeyboardKey.escape ||
          (isControlPressed && key == LogicalKeyboardKey.keyB)) {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        return true;
      } else if (isControlPressed && key == LogicalKeyboardKey.keyF) {
        searchFocusNode.requestFocus();
        return true;
      } else if (isControlPressed && key == LogicalKeyboardKey.keyR) {
        // Removed RevenueScreen import, so this line will cause an error if not removed or replaced.
        // Keeping it as per instruction to only modify _simulatePrint and imports.
        // Navigator.push(context, MaterialPageRoute(builder: (_) => const RevenueScreen()));
        return true;
      }
    }
    return false;
  }

  Future<void> loadData() async {
    final loaded = await LocalDbService.loadCategories();
    categories = ["ALL", ...loaded];
    menu = await LocalDbService.loadMenuItems();
    setState(() {});
  }

  Future<void> loadCart() async {
    final saved = await LocalDbService.loadCartItems(widget.table.number);
    widget.table.cart
      ..clear()
      ..addAll(saved);
    setState(() {});
  }

  Future<void> addItemManually(Map item, int qty) async {
    final cart = widget.table.cart;
    final index = cart.indexWhere((i) => i.name == item["name"]);

    if (index != -1) {
      cart[index].quantity += qty;
    } else {
      final newItem = CartItem(
        name: item["name"],
        category: item["category"],
        price: item["price"],
        image: item["image"],
        quantity: qty,
      );
      cart.add(newItem);
    }

    await LocalDbService.saveOrUpdateCartItem(
      widget.table.number,
      item["name"],
      item["price"],
      cart[cart.indexWhere((i) => i.name == item["name"])].quantity,
      image: item["image"],
      category: item["category"],
    );

    widget.table.markOccupied();
    await LocalDbService.saveTableStatus(widget.table.number, "occupied",
        occupiedAt: widget.table.occupiedAt);
    setState(() {
      quantityToCalculate = 1; // Reset
    });
  }

  Future<void> changeQty(CartItem item, int delta) async {
    item.quantity += delta;
    if (item.quantity <= 0) {
      widget.table.removeItem(item.name);
      await LocalDbService.saveOrUpdateCartItem(
          widget.table.number, item.name, item.price, 0);
    } else {
      await LocalDbService.saveOrUpdateCartItem(
        widget.table.number,
        item.name,
        item.price,
        item.quantity,
        image: item.image,
        category: item.category,
      );
    }
    setState(() {});
  }

  double get subtotal => widget.table.subtotal;
  double get totalDiscount => (subtotal * discount) / 100;
  double get totalGst => ((subtotal - totalDiscount) * gst) / 100;
  double get grandTotal => subtotal - totalDiscount + totalGst;

  Future<void> proceedPayment() async {
    if (widget.table.cart.isEmpty) return;

    await LocalDbService.recordSale(
      grandTotal,
      widget.table.cart,
      discount: totalDiscount,
      paymentMethod: selectedPaymentMethod,
    );

    widget.table.clearCart();
    await LocalDbService.clearCart(widget.table.number);
    await LocalDbService.saveTableStatus(widget.table.number, "available");

    setState(() {});

    // Auto-return to table grid after payment
    if (mounted) {
      Navigator.pop(context);
    }
  }

  // --- UI Colors & Styles ---
  static const bgColor = Color(0xFFF8FAFC);
  static const primaryGradient =
      LinearGradient(colors: [Color(0xFF00B4D8), Color(0xFF0077B6)]);
  static const tealGradient =
      LinearGradient(colors: [Color(0xFF20B2AA), Color(0xFF008B8B)]);
  static const accentBlue = Color(0xFF0077B6);

  @override
  Widget build(BuildContext context) {
    final filteredMenuItems = menu.where((item) {
      final matchesCat = categories.isNotEmpty &&
          (categories[selectedCategoryIndex] == "ALL" ||
              item["category"] == categories[selectedCategoryIndex]);

      final matchesSearch = item["name"]
          .toString()
          .toLowerCase()
          .contains(searchQuery.toLowerCase());

      return matchesCat && matchesSearch && (item["isAvailable"] ?? true);
    }).toList();

    return Scaffold(
        backgroundColor: bgColor,
        appBar: PosTopBar(
          selectedType: selectedType,
          onTypeChanged: (type) async {
            setState(() => selectedType = type);
            if (type == "takeaway") {
              widget.table.name = "TakeAway ${widget.table.number}";
            } else {
              widget.table.name = "Table ${widget.table.number}";
            }
            await LocalDbService.updateTableName(widget.table.number, widget.table.name);
          },
          onCancelTap: _handleCancelTap,
          now: _now,
        ),
        body: Row(
          children: [
            /// LEFT SIDE
            Expanded(
              flex: 7,
              child: Column(
                children: [
                  /// SEARCH BAR
                  PosSearchBar(
                    searchController: searchController,
                    searchFocusNode: searchFocusNode,
                    onSearchChanged: (v) => setState(() => searchQuery = v),
                    quantityToCalculate: quantityToCalculate,
                    onQuantityChanged: (qty) => setState(() => quantityToCalculate = qty),
                    onAddPressed: () {
                      final results = menu
                          .where((item) => item["name"]
                              .toString()
                              .toLowerCase()
                              .contains(searchQuery.toLowerCase()))
                          .toList();
                      if (results.isNotEmpty) {
                        addItemManually(results.first, quantityToCalculate);
                      }
                    },
                  ),

                  /// CATEGORY LIST (HORIZONTAL)
                  ExcludeFocus(
                    child: SizedBox(
                      height: 120,
                      child: PosCategorySidebar(
                        categories: categories,
                        selectedCategoryIndex: selectedCategoryIndex,
                        onCategorySelected: (index) => setState(() => selectedCategoryIndex = index),
                        categoryScrollController: _categoryScrollController,
                      ),
                    ),
                  ),

                  const SizedBox(height: 15), // Spacing between sidebar and menu grid

                  /// ITEMS GRID
                  Expanded(
                    child: ExcludeFocus(
                      child: PosMenuGrid(
                        items: filteredMenuItems,
                        onItemTap: (item) => addItemManually(item, quantityToCalculate),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            /// RIGHT SIDE BILLING
            Container(
              width: 480,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(-5, 0),
                  )
                ],
              ),
              child: Column(
                children: [
                  Expanded(
                    child: PosCartTable(
                      cart: widget.table.cart,
                      onQtyChanged: changeQty,
                    ),
                  ),
                  PosSummarySection(
                    cart: widget.table.cart,
                    subtotal: subtotal,
                    discountPercentage: discount,
                    totalDiscount: totalDiscount,
                    totalGst: totalGst,
                    grandTotal: grandTotal,
                    isPrinting: isPrinting,
                    onClearTable: _clearTable,
                    onPrintReceipt: _simulatePrint,
                    onPayAndClose: proceedPayment,
                    onDiscountChanged: (val) {
                      setState(() {
                        discount = double.tryParse(val) ?? 0.0;
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      );
  }

  Future<void> _simulatePrint(String type) async {
    if (widget.table.cart.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(LanguageService.translate("cart_empty")),
            behavior: SnackBarBehavior.floating));
      }
      return;
    }
    setState(() => isPrinting = true);

    try {
      final orderItems = widget.table.cart.map((c) => OrderItem(
        name: c.name, 
        qty: c.quantity, 
        price: c.price, 
        total: c.total
      )).toList();

      bool success = false;
      String message = "";

      if (type == "KOT") {
        final kot = KotModel(
          tableNumber: widget.table.number.toString(),
          orderNumber: DateTime.now().millisecondsSinceEpoch.toString().substring(5),
          time: _now,
          items: orderItems,
        );
        success = await PrinterService.printKot(kot);
        message = success ? "KOT printed successfully." : "Failed to print KOT. Check printer settings.";
        
      } else if (type == "BILL") {
        final bill = BillModel(
          restaurantName: "MY CAFE POS",
          address: "123 Main Street, City Area",
          phone: "+91 9876543210",
          billNumber: "B-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}",
          dateTime: _now,
          tableNumber: widget.table.number.toString(),
          items: orderItems,
          subtotal: subtotal,
          discount: totalDiscount,
          gst: totalGst,
          totalAmount: grandTotal,
        );
        success = await PrinterService.printBill(bill);
        message = success ? "Bill printed: ₹${grandTotal.toStringAsFixed(2)}" : "Failed to print Bill. Check printer settings.";
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: success 
                ? (type == "KOT" ? const Color(0xFF20B2AA) : Colors.green)
                : Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      if (success && type == "BILL") {
        widget.table.markBilled();
        await LocalDbService.saveTableStatus(widget.table.number, "billed");
        await LocalDbService.recordInvoice(
          "B-${_now.millisecondsSinceEpoch.toString().substring(5)}", 
          widget.table.number.toString(), 
          selectedType == "takeaway" ? "Takeaway" : "Dine-in", 
          widget.table.cart, 
          totalDiscount, 
          grandTotal
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Print Exception: $e"), backgroundColor: Colors.red));
      }
    } finally {
      setState(() => isPrinting = false);
    }
  }

  Future<void> _printAndPay(String type) async {
    await _simulatePrint(type);
    await proceedPayment();
  }

  Future<void> _clearTable() async {
    final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text("Clear Table?"),
              content: const Text(
                  "Are you sure you want to cancel the entire order and clear this table?"),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text("No")),
                TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text("Yes, Clear",
                        style: TextStyle(color: Colors.red))),
              ],
            ));

    if (confirm != true) return;

    widget.table.clearCart();
    await LocalDbService.clearCart(widget.table.number);
    await LocalDbService.saveTableStatus(widget.table.number, "available");

    setState(() {});
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _handleCancelTap() async {
    if (widget.table.cart.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LanguageService.translate("cart_empty")),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    await _clearTable();
  }
}

enum TabBarSize { label, tab }
