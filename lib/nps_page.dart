import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_theme.dart';

class NPSPage extends StatefulWidget {
  final String restaurantId;
  const NPSPage({super.key, required this.restaurantId});

  @override
  State<NPSPage> createState() => _NPSPageState();
}

class _NPSPageState extends State<NPSPage> {
  final _db = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _feedbackController = TextEditingController();

  final List<String> questions = [
    "Sejauh mana anda akan mencadangkan restoran ini kepada rakan?",
    "Adakah anda rasa kualiti makanan kami menepati jangkaan?",
    "Adakah pengalaman makan anda menyeronokan?",
    "Adakah anda berasa dihargai sebagai pelanggan?",
    "Sejauh mana anda yakin untuk kembali semula ke sini?"
  ];

  Map<int, double> answers = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(bottom: 20),
              title: const Text(
                "Loyalty",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6366F1),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Progress", style: const TextStyle(fontSize: 16, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "${answers.length}/${questions.length}",
                          style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ...List.generate(questions.length, (i) => _buildQuestionCard(i, questions[i])),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Additional Feedback",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _feedbackController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: "Share your thoughts...",
                            filled: true,
                            fillColor: Colors.grey[50],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitSurvey,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: const Text("Submit Feedback", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitSurvey() async {
    if (answers.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Sila jawab semua soalan."), backgroundColor: AppTheme.error),
      );
      return;
    }
    
    final user = _auth.currentUser;
    if (user == null) return;

    final avgScore = answers.values.reduce((a, b) => a + b) / answers.values.length;
    final now = DateTime.now().toIso8601String();

    // 1. Save to Restaurant Stats
    await _db.child("restaurants/${widget.restaurantId}/surveys").push().set({
      "type": "NPS",
      "nps": avgScore,
      "comment": _feedbackController.text.trim(),
      "date": now,
    });

    // 2. Save to User History (Use .update to preserve other scores)
    await _db.child("users/${user.uid}/completedSurveys/${widget.restaurantId}").update({
      "completed": true,
      "date": now,
      "nps": avgScore, // <--- CRITICAL FIX
    });

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Terima kasih atas maklum balas anda!"), backgroundColor: const Color(0xFF6366F1)),
    );
  }

  Widget _buildQuestionCard(int index, String question) {
    final currentAnswer = answers[index] ?? 0.0;
    
    String getLabel(double value) {
      if (value < 7) return "Detraktor";
      if (value < 9) return "Pasif";
      return "Promoter";
    }

    Color getColor(double value) {
      if (value < 7) return Colors.red;
      if (value < 9) return Colors.orange;
      return const Color(0xFF10B981); // Green
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Q${index + 1}. $question",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
          ),
          const SizedBox(height: 20),
          
          Row(
            children: [
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: const Color(0xFF6366F1),
                    inactiveTrackColor: const Color(0xFF6366F1).withOpacity(0.2),
                    thumbColor: const Color(0xFF6366F1),
                    overlayColor: const Color(0xFF6366F1).withOpacity(0.1),
                    trackHeight: 6,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                  ),
                  child: Slider(
                    value: currentAnswer,
                    divisions: 10,
                    min: 0,
                    max: 10,
                    onChanged: (value) => setState(() => answers[index] = value),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: getColor(currentAnswer).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    currentAnswer.toInt().toString(),
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: getColor(currentAnswer)),
                  ),
                ),
              ),
            ],
          ),
          
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              getLabel(currentAnswer),
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: getColor(currentAnswer)),
            ),
          ),
        ],
      ),
    );
  }
}