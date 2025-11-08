import 'package:flutter/material.dart';

class ThreePanelLayout extends StatelessWidget {
  final Widget top;
  final Widget middle;
  final Widget bottom;
  const ThreePanelLayout(
      {super.key, required this.top, required this.middle, required this.bottom});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          width: double.infinity,
          color: Colors.indigo,
          child: top,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: middle,
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          width: double.infinity,
          color: Colors.grey[100],
          child: bottom,
        ),
      ],
    );
  }
}
