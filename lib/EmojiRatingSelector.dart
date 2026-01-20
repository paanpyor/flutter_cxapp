import 'package:flutter/material.dart';
import 'app_theme.dart';

class EmojiRatingOption {
  final int value;
  final String emoji;
  final String label;
  const EmojiRatingOption({required this.value, required this.emoji, required this.label});
}

class EmojiRatingSelector extends StatefulWidget {
  final List<EmojiRatingOption> options;
  final Function(int) onRatingSelected;
  final int? initialValue;
  const EmojiRatingSelector({super.key, required this.options, required this.onRatingSelected, this.initialValue});

  @override
  State<EmojiRatingSelector> createState() => _EmojiRatingSelectorState();
}

class _EmojiRatingSelectorState extends State<EmojiRatingSelector> {
  int? _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.initialValue;
  }

  void _handleTap(int value) {
    setState(() => _selectedValue = value);
    widget.onRatingSelected(value);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: widget.options.length,
        itemBuilder: (context, index) {
          final option = widget.options[index];
          final isSelected = _selectedValue == option.value;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primary.withOpacity(0.1) : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(color: isSelected ? AppTheme.primary : Colors.transparent, width: 3.0),
                  ),
                  child: Center(child: Text(option.emoji, style: const TextStyle(fontSize: 32))),
                ),
                const SizedBox(height: 8),
                Text(option.label, style: TextStyle(fontSize: 12, color: isSelected ? AppTheme.primary : Colors.grey.shade600, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
              ],
            ),
          );
        },
      ),
    );
  }
}