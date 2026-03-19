import 'package:flutter/material.dart';
import 'package:pos_app/services/local_db_service.dart';
import 'package:pos_app/services/language_service.dart';
import 'package:pos_app/settings/printer_settings.dart';
import 'package:pos_app/services/usb_printer_service.dart';
import 'package:pos_app/services/bluetooth_printer_service.dart';
import 'package:flutter_pos_printer_platform_image_3/flutter_pos_printer_platform_image_3.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final categoryController = TextEditingController();
  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final imageController = TextEditingController();
  final searchController = TextEditingController();

  String? selectedCategory;
  String itemSearchQuery = "";
  bool isNewItemNonVeg = false;

  List<String> categories = [];
  List<Map<String, dynamic>> menu = [];
  bool isLoading = true;

  // ================= UTILITIES =================
  Future<void> clearHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Clear History",
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
            "This will permanently delete all sales and transaction history. This action cannot be undone."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
            child: const Text("Delete History"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await LocalDbService.clearHistory();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("All history cleared successfully"),
            behavior: SnackBarBehavior.floating));
      }
    }
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) loadData();
    });
  }

  // ================= LOAD DB =================
  Future<void> loadData() async {
    categories = await LocalDbService.loadCategories();
    menu = await LocalDbService.loadMenuItems();

    if (categories.isNotEmpty && selectedCategory == null) {
      selectedCategory = categories.first;
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  // ================= ADD CATEGORY =================
  Future<void> addCategory() async {
    final text = categoryController.text.trim();
    if (text.isEmpty) return;

    await LocalDbService.addCategory(text);
    categoryController.clear();
    await loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Category '$text' added"),
          behavior: SnackBarBehavior.floating));
    }
  }

  // ================= DELETE CATEGORY =================
  Future<void> deleteCategory(String name) async {
    final confirm = await _confirmAction("Delete Category?",
        "Are you sure you want to delete '$name'? This will also delete all items in this category.");
    if (confirm != true) return;

    final db = await LocalDbService.database;
    await db.delete("categories", where: "name = ?", whereArgs: [name]);
    await db.delete("menu", where: "category = ?", whereArgs: [name]);

    if (selectedCategory == name) selectedCategory = null;
    await loadData();
  }

  // ================= ADD ITEM =================
  Future<void> addItem() async {
    final name = nameController.text.trim();
    final priceText = priceController.text.trim();
    final image = imageController.text.trim();

    if (name.isEmpty || priceText.isEmpty || selectedCategory == null) {
      _showError("Please fill name and price, and select a category.");
      return;
    }

    final price = double.tryParse(priceText);
    if (price == null) {
      _showError("Invalid price format.");
      return;
    }

    await LocalDbService.addMenuItem(name, price, selectedCategory!, image,
        isAvailable: 1,
        isNonVeg: isNewItemNonVeg ? 1 : 2); // 2 means explicitly Veg

    nameController.clear();
    priceController.clear();
    imageController.clear();
    setState(() {
      isNewItemNonVeg = false;
    });
    await loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Item '$name' added to $selectedCategory"),
          behavior: SnackBarBehavior.floating));
    }
  }

  // ================= DELETE ITEM =================
  Future<void> deleteItem(String name) async {
    final confirm = await _confirmAction(
        "Delete Item?", "Are you sure you want to delete '$name'?");
    if (confirm != true) return;

    final db = await LocalDbService.database;
    await db.delete("menu", where: "name = ?", whereArgs: [name]);
    await loadData();
  }

  // ================= TOGGLE AVAILABILITY =================
  Future<void> toggleItemAvailability(Map<String, dynamic> item) async {
    final newStatus = item["isAvailable"] == true ? 0 : 1;
    final db = await LocalDbService.database;
    await db.update("menu", {"isAvailable": newStatus},
        where: "id = ?", whereArgs: [item["id"]]);
    await loadData();
  }

  // ================= TOGGLE VEG STATUS =================
  Future<void> toggleItemVegStatus(Map<String, dynamic> item) async {
    final newStatus = item["isNonVeg"] == true
        ? 2
        : 1; // 2 = Explicitly Veg, 1 = Explicitly Non-Veg
    final db = await LocalDbService.database;
    await db.update("menu", {"isNonVeg": newStatus},
        where: "id = ?", whereArgs: [item["id"]]);
    await loadData();
  }

  Future<bool?> _confirmAction(String title, String content) {
    return showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Text(title,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              content: Text(content),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text("Cancel")),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white),
                  child: const Text("Confirm"),
                ),
              ],
            ));
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating));
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = menu.where((item) {
      final matchesCat = item["category"] == selectedCategory;
      final matchesSearch = item["name"]
          .toString()
          .toLowerCase()
          .contains(itemSearchQuery.toLowerCase());
      return matchesCat && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFF8C00), Color(0xFFFF4500)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                  color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white)),
                  const SizedBox(width: 12),
                  Text(LanguageService.translate("system_mgmt"),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.white)),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: OutlinedButton.icon(
                      onPressed: clearHistory,
                      icon: const Icon(Icons.cleaning_services,
                          size: 18, color: Colors.white),
                      label: const Text("Terminal Reset",
                          style: TextStyle(color: Colors.white)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white70),
                        backgroundColor: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : Row(
              children: [
                // ===== LEFT PANEL: CATEGORIES & TOOLS =====
                Container(
                  width: 350,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(right: BorderSide(color: Colors.grey[200]!)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Categories",
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 4)
                                ],
                              ),
                              child: TextField(
                                controller: categoryController,
                                decoration: InputDecoration(
                                  hintText: "Add new category...",
                                  suffixIcon: InkWell(
                                    onTap: addCategory,
                                    borderRadius: BorderRadius.circular(50),
                                    child: const Icon(Icons.add_circle,
                                        color: Colors.orange, size: 28),
                                  ),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                                ),
                                onSubmitted: (_) => addCategory(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: categories.isEmpty
                            ? Center(
                                child: Text("No categories added",
                                    style: TextStyle(color: Colors.grey[400])))
                            : ListView.builder(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                itemCount: categories.length,
                                itemBuilder: (_, i) {
                                  final cat = categories[i];
                                  final isSelected = selectedCategory == cat;
                                  return Container(
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.orange.withOpacity(0.08)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: ListTile(
                                      selected: isSelected,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      title: Text(cat,
                                          style: TextStyle(
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                              color: isSelected
                                                  ? Colors.orange
                                                  : Colors.black87)),
                                      onTap: () => setState(
                                          () => selectedCategory = cat),
                                      trailing: isSelected
                                          ? IconButton(
                                              icon: const Icon(
                                                  Icons.delete_sweep_outlined,
                                                  size: 20,
                                                  color: Colors.redAccent),
                                              onPressed: () =>
                                                  deleteCategory(cat),
                                            )
                                          : null,
                                    ),
                                  );
                                },
                              ),
                      ),
                      const Divider(height: 1),
                      _languageSelector(),
                      const Divider(height: 1),
                      _printerSelectorTitle("Billing Printer",
                          PrinterSettings.billingPrinterId, true),
                      _printerSelectorTitle("Kitchen (KOT) Printer",
                          PrinterSettings.kitchenPrinterId, false),
                      const Divider(height: 1),
                      _infoCard(),
                    ],
                  ),
                ),

                // ===== RIGHT PANEL: ITEM MANAGEMENT =====
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.all(32),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            _headerSection(),
                            const SizedBox(height: 32),
                            _addItemForm(),
                            const SizedBox(height: 48),
                            _itemsListHeader(),
                            const SizedBox(height: 16),
                          ]),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 32)
                            .copyWith(top: 0, bottom: 32),
                        sliver: _itemsGrid(filteredItems),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _headerSection() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.inventory_2, color: Colors.orange),
        ),
        const SizedBox(width: 16),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Menu Repository",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text("Manage your restaurant's digital menu and inventory",
                style: TextStyle(color: Colors.black54)),
          ],
        ),
        ElevatedButton.icon(
          onPressed: _showMasterResetDialog,
          icon: const Icon(Icons.auto_awesome),
          label: const Text("Master Reset Menu"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.redAccent,
            side: const BorderSide(color: Colors.redAccent),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton.icon(
          onPressed: _showBulkImportDialog,
          icon: const Icon(Icons.upload_file),
          label: const Text("Bulk Import"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.orange,
            side: const BorderSide(color: Colors.orange),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  void _showMasterResetDialog() {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text("Master Reset Database?"),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              content: const Text(
                  "This will permanently DELETE your entire menu, all categories, and all sales history. You will be left with a completely blank POS system. This action cannot be undone."),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("Cancel")),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    _showSuccess("Deleting database... Please wait.");
                    try {
                      await LocalDbService.clearMenu();
                      await LocalDbService.clearHistory();
                      await loadData();
                      _showSuccess("Database wiped successfully!");
                    } catch (e) {
                      _showError("Failed to wipe database: $e");
                    }
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white),
                  child: const Text("Yes, Delete Everything"),
                )
              ],
            ));
  }

  void _showBulkImportDialog() {
    final bulkController = TextEditingController();
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text("Bulk Import Menu"),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              content: SizedBox(
                width: 500,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Format: Name, Price, Category, isNonVeg(0/1)",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.grey)),
                    const Text("Example: Chicken Burger, 150, Burgers, 1",
                        style: TextStyle(fontSize: 11, color: Colors.grey)),
                    const SizedBox(height: 15),
                    TextField(
                      controller: bulkController,
                      maxLines: 10,
                      decoration: InputDecoration(
                        hintText: "Paste your items here...",
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                        "Note: This will automatically create new categories if they don't exist.",
                        style: TextStyle(
                            fontSize: 10, color: Colors.orangeAccent)),
                  ],
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("Cancel")),
                ElevatedButton(
                  onPressed: () async {
                    final text = bulkController.text.trim();
                    if (text.isEmpty) return;

                    final lines = text.split("\n");
                    List<Map<String, dynamic>> itemsToImport = [];

                    for (var line in lines) {
                      final parts = line.split(",");
                      if (parts.length >= 3) {
                        final name = parts[0].trim();
                        final price = double.tryParse(parts[1].trim()) ?? 0.0;
                        final category = parts[2].trim();
                        final isNonVeg = parts.length > 3
                            ? (int.tryParse(parts[3].trim()) ?? 0)
                            : 0;

                        if (name.isNotEmpty && category.isNotEmpty) {
                          itemsToImport.add({
                            "name": name,
                            "price": price,
                            "category": category,
                            "isNonVeg": isNonVeg,
                          });
                        }
                      }
                    }

                    if (itemsToImport.isNotEmpty) {
                      await LocalDbService.bulkImportMenuItems(itemsToImport);
                      Navigator.pop(ctx);
                      await loadData();
                      _showSuccess(
                          "${itemsToImport.length} items imported successfully!");
                    }
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white),
                  child: const Text("Import Now"),
                )
              ],
            ));
  }

  Widget _addItemForm() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 20,
              offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Quick Add Item",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _textField(
                    nameController, "Item Name", Icons.fastfood_outlined),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _textField(
                    priceController, "Price (₹)", Icons.payments_outlined,
                    isNumber: true),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 2,
                child: _textField(imageController, "Asset Filename (opt)",
                    Icons.image_outlined),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Text("Category: ",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.black54)),
              const SizedBox(width: 8),
              Chip(
                label: Text(selectedCategory ?? "None"),
                backgroundColor: Colors.orange.withOpacity(0.1),
                labelStyle: const TextStyle(
                    color: Colors.orange, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 24),
              const Text("Type: ",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.black54)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: isNewItemNonVeg
                      ? Colors.red.withOpacity(0.1)
                      : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<bool>(
                    value: isNewItemNonVeg,
                    items: const [
                      DropdownMenuItem(
                          value: false,
                          child: Text("Veg",
                              style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold))),
                      DropdownMenuItem(
                          value: true,
                          child: Text("Non-Veg",
                              style: TextStyle(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.bold))),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => isNewItemNonVeg = val);
                    },
                    icon: Icon(Icons.arrow_drop_down,
                        color:
                            isNewItemNonVeg ? Colors.redAccent : Colors.green),
                  ),
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: addItem,
                icon: const Icon(Icons.add),
                label: const Text("Save Item to Menu"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _textField(
      TextEditingController controller, String label, IconData icon,
      {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.orange, width: 2)),
      ),
    );
  }

  Widget _itemsListHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Text("Existing Menu",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(width: 12),
            if (selectedCategory != null)
              Text("in $selectedCategory",
                  style: const TextStyle(color: Colors.black45)),
          ],
        ),
        SizedBox(
          width: 300,
          child: TextField(
            onChanged: (val) => setState(() => itemSearchQuery = val),
            decoration: InputDecoration(
              hintText: "Search in this category...",
              prefixIcon: const Icon(Icons.search, size: 20),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey[200]!)),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
        ),
      ],
    );
  }

  Widget _itemsGrid(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          height: 200,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inventory_2_outlined,
                  size: 48, color: Colors.grey[200]),
              const SizedBox(height: 16),
              Text("No items found here",
                  style: TextStyle(color: Colors.grey[400])),
            ],
          ),
        ),
      );
    }

    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        mainAxisExtent: 120,
      ),
      delegate: SliverChildBuilderDelegate(
        (_, i) {
          final item = items[i];
          final isAvailable = item["isAvailable"] == true;
          final isNonVeg = item["isNonVeg"] == true;
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: isAvailable
                      ? Colors.grey[100]!
                      : Colors.red.withOpacity(0.2)),
            ),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: _itemImage(item["image"]?.toString() ?? ""),
              title: Text(item["name"].toString(),
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isAvailable ? Colors.black87 : Colors.black38,
                      decoration:
                          isAvailable ? null : TextDecoration.lineThrough),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("₹${item["price"]}",
                      style: TextStyle(
                          color: isAvailable ? Colors.orange : Colors.grey,
                          fontWeight: FontWeight.bold)),
                  if (!isAvailable)
                    const Text("Out of Stock",
                        style: TextStyle(
                            color: Colors.red,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                ],
              ),
              trailing: SizedBox(
                width: 114,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Veg/Non-Veg Toggle
                    Tooltip(
                      message: isNonVeg ? "Change to Veg" : "Change to Non-Veg",
                      child: InkWell(
                        onTap: () => toggleItemVegStatus(item),
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: isNonVeg ? Colors.red : Colors.green),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Icon(
                            Icons.circle,
                            color: isNonVeg ? Colors.red : Colors.green,
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                    // Availability Toggle
                    Tooltip(
                      message: isAvailable ? "In Stock" : "Out of Stock",
                      child: Transform.scale(
                        scale: 0.8,
                        child: Switch(
                          value: isAvailable,
                          onChanged: (val) => toggleItemAvailability(item),
                          activeThumbColor: Colors.orange,
                          inactiveThumbColor: Colors.grey,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => deleteItem(item["name"].toString()),
                      child: const Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Icon(Icons.delete_outline,
                            color: Colors.redAccent, size: 24),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        childCount: items.length,
      ),
    );
  }

  Widget _itemImage(String path) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12)),
      child: path.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(path,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.fastfood,
                      color: Colors.orange, size: 20)),
            )
          : const Icon(Icons.fastfood, color: Colors.orange, size: 20),
    );
  }

  Widget _languageSelector() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Regional Settings",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _langChip("English"),
              _langChip("Telugu"),
              _langChip("Hindi"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _langChip(String lang) {
    bool isSelected = LanguageService.currentLanguage.value == lang;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        LanguageService.changeLanguage(lang);
        setState(() {}); // Trigger UI update for the chip itself
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? null : Border.all(color: Colors.grey[300]!),
        ),
        child: Text(lang,
            style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 12)),
      ),
    );
  }

  Widget _printerSelectorTitle(String title, String currentId, bool isBilling) {
    return InkWell(
      onTap: () => _showPrinterSelectionDialog(isBilling),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(isBilling ? Icons.receipt_long : Icons.restaurant,
                    size: 18, color: Colors.blueGrey),
                const SizedBox(width: 8),
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              currentId.isEmpty ? "Tap to configure" : currentId,
              style: TextStyle(
                  color: currentId.isEmpty ? Colors.redAccent : Colors.black54,
                  fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showPrinterSelectionDialog(bool isBilling) async {
    showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: Text("Select ${isBilling ? 'Billing' : 'Kitchen'} Printer"),
            content: SizedBox(
              width: 400,
              height: 300,
              child: FutureBuilder(
                future: Future.wait([
                  UsbPrinterService.getPrinters(),
                  Future.value(BluetoothPrinterService.getAvailableComPorts())
                ]),
                builder: (ctx, snapshot) {
                  if (!snapshot.hasData)
                    return const Center(child: CircularProgressIndicator());

                  final List<PrinterDevice> usbPrinters =
                      snapshot.data![0] as List<PrinterDevice>;
                  final List<String> comPorts =
                      snapshot.data![1] as List<String>;

                  return ListView(
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text("USB PRINTERS",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                                fontSize: 12)),
                      ),
                      if (usbPrinters.isEmpty)
                        const Text("  No USB Spooler printers found."),
                      ...usbPrinters.map((p) => ListTile(
                            leading: const Icon(Icons.usb, color: Colors.blue),
                            title: Text(p.name),
                            dense: true,
                            onTap: () async {
                              if (isBilling) {
                                await PrinterSettings.saveBillingPrinter(
                                    PrinterConnectionType.usb, p.name);
                              } else {
                                await PrinterSettings.saveKitchenPrinter(
                                    PrinterConnectionType.usb, p.name);
                              }
                              Navigator.pop(ctx);
                              setState(() {});
                            },
                          )),
                      const Divider(),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text("BLUETOOTH COM PORTS",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                                fontSize: 12)),
                      ),
                      if (comPorts.isEmpty)
                        const Text("  No Bluetooth COM ports detected."),
                      ...comPorts.map((c) => ListTile(
                            leading:
                                const Icon(Icons.bluetooth, color: Colors.blue),
                            title: Text(c),
                            dense: true,
                            onTap: () async {
                              if (isBilling) {
                                await PrinterSettings.saveBillingPrinter(
                                    PrinterConnectionType.bluetooth, c);
                              } else {
                                await PrinterSettings.saveKitchenPrinter(
                                    PrinterConnectionType.bluetooth, c);
                              }
                              Navigator.pop(ctx);
                              setState(() {});
                            },
                          )),
                    ],
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  if (isBilling) {
                    PrinterSettings.saveBillingPrinter(
                        PrinterConnectionType.none, "");
                  } else {
                    PrinterSettings.saveKitchenPrinter(
                        PrinterConnectionType.none, "");
                  }
                  Navigator.pop(ctx);
                  setState(() {});
                },
                child: const Text("Clear Selection",
                    style: TextStyle(color: Colors.red)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cancel"),
              ),
            ],
          );
        });
  }

  Widget _infoCard() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20)),
        child: const Column(
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue, size: 18),
                SizedBox(width: 8),
                Text("Manager Pro-Tip",
                    style: TextStyle(
                        color: Colors.blue, fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(height: 8),
            Text(
                "Select a category on the left to add or manage items in that specific section of your menu.",
                style: TextStyle(fontSize: 12, color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}
