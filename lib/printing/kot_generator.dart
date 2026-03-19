import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:intl/intl.dart';
import '../models/kot_model.dart';
import '../models/order_item.dart';

class KotGenerator {
  static Future<List<int>> generateKot(KotModel kot) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);
    List<int> bytes = [];

    bytes += generator.text('------------------------------------------------');
    bytes += generator.text('KITCHEN ORDER TICKET',
        styles: const PosStyles(
            align: PosAlign.center,
            bold: true,
            height: PosTextSize.size2,
            width: PosTextSize.size2));
    bytes += generator.text('------------------------------------------------');


    bytes += generator.text('Table    : ${kot.tableNumber}',
        styles: const PosStyles(bold: true, height: PosTextSize.size2));
    bytes += generator.text('Order No : ${kot.orderNumber}');
    bytes += generator.text('Time     : ${DateFormat('hh:mm a').format(kot.time)}');
    
    bytes += generator.text('------------------------------------------------');
    bytes += generator.text('--- ITEMS ---', styles: const PosStyles(align: PosAlign.center, bold: true));


    for (OrderItem item in kot.items) {
      bytes += generator.text('${item.qty} x ${item.name}',
          styles: const PosStyles(bold: true, width: PosTextSize.size2, height: PosTextSize.size2));
    }

    if (kot.notes.isNotEmpty) {
      bytes += generator.text('------------------------------------------------');
      bytes += generator.text('Notes: ${kot.notes}',
          styles: const PosStyles(bold: true));
    }

    bytes += generator.text('------------------------------------------------');
    bytes += generator.cut();

    return bytes;
  }
}
