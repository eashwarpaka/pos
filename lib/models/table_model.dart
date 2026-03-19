import 'cart_item.dart';

enum TableStatus { available, occupied, billed, reserved }

class RestaurantTable {
  final int number;
  String name;
  TableStatus status;
  List<CartItem> cart;
  DateTime? occupiedAt;

  RestaurantTable({
    required this.number,
    String? name,
    this.status = TableStatus.available,
    List<CartItem>? cart,
    this.occupiedAt,
  })  : name = name ?? "Table $number",
        cart = cart ?? [];

  // ========= STATUS HELPERS =========

  bool get isOccupied => status == TableStatus.occupied;
  bool get isAvailable => status == TableStatus.available;
  bool get isBilled => status == TableStatus.billed;
  bool get isReserved => status == TableStatus.reserved;

  void markOccupied() {
    status = TableStatus.occupied;
    occupiedAt ??= DateTime.now();
  }

  void markAvailable() {
    status = TableStatus.available;
    occupiedAt = null;
  }

  void markBilled() {
    status = TableStatus.billed;
  }

  void markReserved() {
    status = TableStatus.reserved;
    occupiedAt ??= DateTime.now();
  }

  // ========= CART HELPERS =========

  void addItem(CartItem item) {
    final index = cart.indexWhere((i) => i.name == item.name);

    if (index != -1) {
      cart[index].quantity += item.quantity;
    } else {
      cart.add(item);
    }

    status = TableStatus.occupied;
  }

  void removeItem(String name) {
    cart.removeWhere((i) => i.name == name);

    if (cart.isEmpty) {
      status = TableStatus.available;
    }
  }

  void clearCart() {
    cart.clear();
    status = TableStatus.available;
  }

  double get subtotal =>
      cart.fold(0, (sum, item) => sum + item.total);
}