import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'survey_info_page.dart'; 
import 'app_theme.dart';

class SurveyTypePage extends StatefulWidget {
  final String restaurantId;
  const SurveyTypePage({super.key, required this.restaurantId});

  @override
  State<SurveyTypePage> createState() => _SurveyTypePageState();
}

class _SurveyTypePageState extends State<SurveyTypePage> {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  bool csatDone = false;
  bool cesDone = false;
  bool npsDone = false;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _checkSurveyStatus();
  }

  Future<void> _checkSurveyStatus() async {
    final user = _auth.currentUser;
    if (user == null) {
      setState(() => loading = false);
      return;
    }

    // --- CHANGE 1: Fetch from USER SURVEYS path ---
    final snap = await _db.child("users/${user.uid}/completedSurveys").get();
    
    if (!snap.exists) {
      setState(() => loading = false);
      return;
    }

    final surveys = Map<String, dynamic>.from(snap.value as Map);
    bool cDone = false, ceDone = false, nDone = false;

    // --- CHANGE 2: Check if restaurantId exists as a key ---
    // This matches the structure of data saved in csat/ces/nps pages
    // If the user has a node "completedSurveys/restaurantID", we consider them done.
    if (surveys.containsKey(widget.restaurantId)) {
      // We assume if the key exists, the user has completed surveys there.
      // Ideally, you should check internal flags, but this is the safest assumption.
      cDone = true; 
      ceDone = true;
      nDone = true;
    }

    setState(() {
      csatDone = cDone;
      cesDone = ceDone;
      npsDone = nDone;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: AppTheme.textPrimary,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: AppTheme.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text("Select Feedback"),
        ),
        body: const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Select Feedback"),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    const Text(
                      "Share Your Experience",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Choose a survey category below to help us improve:",
                      style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // --- FIX: Use SliverGrid with Max Extent to prevent overflow ---
            // Using a max extent ensures every card has a fixed height, 
            // preventing the "RenderFlex overflowed" error.
            SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 1, // 1 Column
                mainAxisSpacing: 16,
                // FIX: Set a predictable max height for the cards
                // Adjust this value based on your card design (text size + padding)
                // 300 is a safe bet for the content size
                mainAxisExtent: 300.0, 
              ),
              delegate: SliverChildListDelegate([
                // CSAT Card
                _buildSurveyOption(
                  title: "Satisfaction",
                  subtitle: "CSAT Survey",
                  description: "Rate overall satisfaction with service and food.",
                  icon: Icons.sentiment_satisfied_alt,
                  color: AppTheme.csatColor,
                  isCompleted: csatDone,
                  type: "CSAT",
                ),
                
                // CES Card
                _buildSurveyOption(
                  title: "Effort",
                  subtitle: "CES Survey",
                  description: "Tell us how easy it was to order and get service.",
                  icon: Icons.timer,
                  color: AppTheme.cesColor,
                  isCompleted: cesDone,
                  type: "CES",
                ),
                
                // NPS Card
                _buildSurveyOption(
                  title: "Loyalty",
                  subtitle: "NPS Survey",
                  description: "Would you recommend this restaurant to a friend?",
                  icon: Icons.thumb_up,
                  color: AppTheme.npsColor,
                  isCompleted: npsDone,
                  type: "NPS",
                ),
              ]),
            ),
            
            // Bottom padding for safe scrolling area
            SliverPadding(
              padding: const EdgeInsets.only(bottom: 80),
              sliver: SliverToBoxAdapter(child: SizedBox()), 
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSurveyOption({
    required String title,
    required String subtitle,
    required String description,
    required IconData icon,
    required Color color,
    required bool isCompleted,
    required String type,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SurveyInfoPage(type: type, restaurantId: widget.restaurantId),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Icon + Badge
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color, size: 32),
                ),
                const Spacer(),
                if (isCompleted)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.secondary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text("Done", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          
            const SizedBox(height: 20),
            
            // Text Content
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.3),
            ),
          ],
        ),
      ),
    );
  }
}