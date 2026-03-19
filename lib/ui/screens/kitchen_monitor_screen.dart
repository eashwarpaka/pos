import 'package:flutter/material.dart';
import 'package:pos_app/models/cart_item.dart';
import 'package:pos_app/services/local_db_service.dart';

class KitchenMonitorScreen extends StatefulWidget {
  const KitchenMonitorScreen({super.key});

  @override
  State<KitchenMonitorScreen> createState() => _KitchenMonitorScreenState();
}

class _KitchenMonitorScreenState extends State<KitchenMonitorScreen> {
  Map<int, List<CartItem>> activeOrders = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllOrders();
  }

  Future<void> _loadAllOrders() async {
    final tables = await LocalDbService.loadTables();
    Map<int, List<CartItem>> orders = {};
    
    for (var entry in tables.entries) {
      if (entry.value['status'] == 'occupied' || entry.value['status'] == 'billed') {
        final items = await LocalDbService.loadCartItems(entry.key);
        if (items.isNotEmpty) {
          orders[entry.key] = items;
        }
      }
    }

    setState(() {
      activeOrders = orders;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark Navy
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFF8C00), Color(0xFFFF4500)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
          ),
          child: SafeArea(
            child: Row(
              children: [
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back, color: Colors.white)),
                const SizedBox(width: 12),
                const Text("LIVE KITCHEN MONITOR", 
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white, letterSpacing: 1.2)),
                const Spacer(),
                IconButton(onPressed: _loadAllOrders, icon: const Icon(Icons.refresh, color: Colors.white70)),
                const SizedBox(width: 20),
              ],
            ),
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : activeOrders.isEmpty
              ? Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.restaurant_menu, size: 64, color: Colors.white10),
                    const SizedBox(height: 16),
                    Text("No active orders at the moment", style: TextStyle(color: Colors.white38)),
                  ],
                ))
              : GridView.builder(
                  padding: const EdgeInsets.all(24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: activeOrders.length,
                  itemBuilder: (_, i) {
                    final tableNumber = activeOrders.keys.elementAt(i);
                    final items = activeOrders[tableNumber]!;
                    return _orderCard(tableNumber, items);
                  },
                ),
    );
  }

  Widget _orderCard(int tableNumber, List<CartItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("TABLE $tableNumber", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                const Icon(Icons.timer_outlined, color: Colors.white, size: 20),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final item = items[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(4)),
                        child: Text("${item.quantity}x", style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item.name,
                          style: TextStyle(
                            color: item.isKotSent ? Colors.white70 : Colors.white,
                            fontSize: 16,
                            decoration: item.isKotSent ? null : TextDecoration.underline,
                            decorationColor: Colors.orange,
                          ),
                        ),
                      ),
                      if (!item.isKotSent)
                        const Icon(Icons.new_releases, color: Colors.orange, size: 16),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // In a real app, this would mark items as "Served"
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Table $tableNumber items cleared from monitor")));
                  setState(() {
                    activeOrders.remove(tableNumber);
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("MARK COMPLETED"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
