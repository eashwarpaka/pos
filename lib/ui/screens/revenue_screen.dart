import 'package:flutter/material.dart';
import 'package:pos_app/services/local_db_service.dart';
import 'package:pos_app/services/language_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class RevenueScreen extends StatefulWidget {
  const RevenueScreen({super.key});

  @override
  State<RevenueScreen> createState() => _RevenueScreenState();
}

class _RevenueScreenState extends State<RevenueScreen> {
  List<Map<String, dynamic>> sales = [];
  List<Map<String, dynamic>> popularItems = [];
  Map<String, double> categoryRevenue = {};
  Map<String, double> paymentStats = {};
  double totalRevenue = 0;
  double todayRevenue = 0;
  int totalOrders = 0;
  String searchOrderQuery = "";
  String timeFilter = "daily"; // internal keys: daily, weekly, monthly, all
  int selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    loadAnalytics();
  }

  Future<void> loadAnalytics() async {
    final report = await LocalDbService.loadSalesReport();
    final pStats = await LocalDbService.getPaymentModeStats();
    
    double total = 0;
    double today = 0;
    final now = DateTime.now();

    for (var sale in report) {
      final amount = ((sale['amount'] ?? 0) as num).toDouble();
      total += amount;
      
      final dt = DateTime.parse(sale['timestamp']);
      if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
        today += amount;
      }
    }

    setState(() {
      sales = report;
      paymentStats = pStats;
      totalRevenue = total;
      todayRevenue = today;
      totalOrders = report.length;
    });
    
    await updateFilteredData();
  }

  Future<void> updateFilteredData() async {
    final filtered = _getFilteredSales();
    Map<String, double> tempCatRev = {};
    Map<String, Map<String, dynamic>> tempItems = {};
    
    for (var sale in filtered) {
      final items = await LocalDbService.loadSaleItems(sale['id']);
      for (var item in items) {
        String cat = item['category'] ?? 'Uncategorized';
        String name = item['name'];
        double itemRev = ((item['price'] ?? 0) as num).toDouble() * ((item['quantity'] ?? 0) as num).toDouble();
        
        tempCatRev[cat] = (tempCatRev[cat] ?? 0) + itemRev;
        
        if (!tempItems.containsKey(name)) {
          tempItems[name] = { 'name': name, 'totalQty': 0, 'revenue': 0.0 };
        }
        tempItems[name]!['totalQty'] += ((item['quantity'] ?? 0) as num).toInt();
        tempItems[name]!['revenue'] += itemRev;
      }
    }
    
    var popList = tempItems.values.toList();
    popList.sort((a, b) => (b['totalQty'] as int).compareTo(a['totalQty'] as int));
    
    if (mounted) {
      setState(() {
        popularItems = popList.take(10).toList();
        categoryRevenue = tempCatRev;
      });
    }
  }

  Future<void> exportToCSV() async {
    if (sales.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No sales to export!"), behavior: SnackBarBehavior.floating));
      return;
    }

    List<List<dynamic>> rows = [];
    
    // Header
    rows.add(["Order ID", "Timestamp", "Amount", "Discount", "Payment Method", "Items"]);

    for (var sale in sales) {
      final items = await LocalDbService.loadSaleItems(sale['id']);
      String itemSummary = items.map((i) => "${i['quantity']}x ${i['name']}").join(" | ");
      
      rows.add([
        sale['id'],
        sale['timestamp'],
        sale['amount'],
        sale['discount'],
        sale['paymentMethod'],
        itemSummary
      ]);
    }

    // Manual CSV generation to avoid dependency issues
    String csvData = rows.map((row) => row.map((cell) => '"${cell.toString().replaceAll('"', '""')}"').join(',')).join('\n');
    
    try {
      Directory? directory = await getDownloadsDirectory();
      directory ??= await getApplicationDocumentsDirectory();
      
      final path = "${directory.path}/POS_Sales_Report_${DateTime.now().millisecondsSinceEpoch}.csv";
      final file = File(path);
      await file.writeAsString(csvData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Report downloaded to Downloads folder!"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(label: "Open", textColor: Colors.white, onPressed: () {
               if (Platform.isWindows) {
                 Process.run('explorer.exe', ['/select,', path.replaceAll('/', '\\')]);
               }
            }),
          ),
        );
      }
      
      // Auto-open directory on Windows
      if (Platform.isWindows) {
        Process.run('explorer.exe', ['/select,', path.replaceAll('/', '\\')]);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Export failed: $e"), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFF8C00), Color(0xFFFF4500)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
            ),
            child: Material(
              color: Colors.transparent,
              child: SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: Row(
                        children: [
                          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back, color: Colors.white)),
                          const SizedBox(width: 12),
                          Text(LanguageService.translate("adv_analytics"), 
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white)),
                          const Spacer(),
                          _timeFilterBtn("daily"),
                          _timeFilterBtn("weekly"),
                          _timeFilterBtn("monthly"),
                          _timeFilterBtn("yearly"),
                          _timeFilterBtn("all"),
                          const SizedBox(width: 20),
                          TextButton.icon(
                            onPressed: exportToCSV,
                            icon: const Icon(Icons.download, color: Colors.white),
                            label: Text(LanguageService.translate("export_csv"), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                            style: TextButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.2)),
                          ),
                        ],
                      ),
                    ),
                    TabBar(
                      indicatorColor: Colors.white,
                      indicatorWeight: 4,
                      tabs: [
                        Tab(text: LanguageService.translate("overview")),
                        Tab(text: LanguageService.translate("item_sales")),
                        Tab(text: LanguageService.translate("cat_sales")),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _buildOverviewTab(),
            _buildItemWiseTab(),
            _buildCategoryWiseTab(),
          ],
        ),
      ),
    );
  }

  Widget _timeFilterBtn(String label) {
    bool isSelected = timeFilter == label;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(() => timeFilter = label);
          updateFilteredData();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.white10,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(LanguageService.translate(label), style: TextStyle(color: isSelected ? const Color(0xFFFF4500) : Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    final filteredSales = _getFilteredSales();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _statCard("${LanguageService.translate(timeFilter).toUpperCase()} ${LanguageService.translate("revenue").toUpperCase()}", "₹${_calculateSum(filteredSales).toStringAsFixed(2)}", Colors.orange, Icons.payments),
              const SizedBox(width: 24),
              _statCard(LanguageService.translate("orders").toUpperCase(), "${filteredSales.length}", Colors.blue, Icons.receipt_long),
              const SizedBox(width: 24),
              _statCard("AVG ORDER VALUE", "₹${(filteredSales.isEmpty ? 0 : (_calculateSum(filteredSales) / filteredSales.length)).toStringAsFixed(2)}", Colors.green, Icons.analytics),
            ],
          ),
          const SizedBox(height: 40),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: _salesTrendChart(filteredSales)),
              const SizedBox(width: 24),
              Expanded(child: _categoryDistributionChart()),
            ],
          ),
          const SizedBox(height: 40),
          _transactionLog(filteredSales),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredSales() {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);

    return sales.where((s) {
      final ts = s['timestamp']?.toString();
      if (ts == null) return false;
      final dt = DateTime.tryParse(ts);
      if (dt == null) return false;

      if (timeFilter == "daily") {
        final start = startOfToday;
        final end = start.add(const Duration(days: 1));
        return !dt.isBefore(start) && dt.isBefore(end);
      }

      if (timeFilter == "weekly") {
        // Week starts on Monday (weekday 1)
        final start = startOfToday.subtract(Duration(days: now.weekday - 1));
        final end = start.add(const Duration(days: 7));
        return !dt.isBefore(start) && dt.isBefore(end);
      }

      if (timeFilter == "monthly") {
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(now.year, now.month + 1, 1);
        return !dt.isBefore(start) && dt.isBefore(end);
      }

      if (timeFilter == "yearly") {
        final start = DateTime(now.year, 1, 1);
        final end = DateTime(now.year + 1, 1, 1);
        return !dt.isBefore(start) && dt.isBefore(end);
      }

      return true;
    }).toList();
  }

  double _calculateSum(List<Map<String, dynamic>> list) {
    return list.fold(0.0, (sum, item) => sum + ((item['amount'] ?? 0) as num).toDouble());
  }

  Widget _buildItemWiseTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: _sectionCard(
        "Item-wise Sales Performance",
        DataTable(
          columns: [
            DataColumn(label: Text(LanguageService.translate("item_name").toUpperCase())),
            DataColumn(label: Text(LanguageService.translate("qty").toUpperCase())),
            DataColumn(label: Text(LanguageService.translate("revenue").toUpperCase())),
            DataColumn(label: Text(LanguageService.translate("popular_items").toUpperCase())),
          ],
          rows: popularItems.map((item) {
            double revenue = ((item['revenue'] ?? 0) as num).toDouble();
            return DataRow(cells: [
              DataCell(Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold))),
              DataCell(Text("${item['totalQty']}")),
              DataCell(Text("₹$revenue")),
              DataCell(Container(
                width: 100,
                height: 8,
                decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4)),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: popularItems.isNotEmpty ? (((item['totalQty'] ?? 0) as num) / ((popularItems.first['totalQty'] ?? 1) as num)).clamp(0.0, 1.0) : 0.0,
                  child: Container(decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(4))),
                ),
              )),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCategoryWiseTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: _sectionCard(
        "Category-wise Revenue Breakdown",
        DataTable(
          columns: const [
            DataColumn(label: Text("CATEGORY")),
            DataColumn(label: Text("TOTAL REVENUE")),
            DataColumn(label: Text("SHARE %")),
          ],
          rows: categoryRevenue.entries.map((e) {
            double total = categoryRevenue.values.fold(0, (a, b) => a + b);
            double share = (e.value / total) * 100;
            return DataRow(cells: [
              DataCell(Text(e.key, style: const TextStyle(fontWeight: FontWeight.bold))),
              DataCell(Text("₹${e.value.toStringAsFixed(2)}")),
              DataCell(Text("${share.toStringAsFixed(1)}%")),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _salesTrendChart(List<Map<String, dynamic>> filteredSales) {
    return _sectionCard(
      "Revenue Trend",
      SizedBox(
        height: 300,
        child: BarChart(
          BarChartData(
            barTouchData: BarTouchData(enabled: false),
            gridData: FlGridData(show: false),
            titlesData: FlTitlesData(show: false),
            borderData: FlBorderData(show: false),
            barGroups: filteredSales.take(10).toList().asMap().entries.map((entry) {
              return BarChartGroupData(x: entry.key, barRods: [
                BarChartRodData(toY: ((entry.value['amount'] ?? 0) as num).toDouble(), color: Colors.orange, width: 20, borderRadius: BorderRadius.circular(4))
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _categoryDistributionChart() {
    return _sectionCard(
      "Top Categories",
      SizedBox(
        height: 300,
        child: PieChart(
          PieChartData(
            pieTouchData: PieTouchData(enabled: false),
            sections: categoryRevenue.entries.take(5).map((e) => PieChartSectionData(
              color: [Colors.orange, Colors.blue, Colors.green, Colors.purple, Colors.red][categoryRevenue.keys.toList().indexOf(e.key) % 5],
              value: e.value,
              title: e.key,
              radius: 50,
              titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
            )).toList(),
          ),
        ),
      ),
    );
  }

  Widget _transactionLog(List<Map<String, dynamic>> filteredSales) {
    return _sectionCard(
      "Order Log (Filtered)",
      ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: filteredSales.length,
        itemBuilder: (context, index) {
          final sale = filteredSales[index];
          final dt = DateTime.parse(sale['timestamp']);
          return ListTile(
            onTap: () => _showReceipt(sale['id'] as int, sale['amount']),
            leading: const Icon(Icons.receipt, color: Colors.orange),
            title: Text("ORDER #${sale['id']} - ${sale['paymentMethod']}"),
            subtitle: Text("${dt.hour}:${dt.minute} | ${dt.day}/${dt.month}/${dt.year}"),
            trailing: Text("₹${sale['amount']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 16)),
          );
        },
      ),
    );
  }

  void _showReceipt(int saleId, dynamic total) async {
    _openReceiptDialog(saleId);
  }

  void _openReceiptDialog(int saleId) async {
    List<Map<String, dynamic>> items = await LocalDbService.loadSaleItems(saleId);
    List<Map<String, dynamic>> allSales = await LocalDbService.loadSalesReport();
    final saleIndex = allSales.indexWhere((s) => s['id'] == saleId);
    if (saleIndex == -1 || !mounted) return;
    
    Map<String, dynamic> sale = allSales[saleIndex];
    double totalAmount = (sale['amount'] as num).toDouble();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text("Receipt #$saleId", style: const TextStyle(fontWeight: FontWeight.bold)),
              content: SizedBox(
                width: 450,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Divider(),
                    if (items.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text("All items cancelled.", style: TextStyle(color: Colors.red, fontStyle: FontStyle.italic)),
                      ),
                    ...items.map((item) {
                       int qty = item['quantity'] as int;
                       double price = (item['price'] as num).toDouble();
                       return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Expanded(child: Text("${qty}x ${item['name']}", style: const TextStyle(fontWeight: FontWeight.w500))),
                            Text("₹${(price * qty).toStringAsFixed(2)}"),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.red, size: 20),
                              tooltip: "Cancel Item",
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () async {
                                int cancelQty = 1;
                                if (qty > 1) {
                                  cancelQty = await _askCancelQuantity(context, qty, item['name']);
                                  if (cancelQty <= 0) return;
                                } else {
                                  bool? confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (c) => AlertDialog(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      title: Row(
                                        children: [
                                          const Icon(Icons.warning_rounded, color: Colors.orange),
                                          const SizedBox(width: 8),
                                          const Text("Confirm Cancel"),
                                        ],
                                      ),
                                      content: Text("Are you sure you want to cancel ${item['name']}?", style: const TextStyle(fontSize: 16)),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text("No, Keep it", style: TextStyle(color: Colors.grey))),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.redAccent,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)
                                          ),
                                          onPressed: () => Navigator.pop(c, true), 
                                          child: const Text("Yes, Cancel", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                                        ),
                                      ]
                                    )
                                  );
                                  if (confirm != true) return;
                                }
                                
                                await LocalDbService.cancelSaleItem(saleId, item['id'], cancelQty, price);
                                
                                List<Map<String, dynamic>> freshItems = await LocalDbService.loadSaleItems(saleId);
                                List<Map<String, dynamic>> freshSales = await LocalDbService.loadSalesReport();
                                Map<String, dynamic>? freshSale = freshSales.where((s) => s['id'] == saleId).cast<Map<String, dynamic>?>().firstWhere((_) => true, orElse: () => null);
                                
                                setStateDialog(() {
                                  items = freshItems;
                                  if (freshSale != null) {
                                    totalAmount = (freshSale['amount'] as num).toDouble();
                                  }
                                });
                                loadAnalytics();
                              },
                            )
                          ],
                        ),
                      );
                    }),
                    const Divider(thickness: 2),
                    if (sale['discount'] != null && (sale['discount'] as num) > 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Discount Applied", style: TextStyle(color: Colors.green)),
                            Text("- ₹${((sale['discount'] ?? 0) as num).toDouble().toStringAsFixed(2)}", style: const TextStyle(color: Colors.green)),
                          ],
                        ),
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Total Paid", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        Text("₹${totalAmount.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.orange)),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close", style: TextStyle(color: Colors.orange))),
              ],
            );
          }
        );
      }
    );
  }

  Future<int> _askCancelQuantity(BuildContext context, int maxQty, String itemName) async {
    int selectedQty = 1;
    return await showDialog<int>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  const Icon(Icons.remove_shopping_cart, color: Colors.redAccent),
                  const SizedBox(width: 8),
                  Expanded(child: Text("Cancel $itemName", overflow: TextOverflow.ellipsis)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text("How many would you like to cancel?", style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.grey.shade300)
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.remove_circle, color: selectedQty > 1 ? Colors.redAccent : Colors.grey, size: 28),
                          onPressed: selectedQty > 1 ? () => setDialogState(() => selectedQty--) : null,
                        ),
                        const SizedBox(width: 16),
                        Text("$selectedQty", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: Icon(Icons.add_circle, color: selectedQty < maxQty ? Colors.green : Colors.grey, size: 28),
                          onPressed: selectedQty < maxQty ? () => setDialogState(() => selectedQty++) : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text("Max quantity: $maxQty", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, 0), child: const Text("Go Back", style: TextStyle(color: Colors.grey))),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, selectedQty),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)
                  ),
                  child: const Text("Confirm Cancellation", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          }
        );
      },
    ) ?? 0;
  }

  Widget _statCard(String title, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.black54, fontSize: 14)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _sectionCard(String title, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }
}
