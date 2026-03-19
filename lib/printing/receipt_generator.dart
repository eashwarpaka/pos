import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:intl/intl.dart';
import '../models/bill_model.dart';
import '../models/order_item.dart';

class ReceiptGenerator {
  static Future<List<int>> generateBill(BillModel bill) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);
    List<int> bytes = [];

    // Header Section
    bytes += generator.text('------------------------------------------------');
    bytes += generator.text(bill.restaurantName.toUpperCase(),
        styles: const PosStyles(
            align: PosAlign.center,
            bold: true));
    
    bytes += generator.text(bill.address,
        styles: const PosStyles(align: PosAlign.center));
    
    bytes += generator.text('GSTIN: 36ABCDE1234F1Z5', // Can be parameterized later
        styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text('------------------------------------------------');
    


    // Bill Info
    bytes += generator.text('Invoice No: ${bill.billNumber}');
    bytes += generator.text('Date: ${DateFormat('dd-MM-yyyy').format(bill.dateTime)}');
    bytes += generator.text('Table: ${bill.tableNumber}');
    // Check if table is takeaway (e.g. table number ends with TakeAway or similar)
    String orderType = bill.tableNumber.toLowerCase().contains('take') ? 'Takeaway' : 'Dine-in';
    bytes += generator.text('Order Type: $orderType');
    
    bytes += generator.text('------------------------------------------------');

    // Items Section Header
    bytes += generator.row([
      PosColumn(text: 'Item', width: 6),
      PosColumn(text: 'Qty', width: 2, styles: const PosStyles(align: PosAlign.center)),
      PosColumn(text: 'Price', width: 4, styles: const PosStyles(align: PosAlign.right)),
    ]);
    
    bytes += generator.text('------------------------------------------------');

    // Items
    for (OrderItem item in bill.items) {
      bytes += generator.row([
        PosColumn(text: item.name, width: 6),
        PosColumn(text: item.qty.toString(), width: 2, styles: const PosStyles(align: PosAlign.center)),
        PosColumn(text: item.total.toStringAsFixed(0), width: 4, styles: const PosStyles(align: PosAlign.right)),
      ]);
    }

    bytes += generator.text('------------------------------------------------');

    // Totals
    bytes += generator.row([
      PosColumn(text: 'Subtotal', width: 8),
      PosColumn(text: bill.subtotal.toStringAsFixed(2), width: 4, styles: const PosStyles(align: PosAlign.right)),
    ]);
    


    if (bill.discount > 0) {
      bytes += generator.row([
        PosColumn(text: 'Discount', width: 8),
        PosColumn(text: '-${bill.discount.toStringAsFixed(2)}', width: 4, styles: const PosStyles(align: PosAlign.right)),
      ]);

    }

    double cgst = bill.gst / 2;
    double sgst = bill.gst / 2;

    bytes += generator.row([
      PosColumn(text: 'CGST 2.5%', width: 8),
      PosColumn(text: cgst.toStringAsFixed(2), width: 4, styles: const PosStyles(align: PosAlign.right)),
    ]);
    bytes += generator.row([
      PosColumn(text: 'SGST 2.5%', width: 8),
      PosColumn(text: sgst.toStringAsFixed(2), width: 4, styles: const PosStyles(align: PosAlign.right)),
    ]);

    bytes += generator.text('------------------------------------------------');

    bytes += generator.row([
      PosColumn(text: 'TOTAL', width: 8, styles: const PosStyles(bold: true)),
      PosColumn(text: bill.totalAmount.toStringAsFixed(2), width: 4, styles: const PosStyles(align: PosAlign.right, bold: true)),
    ]);

    bytes += generator.text('------------------------------------------------');

    // Footer
    bytes += generator.text('Thank You Visit Again',
        styles: const PosStyles(align: PosAlign.center));

    bytes += generator.cut();

    return bytes;
  }
}
