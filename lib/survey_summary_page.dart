import 'package:flutter/material.dart';

class SurveySummaryPage extends StatelessWidget {
  final String title;
  final double score;
  final Color color;

  const SurveySummaryPage({
    super.key,
    required this.title,
    required this.score,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, size: 90, color: color),
              const SizedBox(height: 20),
              Text(
                title,
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold, color: color),
              ),
              const SizedBox(height: 10),
              Text(
                "Your score: ${score.toStringAsFixed(1)}",
                style: const TextStyle(fontSize: 18, color: Colors.black54),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
                style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 40)),
                child: const Text("Back to Dashboard",
                    style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
