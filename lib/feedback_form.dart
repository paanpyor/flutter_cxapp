import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'app_theme.dart';
import 'custom_button.dart'; 


class FeedbackFormPage extends StatefulWidget {
  final String restaurantId;
  const FeedbackFormPage({super.key, required this.restaurantId});

  @override
  State<FeedbackFormPage> createState() => _FeedbackFormPageState();
}

class _FeedbackFormPageState extends State<FeedbackFormPage> {
  final _controller = TextEditingController();
  bool _loading = false;

  // --- YOUR EXISTING LOGIC (UNCHANGED) ---
  Future<void> _submitFeedback() async {
    final text = _controller.text.trim();

    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please write your feedback")),
      );
      return;
    }

    if (text.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Feedback is too short!")),
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
        "comment": text,
        "date": DateTime.now().toIso8601String(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Feedback submitted!"),
          backgroundColor: AppTheme.secondary, // Green success color
        ),
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

  // --- BUILD WIDGET: UPDATED TO "THE FORK" DESIGN ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background, // Off-white background
      appBar: AppBar(
        title: const Text("Send Feedback"),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppTheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        // Fix keyboard overflow
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height - 
                       MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // 1. Hero Icon Illustration
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.rate_review_outlined, 
                      size: 64, 
                      color: AppTheme.primary
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // 2. Title & Subtitle
                Text(
                  "We value your opinion!",
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 22
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  "Help us improve by sharing your thoughts about this restaurant.",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.grey, 
                    fontSize: 14
                  ),
                ),
                const SizedBox(height: 30),

                // 3. Feedback Input Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)
                  ),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Your Feedback",
                          style: TextStyle(
                            fontSize: 16, 
                            fontWeight: FontWeight.bold
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        TextField(
                          controller: _controller,
                          maxLines: 6,
                          maxLength: 200,
                          // Update character count on typing
                          onChanged: (text) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: "Share your thoughts...",
                            hintStyle: TextStyle(
                              color: Colors.grey[400]
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Character Counter
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            "${_controller.text.length} / 200",
                            style: const TextStyle(
                              fontSize: 12, 
                              color: Colors.grey
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // 4. Submit Button
                AppButton(
                  text: "Submit Feedback",
                  icon: Icons.send_rounded,
                  isLoading: _loading,
                  onPressed: _submitFeedback,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}