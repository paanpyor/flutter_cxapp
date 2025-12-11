import 'package:flutter/material.dart';

// 1. Define the data structure for the rating options
class EmojiRatingOption {
  final int value;
  final String emoji;
  final Color color;
  final String description;

  const EmojiRatingOption(this.value, this.emoji, this.color, this.description);
}

// 2. The Widget to display the rating options
class EmojiRatingSelector extends StatefulWidget {
  final List<EmojiRatingOption> options;
  final ValueChanged<int> onRatingSelected;
  final int? initialValue;

  const EmojiRatingSelector({
    super.key,
    required this.options,
    required this.onRatingSelected,
    this.initialValue,
  });

  @override
  State<EmojiRatingSelector> createState() => _EmojiRatingSelectorState();
}

class _EmojiRatingSelectorState extends State<EmojiRatingSelector> {
  // Holds the currently selected rating value (e.g., 1, 2, 3, 4, 5)
  int? _selectedRating;

  @override
  void initState() {
    super.initState();
    _selectedRating = widget.initialValue;
  }

  // 3. The core builder for each individual emoji button
  Widget _buildRatingButton(EmojiRatingOption option) {
    // Determine if this option is currently selected
    final bool isSelected = _selectedRating == option.value;
    
    // The scale factor for the animation (larger when selected)
    final double scale = isSelected ? 1.2 : 1.0;
    
    // The border color changes based on selection
    final Color borderColor = isSelected ? option.color : Colors.transparent;
    
    // The duration for the implicit animation (smooth transition)
    const Duration animationDuration = Duration(milliseconds: 250);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRating = option.value;
          widget.onRatingSelected(option.value);
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Column(
          children: [
            // AnimatedScale provides the "pop" or "bounce" effect
            AnimatedScale(
              scale: scale,
              duration: animationDuration,
              curve: Curves.easeOut,
              child: AnimatedContainer(
                duration: animationDuration,
                height: 50,
                width: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white, // Background for the emoji
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: borderColor,
                    width: 3.0,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: option.color.withOpacity(0.4),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ]
                      : [],
                ),
                child: Text(
                  option.emoji,
                  style: const TextStyle(fontSize: 32),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Optional: Show the description below the emoji
            Text(
              option.description,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? option.color : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: widget.options.map(_buildRatingButton).toList(),
        ),
      ),
    );
  }
}