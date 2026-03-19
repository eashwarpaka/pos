import 'package:flutter/material.dart';
import 'package:pos_app/services/language_service.dart';

class PosSearchBar extends StatelessWidget {
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final ValueChanged<String> onSearchChanged;
  final int quantityToCalculate;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onAddPressed;

  static const tealGradient =
      LinearGradient(colors: [Color(0xFF20B2AA), Color(0xFF008B8B)]);

  const PosSearchBar({
    super.key,
    required this.searchController,
    required this.searchFocusNode,
    required this.onSearchChanged,
    required this.quantityToCalculate,
    required this.onQuantityChanged,
    required this.onAddPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 55,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TextField(
                autofocus: true,
                controller: searchController,
                focusNode: searchFocusNode,
                onChanged: onSearchChanged,
                decoration: InputDecoration(
                  hintText: LanguageService.translate("search"),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Container(
            height: 55,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Text(LanguageService.translate("qty"),
                    style: const TextStyle(
                        color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                IconButton(
                    onPressed: () => onQuantityChanged(
                        (quantityToCalculate > 1) ? quantityToCalculate - 1 : 1),
                    icon: const Icon(Icons.remove, size: 18)),
                Text("$quantityToCalculate",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                IconButton(
                    onPressed: () => onQuantityChanged(quantityToCalculate + 1),
                    icon: const Icon(Icons.add, size: 18)),
              ],
            ),
          ),
          const SizedBox(width: 15),
          InkWell(
            onTap: onAddPressed,
            child: Container(
              height: 55,
              padding: const EdgeInsets.symmetric(horizontal: 35),
              decoration: BoxDecoration(
                gradient: tealGradient,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFF20B2AA).withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Center(
                  child: Text(LanguageService.translate("add"),
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16))),
            ),
          ),
        ],
      ),
    );
  }
}
