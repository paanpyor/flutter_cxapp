import 'package:flutter/material.dart';

class MetricBentoCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;
  final bool isLarge; // For the main NPS metric

  const MetricBentoCard({
    super.key,
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isLarge ? 8 : 4, // Higher elevation for the main metric
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: color.withOpacity(isLarge ? 0.15 : 0.05), // Subtle color wash
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.4), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Icon and Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isLarge ? 16 : 14,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Icon(icon, color: color, size: isLarge ? 30 : 24),
              ],
            ),
            const SizedBox(height: 8),
            // Value
            Text(
              value,
              style: TextStyle(
                fontSize: isLarge ? 48 : 32, // Big Typography
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            // Optional: Trend indicator could go here
          ],
        ),
      ),
    );
  }
}