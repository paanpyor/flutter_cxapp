import 'package:flutter/material.dart';
import 'app_theme.dart';

class CommonHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing; // e.g. User Avatar or Notification Icon
 

  const CommonHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,

  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      margin: const EdgeInsets.only(bottom: 24), // Spacing below the header
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24), // Modern "The Fork" rounded corners
        boxShadow: [
          // Soft, diffuse shadow for floating effect
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          // Main Title Section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800, // Extra Bold for impact
                    color: AppTheme.primary, // Vibrant primary color
                    letterSpacing: -0.5, // Tighter tracking
                  ),
                ),
                // Optional Subtitle (e.g., "Good Morning")
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Optional Trailing Widget
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
