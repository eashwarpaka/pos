import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos_app/services/language_service.dart';
import 'package:pos_app/ui/screens/revenue_screen.dart';

class PosTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String selectedType;
  final ValueChanged<String> onTypeChanged;
  final VoidCallback onCancelTap;
  final DateTime now;

  const PosTopBar({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
    required this.onCancelTap,
    required this.now,
  });

  @override
  Size get preferredSize => const Size.fromHeight(80);

  @override
  Widget build(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(80),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFF8C00), Color(0xFFFF4500)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back,
                      color: Colors.white, size: 32)),
              const SizedBox(width: 10),
              // Logo Placeholder
              Container(
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle),
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(Icons.blur_on, color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 20),
              const SizedBox(width: 20),
              // SERVICE TYPE SELECTOR
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    _typeBtn("dine_in", Icons.restaurant_rounded),
                    _typeBtn("takeaway", Icons.local_mall_rounded),
                  ],
                ),
              ),
              const Spacer(),
              // DATE & TIME
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: Text(
                  DateFormat('dd MMM, yyyy  -  hh:mm:ss a').format(now),
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              _topActionIcon(Icons.cancel_outlined,
                  LanguageService.translate("cancel_order"), onCancelTap),
              const SizedBox(width: 4),
              _topActionIcon(Icons.analytics_outlined,
                  LanguageService.translate("revenue"), () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const RevenueScreen()));
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typeBtn(String type, IconData icon) {
    final isSelected = selectedType == type;
    return InkWell(
      onTap: () => onTypeChanged(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)]
              : null,
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 18,
                color: isSelected ? const Color(0xFFFF4500) : Colors.white70),
            const SizedBox(width: 8),
            Text(LanguageService.translate(type),
                style: TextStyle(
                    color: isSelected ? const Color(0xFFFF4500) : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _topActionIcon(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: Colors.white),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
