// lib/ces_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class CESPage extends StatefulWidget {
  final String restaurantId;
  const CESPage({super.key, required this.restaurantId});

  @override
  State<CESPage> createState() => _CESPageState();
}

class _CESPageState extends State<CESPage> {
  final _db = FirebaseDatabase.instance.ref();
  final _feedbackController = TextEditingController();
  final List<String> questions = [
    "Sejauh mana mudah untuk membuat tempahan di restoran kami?",
    "Adakah staf membantu dengan cepat apabila anda perlukan bantuan?",
    "Adakah proses pembayaran mudah difahami?",
    "Adakah anda menghadapi kesukaran ketika membuat pesanan?",
    "Secara keseluruhan, usaha yang diperlukan untuk berurusan dengan kami adalah..."
  ];
  Map<int, double> answers = {};

  Future<void> _submitSurvey() async {
    if (answers.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Sila jawab semua soalan.")),
      );
      return;
    }
    final avgScore = answers.values.reduce((a, b) => a + b) / answers.values.length;
    await _db.child("restaurants/${widget.restaurantId}/surveys").push().set({
      "type": "CES",
      "ces": avgScore,
      "comment": _feedbackController.text.trim(),
      "date": DateTime.now().toIso8601String(),
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Terima kasih atas maklum balas anda!")),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        title: const Text("Customer Effort Score (CES)"),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text(
              "Please rate your effort level (0–10):",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            for (int i = 0; i < questions.length; i++)
              _buildQuestionCard(i, questions[i]),
            const SizedBox(height: 20),
            // Feedback Card
            Card(
              elevation: 2,
              shadowColor: Colors.black12,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Additional Feedback (Optional)",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4F46E5),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _feedbackController,
                      decoration: InputDecoration(
                        hintText: "Share your thoughts...",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2),
                        ),
                      ),
                      maxLines: 3,
                      keyboardType: TextInputType.multiline,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitSurvey,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                child: const Text("Submit Survey"),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(int index, String question) {
    final currentAnswer = answers[index] ?? 0.0;

    String getLabel(double value) {
      if (value <= 2) return "Sangat Sukar";
      if (value <= 4) return "Sukar";
      if (value <= 6) return "Sederhana";
      if (value <= 8) return "Mudah";
      return "Sangat Mudah";
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, height: 1.3),
            ),
            const SizedBox(height: 12),
            Text(
              "${currentAnswer.toStringAsFixed(0)} / 10 — ${getLabel(currentAnswer)}",
              style: TextStyle(
                color: currentAnswer > 0 ? const Color(0xFF4F46E5) : Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: const Color(0xFF4F46E5),
                inactiveTrackColor: const Color(0xFF4F46E5).withOpacity(0.2),
                thumbColor: const Color(0xFF4F46E5),
                overlayColor: const Color(0xFF4F46E5).withOpacity(0.1),
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
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
          ],
        ),
      ),
    );
  }
}