import 'package:flutter_pos_printer_platform_image_3/flutter_pos_printer_platform_image_3.dart';

class UsbPrinterService {
  static Future<List<PrinterDevice>> getPrinters() async {
    final List<PrinterDevice> printers = [];
    
    // Add Notepad Fallback option
    printers.insert(0, PrinterDevice(name: 'Billing is not working', address: 'notepad'));
    
    var defaultPrinterManager = PrinterManager.instance;
    final stream = defaultPrinterManager.discovery(type: PrinterType.usb, isBle: false);
    
    final subscription = stream.listen((device) {
      if (!printers.any((p) => p.name == device.name)) {
        printers.add(device);
      }
    });

    // Wait short time to discover
    await Future.delayed(const Duration(seconds: 1));
    await subscription.cancel();
    
    return printers;
  }

  /// Sends raw ESC/POS bytes directly to a chosen Windows USB printer spooler queue.
  static Future<bool> printBytes(PrinterDevice printer, List<int> bytes) async {
    try {
      var defaultPrinterManager = PrinterManager.instance;
      
      // Connect
      bool isConnected = await defaultPrinterManager.connect(
          type: PrinterType.usb, 
          model: UsbPrinterInput(
            name: printer.name,
            productId: printer.productId,
            vendorId: printer.vendorId
          )
      );

      if (isConnected) {
        // Send bytes
        defaultPrinterManager.send(type: PrinterType.usb, bytes: bytes);
        
        // Brief delay to ensure hardware buffer clears
        await Future.delayed(const Duration(milliseconds: 200));
        
        // Disconnect
        await defaultPrinterManager.disconnect(type: PrinterType.usb);
        return true;
      }
      return false;
    } catch (e) {
      print("USB Printing Error: $e");
      return false;
    }
  }
}
