import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
      appBar:
          AppBar(title: const Text("Submit Feedback"), backgroundColor: Colors.indigo),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: "Your Feedback",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 25),
            ElevatedButton.icon(
              onPressed: _loading ? null : _submitFeedback,
              icon: const Icon(Icons.send),
              label: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Submit"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
