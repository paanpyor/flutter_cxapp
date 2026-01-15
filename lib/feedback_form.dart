// lib/feedback_form_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class FeedbackFormPage extends StatefulWidget {
  final String restaurantId;
  const FeedbackFormPage({super.key, required this.restaurantId});

  @override
  State<FeedbackFormPage> createState() => _FeedbackFormPageState();
}

class _FeedbackFormPageState extends State<FeedbackFormPage> {
  final _controller = TextEditingController();
  bool _loading = false;

  Future<void> _submitFeedback() async {
    if (_controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please write your feedback")),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseDatabase.instance
          .ref("restaurants/${widget.restaurantId}/feedback")
          .push()
          .set({
        "user": user?.email ?? "Anonymous",
        "comment": _controller.text.trim(),
        "date": DateTime.now().toIso8601String(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Feedback submitted!")),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed to send feedback: $e")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Submit Feedback"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _controller,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: "Share your thoughts...",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.indigo, width: 2),
                    ),
                    prefixIcon: const Icon(Icons.message_outlined, color: Colors.grey),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _submitFeedback,
                icon: const Icon(Icons.send_rounded, color: Colors.white),
                label: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Submit Feedback", style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}