
import 'package:flutter/material.dart';
/// Reusable widget for rating scales.

class RatingScaleWidget extends StatelessWidget {
  final int max;
  final int groupValue;
  final ValueChanged<int?> onChanged;
  final Color activeColor;

  const RatingScaleWidget({
    super.key,
    required this.max,
    required this.groupValue,
    required this.onChanged,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(max, (index) {
          final score = index + 1;
          return Expanded(
            child: RadioListTile<int>(
              title: Text('$score', textAlign: TextAlign.center),
              value: score,
              groupValue: groupValue,
              onChanged: onChanged,
              contentPadding: EdgeInsets.zero,
              activeColor: activeColor,
            ),
          );
        }),
      ),
    );
  }
}

/// Reusable widget for navigation buttons.
class StepButtonWidget extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color backgroundColor;

  const StepButtonWidget({
    super.key,
    required this.text,
    required this.onPressed,
    this.backgroundColor = Colors.indigo,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 5,
        ),
        child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

