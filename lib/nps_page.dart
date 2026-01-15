// lib/nps_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class NPSPage extends StatefulWidget {
  final String restaurantId;
  const NPSPage({super.key, required this.restaurantId});

  @override
  State<NPSPage> createState() => _NPSPageState();
}

class _NPSPageState extends State<NPSPage> {
  final _db = FirebaseDatabase.instance.ref();
  final _feedbackController = TextEditingController();
  final List<String> questions = [
    "Sejauh mana anda akan mencadangkan restoran ini kepada rakan?",
    "Adakah anda rasa kualiti makanan kami menepati jangkaan?",
    "Adakah pengalaman makan anda menyeronokkan?",
    "Adakah anda berasa dihargai sebagai pelanggan?",
    "Sejauh mana anda yakin untuk kembali semula ke sini?"
  ];
  Map<int, double> answers = {};

  Future<void> _submitSurvey() async {
    if (answers.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sila jawab semua soalan.")));
      return;
    }
    final avgScore = answers.values.reduce((a, b) => a + b) / answers.values.length;
    await _db.child("restaurants/${widget.restaurantId}/surveys").push().set({
      "type": "NPS",
      "nps": avgScore,
      "comment": _feedbackController.text.trim(),
      "date": DateTime.now().toIso8601String(),
    });
    Navigator.pop(context);
    // Optional: show summary page
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        title: const Text("Net Promoter Score (NPS)"),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text("Rate from 0 (Detractor) to 10 (Promoter)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            for (int i = 0; i < questions.length; i++) _buildQuestionCard(i, questions[i]),
            const SizedBox(height: 20),
            _buildFeedbackCard(),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitSurvey,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Submit Survey", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(int index, String question) {
    final currentAnswer = answers[index] ?? 0.0;
    String getLabel(double value) => value < 7 ? "Detraktor" : value < 9 ? "Pasif" : "Promoter";
    Color getColor(double value) => value < 7 ? Colors.red : value < 9 ? Colors.orange : Colors.green;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(question, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text("${currentAnswer.toStringAsFixed(0)} / 10 — ${getLabel(currentAnswer)}", style: TextStyle(color: getColor(currentAnswer), fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF4F46E5),
              inactiveTrackColor: const Color(0xFF4F46E5).withOpacity(0.2),
              thumbColor: const Color(0xFF4F46E5),
              overlayColor: const Color(0xFF4F46E5).withOpacity(0.1),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            ),
            child: Slider(
              value: currentAnswer,
              divisions: 10,
              min: 0,
              max: 10,
              label: currentAnswer.toStringAsFixed(0),
              onChanged: (value) => setState(() => answers[index] = value),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildFeedbackCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text("Additional Feedback (Optional)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5))),
          const SizedBox(height: 10),
          TextField(
            controller: _feedbackController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: "Share your thoughts...",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2)),
            ),
          ),
        ]),
      ),
    );
  }
}