import 'package:flutter/material.dart';
import 'app_theme.dart';

class MetricBentoCard extends StatelessWidget {
  final String title;
  final String value;
  final Color? color;
  final IconData icon;
  final bool isLarge; // True for main metrics, False for grid items
  final VoidCallback? onTap;

  const MetricBentoCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.color,
    this.isLarge = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = color ?? AppTheme.primary;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(isLarge ? 20 : 16),
        splashColor: cardColor.withOpacity(0.2),
        child: Container(
          decoration: BoxDecoration(
            color: cardColor.withOpacity(isLarge ? 0.12 : 0.05),
            borderRadius: BorderRadius.circular(isLarge ? 20 : 16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: isLarge ? 15 : 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: !isLarge 
                ? Border.all(color: cardColor.withOpacity(0.2), width: 1) 
                : null,
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: TextStyle(fontSize: isLarge ? 16 : 14, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                  Container(
                    padding: EdgeInsets.all(isLarge ? 10 : 6),
                    decoration: BoxDecoration(color: cardColor.withOpacity(0.2), shape: BoxShape.circle),
                    child: Icon(icon, color: cardColor, size: isLarge ? 28 : 20),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(value, style: TextStyle(fontSize: isLarge ? 48 : 32, fontWeight: FontWeight.w900, color: cardColor, letterSpacing: -1)),
            ],
          ),
        ),
      ),
    );
  }
}