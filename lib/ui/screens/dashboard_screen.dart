import 'dart:async';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:pos_app/services/local_db_service.dart';
//import 'login_screen.dart';
import 'package:pos_app/ui/screens/revenue_screen.dart';
import 'package:pos_app/ui/screens/settings_screen.dart';
import 'package:pos_app/services/language_service.dart';
import 'package:pos_app/settings/printer_settings.dart';
import 'login_table_screen.dart';
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  double todayRevenue = 0;
  double todayExpenses = 0;
  double todayProfit = 0;
  int todayOrders = 0;

  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
    _loadSummary();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _loadSummary() async {
    final summary = await LocalDbService.getTodaySummary();
    setState(() {
      todayRevenue = summary['revenue'] ?? 0.0;
      todayExpenses = summary['expenses'] ?? 0.0;
      todayProfit = summary['profit'] ?? 0.0;
      todayOrders = summary['orders'] ?? 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          // PREMIUM ORANGE HEADER
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFF8C00), Color(0xFFFF4500)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                    color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))
              ],
            ),
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.restaurant_menu,
                            size: 36, color: Colors.white),
                      ),
                      const SizedBox(width: 16),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("My Café POS",
                              style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 1.1)),
                          Text("Premium Dashboard",
                              style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        child: StreamBuilder(
                          stream: Stream.periodic(const Duration(seconds: 1)),
                          builder: (context, snapshot) {
                            return Text(
                              DateFormat('dd MMM, yyyy  -  hh:mm:ss a').format(DateTime.now()),
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            );
                          }
                        ),
                      ),
                      const SizedBox(width: 32),
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const CircleAvatar(
                            radius: 22,
                            backgroundColor: Colors.white24,
                            child: Icon(Icons.person, color: Colors.white)),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),

          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Column(
                      children: [
                        // TOP SUMMARY CARDS
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: LayoutBuilder(builder: (context, constraints) {
                      return Wrap(
                        spacing: 20,
                        runSpacing: 20,
                        alignment: WrapAlignment.center,
                        children: [
                          _miniStat(
                              LanguageService.translate("today_rev"),
                              "₹${todayRevenue.toStringAsFixed(0)}",
                              Icons.payments_outlined,
                              Colors.green,
                              constraints.maxWidth),
                          _miniStat(
                              LanguageService.translate("today_exp"),
                              "₹${todayExpenses.toStringAsFixed(0)}",
                              Icons.arrow_outward,
                              Colors.red,
                              constraints.maxWidth),
                          _miniStat(
                              LanguageService.translate("net_profit"),
                              "₹${todayProfit.toStringAsFixed(0)}",
                              Icons.account_balance_wallet_outlined,
                              Colors.orange,
                              constraints.maxWidth),
                          _miniStat(
                              LanguageService.translate("orders"),
                              todayOrders.toString(),
                              Icons.receipt_long_outlined,
                              Colors.blue,
                              constraints.maxWidth),
                        ],
                      );
                    }),
                  ),

                  const SizedBox(height: 48),

                  // MAIN TILES GRID
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        double itemWidth;
                        if (width > 1200) {
                          itemWidth = (width - 60) / 3;
                        } else if (width > 800) {
                          itemWidth = (width - 30) / 2;
                        } else {
                          itemWidth = width;
                        }

                        return Wrap(
                          spacing: 30,
                          runSpacing: 30,
                          alignment: WrapAlignment.center,
                          children: [
                            _tile(
                              width: itemWidth,
                              title: LanguageService.translate("pos"),
                              subtitle:
                                  LanguageService.translate("start_order"),
                              icon: Icons.point_of_sale,
                              color: Colors.orange,
                              onTap: () async {
                                await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const LoginTableScreen()));
                                _loadSummary();
                              },
                            ),
                            _tile(
                              width: itemWidth,
                              title: LanguageService.translate("analytics"),
                              subtitle:
                                  LanguageService.translate("detailed_reports"),
                              icon: Icons.bar_chart_rounded,
                              color: Colors.deepOrange,
                              onTap: () async {
                                await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const RevenueScreen()));
                                _loadSummary();
                              },
                            ),
                            _tile(
                              width: itemWidth,
                              title: LanguageService.translate("inventory"),
                              subtitle: LanguageService.translate(
                                  "stock_availability"),
                              icon: Icons.inventory_2_outlined,
                              color: Colors.amber[800]!,
                              onTap: () async {
                                await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const SettingsScreen()));
                                _loadSummary();
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 32,
            right: 32,
            child: _printerStatusBanner(),
          ),
        ],
      ),
    ),
   ],
  ),
 );
}

  Widget _miniStat(String label, String value, IconData icon, Color color,
      double parentWidth) {
    double width;
    if (parentWidth > 1200) {
      width = (parentWidth - 60) / 4;
    } else if (parentWidth > 600) {
      width = (parentWidth - 20) / 2;
    } else {
      width = parentWidth;
    }

    return Container(
      width: width,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.bold)),
                FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(value,
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B)))),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _tile({
    required double width,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: width,
      child: InkWell(
        borderRadius: BorderRadius.circular(36),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(36),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.08),
                blurRadius: 30,
                offset: const Offset(0, 15),
              )
            ],
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 72, color: color),
              ),
              const SizedBox(height: 32),
              Text(title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B))),
              const SizedBox(height: 12),
              Text(subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _printerStatusBanner() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _printerIndicator("Billing Printer", PrinterSettings.billingPrinterId, PrinterSettings.billingPrinterType),
        const SizedBox(height: 12),
        _printerIndicator("Kitchen (KOT)", PrinterSettings.kitchenPrinterId, PrinterSettings.kitchenPrinterType),
      ],
    );
  }

  Widget _printerIndicator(String label, String id, PrinterConnectionType type) {
    bool isConnected = type != PrinterConnectionType.none && id.isNotEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isConnected ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ]
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isConnected ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              type == PrinterConnectionType.bluetooth ? Icons.bluetooth : (type == PrinterConnectionType.usb ? Icons.usb : Icons.print_disabled),
              color: isConnected ? Colors.green : Colors.red,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF64748B))),
              Text(isConnected ? id : "Disconnected", style: TextStyle(color: isConnected ? Colors.green[700] : Colors.red, fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }
}
