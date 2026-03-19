class CartItem {
  final String name;
  final String category;
  double price;
  int quantity;
  final String? image;
  bool isKotSent;

  CartItem({
    required this.name,
    required this.category,
    required this.price,
    this.quantity = 1,
    this.image,
    this.isKotSent = false,
  });

  /// Total price for this item
  double get total => price * quantity;

  // ================= DB SUPPORT =================

  /// Convert CartItem → SQLite Map
  Map<String, dynamic> toMap(int tableId) {
    return {
      'tableId': tableId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'image': image,
      'isKotSent': isKotSent ? 1 : 0,
    };
  }

  /// Create CartItem from SQLite row
  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      name: map['name'] as String,
      category: map['category'] as String? ?? 'General',
      price: (map['price'] as num).toDouble(),
      quantity: map['quantity'] as int,
      image: map['image'] as String?,
      isKotSent: (map['isKotSent'] as int? ?? 0) == 1,
    );
  }

  /// Clone item (safe copy)
  CartItem copy() {
    return CartItem(
      name: name,
      category: category,
      price: price,
      quantity: quantity,
      image: image,
      isKotSent: isKotSent,
    );
  }

  // ================= POS HELPERS =================

  /// Increase quantity
  void increase([int qty = 1]) {
    quantity += qty;
  }

  /// Decrease quantity
  void decrease([int qty = 1]) {
    quantity -= qty;
    if (quantity < 0) quantity = 0;
  }

  /// Set quantity safely
  void setQty(int qty) {
    quantity = qty < 0 ? 0 : qty;
  }

  bool get isEmpty => quantity <= 0;

  // ================= EQUALITY =================
  /// Needed for cart merging
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CartItem &&
          runtimeType == other.runtimeType &&
          name == other.name;

  @override
  int get hashCode => name.hashCode;
}