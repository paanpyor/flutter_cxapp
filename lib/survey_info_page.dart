// lib/survey_info_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_cxapp/csat_page.dart';
import 'package:flutter_cxapp/ces_page.dart';
import 'package:flutter_cxapp/nps_page.dart';
import 'package:flutter_cxapp/survey_type_page.dart';

class SurveyInfoPage extends StatelessWidget {
  final String type;
  final String restaurantId;
  const SurveyInfoPage({super.key, required this.type, required this.restaurantId});

  @override
  Widget build(BuildContext context) {
    final info = _getInfo(type);
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        title: Text("${info["title"]} Explained"),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(info["title"]!, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.indigo)),
            const SizedBox(height: 16),
            Text(info["description"]!, style: const TextStyle(fontSize: 16, height: 1.5)),
            const SizedBox(height: 24),
            if (info["scale"] != null) ...[
              Text("Scale: ${info["scale"]}", style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
            ],
            if (info["example"] != null) ...[
              const Text("Example:", style: TextStyle(fontWeight: FontWeight.bold)),
              Text(info["example"]!, style: const TextStyle(fontSize: 15)),
              const SizedBox(height: 8),
            ],
            const Spacer(),
            SizedBox(
              width: double.infinity,
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
                          default: return SurveyTypePage(restaurantId: restaurantId);
                        }
                      },
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Start Survey", style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, String> _getInfo(String type) {
    switch (type) {
      case "CSAT":
        return {
          "title": "Customer Satisfaction Score (CSAT)",
          "description": "Measures how satisfied customers are with a product, service, or interaction.",
          "scale": "0–10 (0 = Very Dissatisfied, 10 = Very Satisfied)",
          "example": "“How satisfied are you with your dining experience?”"
        };
      case "CES":
        return {
          "title": "Customer Effort Score (CES)",
          "description": "Measures how easy it was for the customer to get an issue resolved or complete a task.",
          "scale": "0–10 (0 = Very Difficult, 10 = Very Easy)",
          "example": "“How easy was it to make a reservation?”"
        };
      case "NPS":
        return {
          "title": "Net Promoter Score (NPS)",
          "description": "Measures customer loyalty and likelihood to recommend your business.",
          "scale": "0–10 (0 = Not at all likely, 10 = Extremely likely)",
          "example": "“How likely are you to recommend this restaurant to a friend?”"
        };
      default:
        return {"title": "Survey", "description": "Thank you for your feedback!"};
    }
  }
}