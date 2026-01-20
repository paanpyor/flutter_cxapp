import 'package:flutter/material.dart';
import 'csat_page.dart';
import 'ces_page.dart';
import 'nps_page.dart';
import 'app_theme.dart';

class SurveyInfoPage extends StatelessWidget {
  final String type;
  final String restaurantId;

  const SurveyInfoPage({super.key, required this.type, required this.restaurantId});

  @override
  Widget build(BuildContext context) {
    final info = _getInfo(type);
    
    // Determine theme color based on type
    final themeColor = type == "CSAT" ? AppTheme.csatColor 
                    : type == "CES" ? AppTheme.cesColor 
                    : AppTheme.npsColor;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("${info["title"]} Explained"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            
            // Hero Icon
            Center(
              child: Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: themeColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  info["icon"],
                  size: 80,
                  color: themeColor,
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // Title
            Text(
              info["title"]!,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            
            // Description
            Text(
              info["description"]!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
            
            const SizedBox(height: 40),

            // Scale & Example Sections
            Container(
              padding: const EdgeInsets.all(24),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Scale Row
                  Row(
                    children: [
                      const Icon(Icons.bar_chart, color: AppTheme.textSecondary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Rating Scale",
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              info["scale"] ?? "N/A",
                              style: const TextStyle(fontSize: 16, color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  
                  // Example Question Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: themeColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: themeColor.withOpacity(0.2), width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Example Question",
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          info["example"]!,
                          style: const TextStyle(
                            fontSize: 15,
                            fontStyle: FontStyle.italic,
                            color: AppTheme.textPrimary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            
            // Start Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) {
                        switch (type) {
                          case "CSAT": return CSATPage(restaurantId: restaurantId);
                          case "CES": return CESPage(restaurantId: restaurantId);
                          case "NPS": return NPSPage(restaurantId: restaurantId);
                          default: return const SizedBox.shrink();
                        }
                      },
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text("Start Survey", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getInfo(String type) {
    switch (type) {
      case "CSAT":
        return {
          "title": "CSAT",
          "description": "Measures how satisfied customers are with a product, service, or interaction.",
          "scale": "0–10 (Very Dissatisfied to Very Satisfied)",
          "example": "“How satisfied are you with your dining experience?”",
          "icon": Icons.sentiment_satisfied_alt
        };
      case "CES":
        return {
          "title": "CES",
          "description": "Measures how easy it was for the customer to get an issue resolved or complete a task.",
          "scale": "0–10 (Very Difficult to Very Easy)",
          "example": "“How easy was it to make a reservation?”",
          "icon": Icons.timer
        };
      case "NPS":
        return {
          "title": "NPS",
          "description": "Measures customer loyalty and likelihood to recommend your business.",
          "scale": "0–10 (Not likely to Extremely likely)",
          "example": "“How likely are you to recommend this restaurant?”",
          "icon": Icons.thumb_up
        };
      default:
        return {"title": "Survey", "description": "Thank you!", "icon": Icons.question_answer};
    }
  }

  
}