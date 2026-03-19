import 'package:flutter/material.dart';
import 'package:pos_app/models/cart_item.dart';
import 'package:pos_app/services/language_service.dart';

class PosSummarySection extends StatelessWidget {
  final List<CartItem> cart;
  final double subtotal;
  final double discountPercentage;
  final double totalDiscount;
  final double totalGst;
  final double grandTotal;
  final bool isPrinting;
  final VoidCallback onClearTable;
  final ValueChanged<String> onPrintReceipt;
  final VoidCallback onPayAndClose;
  final ValueChanged<String> onDiscountChanged;

  const PosSummarySection({
    super.key,
    required this.cart,
    required this.subtotal,
    required this.discountPercentage,
    required this.totalDiscount,
    required this.totalGst,
    required this.grandTotal,
    required this.isPrinting,
    required this.onClearTable,
    required this.onPrintReceipt,
    required this.onPayAndClose,
    required this.onDiscountChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, -5))
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: TextField(
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: "${LanguageService.translate('discount')} (%)",
                    prefixIcon: const Icon(Icons.percent, size: 18),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                  ),
                  onChanged: onDiscountChanged,
                  // We can't use controller here easily without statefullness, but we can set initialValue if we used TextFormField. 
                  // Because the user types, it's simpler to just let them type and it updates state.
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF20B2AA).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF20B2AA).withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Discount Amt", style: TextStyle(fontSize: 10, color: Color(0xFF20B2AA), fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text("-₹${totalDiscount.toStringAsFixed(2)}", style: const TextStyle(fontSize: 14, color: Color(0xFF20B2AA), fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _summaryTotalBar(),
          const SizedBox(height: 15),
          InkWell(
            onTap: cart.isEmpty ? null : onClearTable,
            child: Container(
              height: 45,
              width: double.infinity,
              decoration: BoxDecoration(
                color: cart.isEmpty
                    ? Colors.grey.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: cart.isEmpty ? Colors.grey : Colors.red),
              ),
              child: Center(
                child: Text(
                  LanguageService.translate("clear_table"),
                  style: TextStyle(
                      color: cart.isEmpty ? Colors.grey : Colors.red,
                      fontSize: 14,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: isPrinting ? null : () => onPrintReceipt("KOT"),
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF20B2AA)),
                      boxShadow: [
                        BoxShadow(
                            color: const Color(0xFF20B2AA).withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4))
                      ],
                    ),
                    child: Center(
                        child: Text(
                            isPrinting
                                ? LanguageService.translate("printing")
                                : LanguageService.translate("kot"),
                            style: const TextStyle(
                                color: Color(0xFF20B2AA),
                                fontSize: 16,
                                fontWeight: FontWeight.bold))),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: isPrinting ? null : () => onPrintReceipt("BILL"),
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF8C00),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                            color: const Color(0xFFFF8C00).withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4))
                      ],
                    ),
                    child: Center(
                        child: Text(LanguageService.translate("bill"),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold))),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: isPrinting ? null : onPayAndClose,
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFFDC2626), Color(0xFF991B1B)]),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.red.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4))
                      ],
                    ),
                    child: const Center(
                        child: Text("Pay & Close",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold))),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryTotalBar() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("${LanguageService.translate("total")} :",
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFF1E293B))),
            Text("₹${subtotal.toStringAsFixed(2)}",
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFF1E293B))),
          ],
        ),
        if (totalDiscount > 0) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(LanguageService.translate("discount"),
                  style: const TextStyle(fontSize: 12, color: Colors.green)),
              Text("-₹${totalDiscount.toStringAsFixed(2)}",
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.green)),
            ],
          ),
        ],
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(LanguageService.translate("tax"),
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            Text("₹${totalGst.toStringAsFixed(2)}",
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A))),
          ],
        ),
        const Divider(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(LanguageService.translate("grand_total"),
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B))),
            Text("₹${grandTotal.toStringAsFixed(2)}",
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF4500))),
          ],
        ),
      ],
    );
  }
}
