import 'package:shared_preferences/shared_preferences.dart';

enum PrinterConnectionType { usb, bluetooth, none }

class PrinterSettings {
  static const String _billingTypeKey = "billing_printer_type";
  static const String _billingIdKey = "billing_printer_id"; // COM port or Driver name

  static const String _kitchenTypeKey = "kitchen_printer_type";
  static const String _kitchenIdKey = "kitchen_printer_id";

  // Cache
  static PrinterConnectionType billingPrinterType = PrinterConnectionType.none;
  static String billingPrinterId = "";

  static PrinterConnectionType kitchenPrinterType = PrinterConnectionType.none;
  static String kitchenPrinterId = "";

  static Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    billingPrinterType = _parseType(prefs.getString(_billingTypeKey));
    billingPrinterId = prefs.getString(_billingIdKey) ?? "";

    kitchenPrinterType = _parseType(prefs.getString(_kitchenTypeKey));
    kitchenPrinterId = prefs.getString(_kitchenIdKey) ?? "";
  }

  static Future<void> saveBillingPrinter(PrinterConnectionType type, String identifier) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_billingTypeKey, type.name);
    await prefs.setString(_billingIdKey, identifier);
    billingPrinterType = type;
    billingPrinterId = identifier;
  }

  static Future<void> saveKitchenPrinter(PrinterConnectionType type, String identifier) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kitchenTypeKey, type.name);
    await prefs.setString(_kitchenIdKey, identifier);
    kitchenPrinterType = type;
    kitchenPrinterId = identifier;
  }

  static PrinterConnectionType _parseType(String? typeStr) {
    if (typeStr == PrinterConnectionType.usb.name) return PrinterConnectionType.usb;
    if (typeStr == PrinterConnectionType.bluetooth.name) return PrinterConnectionType.bluetooth;
    return PrinterConnectionType.none;
  }
}
