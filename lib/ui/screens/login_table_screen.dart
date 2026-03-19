import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pos_app/models/table_model.dart';
import 'package:pos_app/services/local_db_service.dart';
import 'package:pos_app/ui/screens/pos_screen.dart';

class LoginTableScreen extends StatefulWidget {
  const LoginTableScreen({super.key});

  @override
  State<LoginTableScreen> createState() => _LoginTableScreenState();
}

class _LoginTableScreenState extends State<LoginTableScreen> {
  List<RestaurantTable> tables = [];

  Timer? _timer;

  bool editMode = false;
  Set<int> selectedTables = {};

  @override
  void initState() {
    super.initState();

    loadTablesFromDB();
    loadTableStatus();

    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  bool hasActiveOrders() {
    for (var table in tables) {
      if (table.isOccupied || table.isBilled) {
        return true;
      }
    }
    return false;
  }

  Future<void> addNewTable() async {
    int newNumber = tables.isEmpty ? 1 : tables.last.number + 1;

    await LocalDbService.createTable(newNumber);

    setState(() {
      tables.add(RestaurantTable(number: newNumber));
    });
  }

  Future<void> loadTablesFromDB() async {
    final ids = await LocalDbService.loadTableIds();

    tables.clear();

    for (var id in ids) {
      tables.add(RestaurantTable(number: id));
    }

    setState(() {});
  }

  Future<void> deleteSelectedTables() async {
    for (var tableNo in selectedTables) {
      await LocalDbService.deleteTable(tableNo);
    }

    tables.removeWhere((table) => selectedTables.contains(table.number));

    setState(() {
      selectedTables.clear();
      editMode = false;
    });
  }

  Future<void> loadTableStatus() async {
    final savedTables = await LocalDbService.loadTables();

    for (var table in tables) {
      if (savedTables.containsKey(table.number)) {
        final data = savedTables[table.number]!;

        final st = data['status'];

        if (st == "occupied") {
          table.status = TableStatus.occupied;
        } else if (st == "reserved") {
          table.status = TableStatus.reserved;
        } else if (st == "billed") {
          table.status = TableStatus.billed;
        } else {
          table.status = TableStatus.available;
        }

        if (data['name'] != null) {
          table.name = data['name'];
        }

        if (data['occupiedAt'] != null) {
          table.occupiedAt = DateTime.parse(data['occupiedAt']);
        }

        final cart = await LocalDbService.loadCartItems(table.number);
        table.cart = cart;
      } else {
        table.status = TableStatus.available;
        table.occupiedAt = null;
        table.cart = [];
        table.name = "Table ${table.number}";
      }
    }

    if (mounted) setState(() {});
  }

  Future<void> openTable(RestaurantTable table) async {
    if (table.isAvailable) {
      table.markReserved();

      await LocalDbService.saveTableStatus(
        table.number,
        "reserved",
      );

      if (mounted) setState(() {});
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PosScreen(table: table),
      ),
    );

    await loadTableStatus();
  }

  String _getTimeElapsed(DateTime? occupiedAt) {
    if (occupiedAt == null) return "";

    final diff = DateTime.now().difference(occupiedAt);

    final mins = diff.inMinutes;

    if (mins < 60) return "$mins mins";

    final hrs = diff.inHours;
    final remaining = mins % 60;

    return "$hrs h $remaining m";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),

      // APPBAR
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFF8C00), Color(0xFFFF4500)],
            ),
          ),
          child: SafeArea(
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Text(
                  "Table Management",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    editMode ? Icons.close : Icons.edit,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    if (hasActiveOrders()) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Cannot modify tables while orders are running",
                          ),
                        ),
                      );
                      return;
                    }

                    setState(() {
                      editMode = !editMode;
                      selectedTables.clear();
                    });
                  },
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.table_bar_outlined,
                  color: Colors.white70,
                ),
                const SizedBox(width: 20),
              ],
            ),
          ),
        ),
      ),

      // BODY
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.live_tv, size: 24, color: Color(0xFFFF8C00)),
                SizedBox(width: 12),
                Text(
                  "Live Table Status",
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Expanded(
              child: GridView.builder(
                itemCount: tables.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.9,
                ),
                itemBuilder: (context, index) {
                  final table = tables[index];

                  final elapsed = _getTimeElapsed(table.occupiedAt);
                  final subtotal = table.subtotal;

                  bool isOccupied = table.isOccupied;
                  bool isReserved = table.isReserved;
                  bool isBilled = table.isBilled;
                  bool isActive = isOccupied || isBilled;

                  Color mainColor = const Color(0xFF059669);
                  Color bgFilter = const Color(0xFFECFDF5);
                  String lbl = "AVAILABLE";
                  Color lblColor = const Color(0xFF059669);
                  Color lblBg = const Color(0xFFECFDF5);
                  
                  if (isOccupied) {
                    mainColor = Colors.red;
                    bgFilter = Colors.red.withOpacity(0.1);
                    lbl = elapsed;
                    lblColor = Colors.red[800]!;
                    lblBg = Colors.red[50]!;
                  } else if (isBilled) {
                    mainColor = Colors.purple;
                    bgFilter = Colors.purple.withOpacity(0.1);
                    lbl = "BILLED";
                    lblColor = Colors.purple[800]!;
                    lblBg = Colors.purple[50]!;
                  } else if (isReserved) {
                    mainColor = Colors.blue;
                    bgFilter = Colors.blue.withOpacity(0.1);
                    lbl = "RESERVED";
                    lblColor = Colors.blue[800]!;
                    lblBg = Colors.blue[50]!;
                  }

                  return InkWell(
                    onTap: () {
                      if (editMode) {
                        setState(() {
                          if (selectedTables.contains(table.number)) {
                            selectedTables.remove(table.number);
                          } else {
                            selectedTables.add(table.number);
                          }
                        });
                      } else {
                        openTable(table);
                      }
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      decoration: BoxDecoration(
                        color: bgFilter,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: mainColor, width: 2),
                      ),
                      child: Stack(
                        children: [
                          if (editMode)
                            Positioned(
                              top: 6,
                              left: 6,
                              child: Transform.scale(
                                scale: 0.8,
                                child: Checkbox(
                                  value: selectedTables.contains(table.number),
                                  onChanged: (val) {
                                    setState(() {
                                      if (val ?? false) {
                                        selectedTables.add(table.number);
                                      } else {
                                        selectedTables.remove(table.number);
                                      }
                                    });
                                  },
                                ),
                              ),
                            ),
                          if (isActive && subtotal > 0)
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: mainColor,
                                  borderRadius: const BorderRadius.only(
                                    topRight: Radius.circular(22),
                                    bottomLeft: Radius.circular(16),
                                  ),
                                ),
                                child: Text(
                                  "₹${subtotal.toInt()}",
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11),
                                ),
                              ),
                            ),
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.table_restaurant,
                                    size: 32, color: mainColor),
                                const SizedBox(height: 12),
                                Text(
                                  table.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: lblBg,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    lbl,
                                    style: TextStyle(
                                      color: lblColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            if (editMode)
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: addNewTable,
                    icon: const Icon(Icons.add),
                    label: const Text("Add Table",
                        style: TextStyle(
                            fontSize: 16,
                            color: Color.fromARGB(246, 255, 252, 252))),
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed:
                        selectedTables.isEmpty ? null : deleteSelectedTables,
                    icon: const Icon(Icons.delete),
                    label: const Text("Delete Selected",
                        style: TextStyle(
                            fontSize: 16,
                            color: Color.fromARGB(246, 255, 252, 252))),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(240, 255, 25, 9)),
                  ),
                  const Spacer(),
                  Text("${selectedTables.length} Selected"),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
