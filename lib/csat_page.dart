import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class CSATPage extends StatefulWidget {
  final String restaurantId;
  const CSATPage({super.key, required this.restaurantId});

  @override
  State<CSATPage> createState() => _CSATPageState();
}

class _CSATPageState extends State<CSATPage> {
  final _db = FirebaseDatabase.instance.ref();
  final _feedbackController = TextEditingController();

  final List<String> questions = [
    "Adakah anda berpuas hati dengan layanan staf kami?",
    "Adakah makanan dihidang tepat pada masanya?",
    "Bagaimana anda menilai kebersihan restoran?",
    "Adakah harga makanan berpatutan?",
    "Adakah anda akan datang semula ke restoran ini?"
  ];

  Map<int, double> answers = {};

  Future<void> _submitSurvey() async {
    if (answers.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Sila jawab semua soalan.")),
      );
      return;
    }

    final avgScore =
        answers.values.reduce((a, b) => a + b) / answers.values.length;

    await _db.child("restaurants/${widget.restaurantId}/surveys").push().set({
      "type": "CSAT",
      "csat": avgScore,
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
      appBar:
          AppBar(title: const Text("CSAT Survey"), backgroundColor: Colors.indigo),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            for (int i = 0; i < questions.length; i++)
              Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(questions[i],
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      Slider(
                        value: answers[i] ?? 0,
                        divisions: 10,
                        min: 0,
                        max: 10,
                        label: "${answers[i]?.toStringAsFixed(0) ?? 0}",
                        onChanged: (v) => setState(() => answers[i] = v),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 10),
            TextField(
              controller: _feedbackController,
              decoration: const InputDecoration(
                labelText: "Berikan maklum balas tambahan (optional)",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitSurvey,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
              child: const Text("Submit Survey"),
            ),
          ],
        ),
      ),
    );
  }
}
