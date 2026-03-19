import 'dart:io';
import 'package:intl/intl.dart';
import 'package:flutter_pos_printer_platform_image_3/flutter_pos_printer_platform_image_3.dart';
import '../models/bill_model.dart';
import '../models/kot_model.dart';
import '../settings/printer_settings.dart';
import '../printing/receipt_generator.dart';
import '../printing/kot_generator.dart';
import 'usb_printer_service.dart';
import 'bluetooth_printer_service.dart';

class PrinterService {
  
  /// Prints a Customer Bill based on the cached Billing Printer settings.
  static Future<bool> printBill(BillModel bill) async {
    try {
      if (PrinterSettings.billingPrinterId == 'Billing is not working') {
        return await _printToNotepad(bill: bill);
      }

      final List<int> bytes = await ReceiptGenerator.generateBill(bill);
      return await _routePrintJob(
        PrinterSettings.billingPrinterType,
        PrinterSettings.billingPrinterId,
        bytes,
      );
    } catch (e) {
      print("Error generating Bill: $e");
      return false;
    }
  }

  /// Prints a Kitchen Ticket based on the cached KOT Printer settings.
  static Future<bool> printKot(KotModel kot) async {
    try {
      if (PrinterSettings.kitchenPrinterId == 'Billing is not working') {
        return await _printToNotepad(kot: kot);
      }

      final List<int> bytes = await KotGenerator.generateKot(kot);
      return await _routePrintJob(
        PrinterSettings.kitchenPrinterType,
        PrinterSettings.kitchenPrinterId,
        bytes,
      );
    } catch (e) {
      print("Error generating KOT: $e");
      return false;
    }
  }

  /// Internal router that decides which hardware service to use.
  static Future<bool> _routePrintJob(
    PrinterConnectionType type, 
    String identifier, 
    List<int> bytes
  ) async {
    
    if (type == PrinterConnectionType.none || identifier.isEmpty) {
      print("Printer configuration missing.");
      return false;
    }

    switch (type) {
      case PrinterConnectionType.usb:
        // Spool to Windows Printer
        final printers = await UsbPrinterService.getPrinters();
        try {
          // Match the identifier with the printer completely (like 'EPSON TM-T82III Receipt')
          final selectedPrinter = printers.firstWhere((p) => p.name == identifier);
          return await UsbPrinterService.printBytes(selectedPrinter, bytes);
        } catch (e) {
          print("Configured USB printer '$identifier' not found in Windows.");
          return false;
        }

      case PrinterConnectionType.bluetooth:
        // Stream to Windows COM port
        if (!BluetoothPrinterService.getAvailableComPorts().contains(identifier)) {
          print("Configured Bluetooth COM port '$identifier' not available.");
          return false;
        }
        return await BluetoothPrinterService.printBytes(identifier, bytes);

      default:
        return false;
    }
  }

  /// Fallback: Writes the receipt to a local text file and opens Notepad.
  static Future<bool> _printToNotepad({BillModel? bill, KotModel? kot}) async {
    try {
      StringBuffer sb = StringBuffer();

      if (bill != null) {
        sb.writeln('------------------------------------------------');
        sb.writeln('                 ${bill.restaurantName.toUpperCase()}                 ');
        sb.writeln('             ${bill.address}             ');
        sb.writeln('             GSTIN: 36ABCDE1234F1Z5             ');
        sb.writeln('------------------------------------------------');
        sb.writeln('Invoice No: ${bill.billNumber}');
        sb.writeln('Date: ${DateFormat("dd-MM-yyyy").format(bill.dateTime)}');
        sb.writeln('Table: ${bill.tableNumber}');
        String orderType = bill.tableNumber.toLowerCase().contains('take') ? 'Takeaway' : 'Dine-in';
        sb.writeln('Order Type: $orderType');
        sb.writeln('------------------------------------------------');
        sb.writeln('Item                      Qty      Price');
        sb.writeln('------------------------------------------------');
        for (var i in bill.items) {
          String name = i.name.padRight(25);
          String qty = i.qty.toString().padLeft(3);
          String price = i.total.toStringAsFixed(0).padLeft(10);
          sb.writeln('$name $qty $price');
        }
        sb.writeln('------------------------------------------------');
        sb.writeln('Subtotal:                      ${bill.subtotal.toStringAsFixed(2).padLeft(10)}');
        if (bill.discount > 0) {
          sb.writeln('Discount:                      -${bill.discount.toStringAsFixed(2).padLeft(9)}');
        }
        double cgst = bill.gst / 2;
        double sgst = bill.gst / 2;
        sb.writeln('CGST 2.5%:                     ${cgst.toStringAsFixed(2).padLeft(10)}');
        sb.writeln('SGST 2.5%:                     ${sgst.toStringAsFixed(2).padLeft(10)}');
        sb.writeln('------------------------------------------------');
        sb.writeln('TOTAL:                         ${bill.totalAmount.toStringAsFixed(2).padLeft(10)}');
        sb.writeln('------------------------------------------------');
        sb.writeln('');
        sb.writeln('             Thank You Visit Again             ');
      } else if (kot != null) {
        sb.writeln('====================================');
        sb.writeln('           KITCHEN ORDER         ');
        sb.writeln('====================================');
        sb.writeln('Table: ${kot.tableNumber}');
        sb.writeln('Order No: ${kot.orderNumber}');
        sb.writeln('Time: ${DateFormat("hh:mm a").format(kot.time)}');
        sb.writeln('------------------------------------');
        sb.writeln('Qty  Item');
        sb.writeln('------------------------------------');
        for (var i in kot.items) {
          String qty = i.qty.toString().padRight(4);
          sb.writeln('$qty ${i.name}');
        }
        sb.writeln('====================================');
      }

      String fileName = 'temp_receipt.txt';
      if (bill != null) {
        fileName = 'Invoice_\${bill.billNumber}.txt';
      } else if (kot != null) {
        fileName = 'KOT_\${kot.orderNumber}.txt';
      }

      final file = File(fileName);
      await file.writeAsString(sb.toString());
      
      if (Platform.isWindows) {
        Process.run('notepad.exe', [file.absolute.path.replaceAll('/', '\\')]);
      }
      return true;
    } catch (e) {
      print("Notepad Error: \$e");
      return false;
    }
  }
}
