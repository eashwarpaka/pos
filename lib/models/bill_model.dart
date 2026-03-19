import 'order_item.dart';

class BillModel {
  final String restaurantName;
  final String address;
  final String phone;

  final String billNumber;
  final DateTime dateTime;
  final String tableNumber;
  final String waiterName;

  final List<OrderItem> items;
  final double subtotal;
  final double discount;
  final double gst;
  final double totalAmount;

  BillModel({
    required this.restaurantName,
    required this.address,
    required this.phone,
    required this.billNumber,
    required this.dateTime,
    required this.tableNumber,
    this.waiterName = "Cashier",
    required this.items,
    required this.subtotal,
    this.discount = 0.0,
    required this.gst,
    required this.totalAmount,
  });
}
