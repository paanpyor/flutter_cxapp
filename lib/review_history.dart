import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'app_theme.dart';

class ReviewHistoryPage extends StatelessWidget {
  final List<Map<String, dynamic>> surveys;

  const ReviewHistoryPage({super.key, required this.surveys});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("My Review History"),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primary,
        elevation: 0,
      ),
      body: surveys.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 60, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    "No surveys completed yet.",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: surveys.length,
              itemBuilder: (context, index) {
                final survey = surveys[index];
                return _buildHistoryCard(survey);
              },
            ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> survey) {
    DateTime date = DateTime.parse(survey["date"]);
    String formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(date);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Image + Info
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  survey["imageUrl"],
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 60, 
                    height: 60, 
                    color: Colors.grey[300],
                    child: const Icon(Icons.restaurant, size: 30),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      survey["restaurantName"],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold, 
                        fontSize: 16, 
                        color: AppTheme.textPrimary
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      survey["location"],
                      style: const TextStyle(
                        fontSize: 13, 
                        color: AppTheme.textSecondary
                      ),
                    ),
                  ],
                ),
              ),
              // Date Column
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formattedDate,
                    style: const TextStyle(
                      fontSize: 11, 
                      color: Colors.grey, 
                      fontWeight: FontWeight.w500
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Review: DISPLAY CSAT, CES, NPS SCORES
          const Text(
            "Your Answers:", 
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildScoreBadge("CSAT", survey["csat"], AppTheme.csatColor),
              const SizedBox(width: 8),
              _buildScoreBadge("CES", survey["ces"], AppTheme.cesColor),
              const SizedBox(width: 8),
              _buildScoreBadge("NPS", survey["nps"], AppTheme.npsColor),
            ],
          ),
        ],
      ),
    );
  }

  // Helper for small score badge
  Widget _buildScoreBadge(String label, dynamic value, Color color) {
    // Handle nulls gracefully
    final scoreValue = (value is num) ? value.toDouble() : 0.0;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
          const SizedBox(width: 6),
          Text(
            // Show "-" if score is 0 (e.g. only NPS taken), otherwise show value
            (scoreValue > 0) ? scoreValue.toStringAsFixed(1) : "-",
            style: TextStyle(fontSize: 14, color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}