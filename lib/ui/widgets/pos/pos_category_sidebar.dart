import 'package:flutter/material.dart';
import 'dart:ui';

class PosCategorySidebar extends StatelessWidget {
  final List<String> categories;
  final int selectedCategoryIndex;
  final ValueChanged<int> onCategorySelected;
  final ScrollController categoryScrollController;

  const PosCategorySidebar({
    super.key,
    required this.categories,
    required this.selectedCategoryIndex,
    required this.onCategorySelected,
    required this.categoryScrollController,
  });

  IconData _getCategoryIcon(String category) {
    category = category.toLowerCase();
    if (category == "all") return Icons.all_inclusive_rounded;
    if (category.contains("pizza")) return Icons.local_pizza_outlined;
    if (category.contains("burger")) return Icons.lunch_dining_outlined;
    if (category.contains("drink") || category.contains("beverage")) return Icons.local_bar_outlined;
    if (category.contains("coffee") || category.contains("tea")) return Icons.coffee_outlined;
    if (category.contains("dessert") || category.contains("cake")) return Icons.cake_outlined;
    if (category.contains("pasta")) return Icons.restaurant_menu;
    if (category.contains("biryani") || category.contains("rice")) return Icons.rice_bowl_outlined;
    if (category.contains("chinese") || category.contains("noodle")) return Icons.ramen_dining_outlined;
    return Icons.fastfood_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120, // slightly taller to fit scrollbar comfortably
      color: Colors.white,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
            PointerDeviceKind.trackpad,
          },
        ),
        child: Scrollbar(
          controller: categoryScrollController,
          thumbVisibility: true,
          thickness: 6,
          radius: const Radius.circular(10),
          child: ListView.builder(
            controller: categoryScrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(10, 5, 10, 15), // pad bottom for scrollbar
            itemCount: categories.length,
            itemBuilder: (context, index) {
          final isSelected = selectedCategoryIndex == index;

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: InkWell(
              onTap: () => onCategorySelected(index),
              child: Container(
                width: 110,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFFF8C00) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 6,
                    )
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _getCategoryIcon(categories[index]),
                      size: 24,
                      color: isSelected ? Colors.white : Colors.grey,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      categories[index],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      ),
      ),
    );
  }
}
