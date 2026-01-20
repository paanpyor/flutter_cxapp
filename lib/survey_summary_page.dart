import 'package:flutter/material.dart';
import 'app_theme.dart';

class SurveySummaryPage extends StatelessWidget {
  final String title;
  final double score;
  final String? feedbackText; // Optional feedback text to show

  const SurveySummaryPage({
    super.key,
    required this.title,
    required this.score,
    this.feedbackText,
  });

  Color _getScoreColor() {
    // More intuitive color coding:
    // Good (8-10) = Green
    // Average (5-7) = Orange
    // Poor (0-4) = Red
    if (score >= 8) return Colors.green;
    if (score >= 5) return Colors.orange;
    return AppTheme.error; // Red
  }

  @override
  Widget build(BuildContext context) {
    final scoreColor = _getScoreColor();

    return Scaffold(
      // Dynamic background based on score success
      backgroundColor: scoreColor.withOpacity(0.1),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              
              // Animated Checkmark
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 800),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: scoreColor.withOpacity(0.3),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.check_circle,
                        color: scoreColor,
                        size: 80,
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 32),
              
              Text(
                "Survey Submitted!",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondary
                ),
              ),
              const SizedBox(height: 16),
              
              // Optional Feedback Quote
              if (feedbackText != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    "\"$feedbackText\"",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize: 16,
                      color: AppTheme.textPrimary
                    ),
                  ),
                ),
              
              const SizedBox(height: 20),
              
              // Score Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text("Score", style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
                    Text(
                      score.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: scoreColor,
                      ),
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
              
              // Back Button
              SizedBox(
                width: 200,
                height: 56,
                child: OutlinedButton(
                  onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textPrimary,
                    side: const BorderSide(color: AppTheme.textPrimary, width: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text("Back to Home", style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}