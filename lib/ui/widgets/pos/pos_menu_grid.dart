import 'package:flutter/material.dart';

class PosMenuGrid extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final ValueChanged<Map<String, dynamic>> onItemTap;

  const PosMenuGrid({
    super.key,
    required this.items,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        childAspectRatio: 1.5,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        bool isNonVeg = item["isNonVeg"] == true;
            
        return InkWell(
          canRequestFocus: false,
          onTap: () => onItemTap(item),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0).withAlpha(128)), // 0.5 opacity * 255
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withAlpha(5), // 0.02 opacity * 255 = 5.1
                    blurRadius: 10,
                    offset: const Offset(0, 4))
              ],
            ),
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (isNonVeg ? Colors.red : Colors.green)
                            .withAlpha(26), // 0.1 opacity * 255
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(isNonVeg ? "NON-VEG" : "VEG",
                          style: TextStyle(
                              fontSize: 9,
                              color: isNonVeg ? Colors.red : Colors.green,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                Text(item["name"],
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF1E293B)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 5),
              ],
            ),
          ),
        );
      },
    );
  }
}
