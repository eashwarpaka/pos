import 'package:flutter/material.dart';
import 'package:pos_app/models/cart_item.dart';
import 'package:pos_app/services/language_service.dart';

class PosCartTable extends StatelessWidget {
  final List<CartItem> cart;
  final void Function(CartItem item, int delta) onQtyChanged;

  const PosCartTable({
    super.key,
    required this.cart,
    required this.onQtyChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: const Color(0xFFF8FAFC),
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
          child: Row(
            children: [
              SizedBox(
                  width: 30,
                  child: Text(LanguageService.translate("serial"),
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF94A3B8)))),
              Expanded(
                  child: Text(LanguageService.translate("item_name"),
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF94A3B8)))),
              SizedBox(
                  width: 90,
                  child: Text(LanguageService.translate("qty"),
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF94A3B8)))),
              SizedBox(
                  width: 60,
                  child: Text(LanguageService.translate("rate"),
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF94A3B8)))),
              SizedBox(
                  width: 60,
                  child: Text(LanguageService.translate("amount"),
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF94A3B8)))),
              const SizedBox(width: 30),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: cart.length,
            itemBuilder: (context, index) {
              final item = cart[index];
              return Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
                decoration: const BoxDecoration(
                    border:
                        Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
                child: Row(
                  children: [
                    SizedBox(
                        width: 30,
                        child: CircleAvatar(
                            radius: 10,
                            backgroundColor:
                                const Color(0xFFEC4899).withOpacity(0.1),
                            child: Text("${index + 1}",
                                style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFFEC4899),
                                    fontWeight: FontWeight.bold)))),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(item.name,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E293B)))),
                    SizedBox(
                      width: 90,
                      child: Row(
                        children: [
                          _qtyBtn(Icons.remove, () => onQtyChanged(item, -1)),
                          Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: Text("${item.quantity}",
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold))),
                          _qtyBtn(Icons.add, () => onQtyChanged(item, 1)),
                        ],
                      ),
                    ),
                    SizedBox(
                        width: 60,
                        child: Text("₹${item.price}",
                            style: const TextStyle(
                                fontSize: 13, color: Color(0xFF64748B)))),
                    SizedBox(
                        width: 60,
                        child: Text("₹${item.total}",
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A)))),
                    SizedBox(
                        width: 30,
                        child: IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.red, size: 18),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => onQtyChanged(item, -item.quantity))),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
            color: const Color(0xFF20B2AA),
            borderRadius: BorderRadius.circular(6)),
        child: Icon(icon, size: 12, color: Colors.white),
      ),
    );
  }
}
