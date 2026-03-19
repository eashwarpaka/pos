import 'order_item.dart';

class KotModel {
  final String tableNumber;
  final String orderNumber;
  final DateTime time;
  final String notes;

  final List<OrderItem> items;

  KotModel({
    required this.tableNumber,
    required this.orderNumber,
    required this.time,
    this.notes = "",
    required this.items,
  });
}
