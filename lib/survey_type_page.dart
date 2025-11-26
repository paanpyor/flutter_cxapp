
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_cxapp/csat_page.dart';
import 'package:flutter_cxapp/ces_page.dart';
import 'package:flutter_cxapp/nps_page.dart';

class SurveyTypePage extends StatefulWidget {
  final String restaurantId;
  const SurveyTypePage({super.key, required this.restaurantId});

  @override
  State<SurveyTypePage> createState() => _SurveyTypePageState();
}

class _SurveyTypePageState extends State<SurveyTypePage> {
  final _db = FirebaseDatabase.instance.ref();
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
    final snap =
        await _db.child("restaurants/${widget.restaurantId}/surveys").get();
    if (!snap.exists) {
      setState(() => loading = false);
      return;
    }

    final surveys = (snap.value as Map).cast<String, dynamic>();
    for (var s in surveys.values) {
      final survey = Map<String, dynamic>.from(s);
      if (survey["type"] == "CSAT") csatDone = true;
      if (survey["type"] == "CES") cesDone = true;
      if (survey["type"] == "NPS") npsDone = true;
    }

    setState(() => loading = false);
  }

  // ✅ Define color method with full block syntax to avoid IDE warnings
  Color _getStatusColor(bool done) {
    return done ? Colors.green : Colors.indigo;
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        backgroundColor: const Color(0xfff8f9fa),
        body: Center(child: CircularProgressIndicator(color: Colors.indigo)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xfff8f9fa),
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        title: const Text("Choose Survey Type"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Share Your Experience",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Complete the surveys below to help us improve:",
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 24),

            _buildSurveyCard(
              title: "CSAT Survey",
              icon: Icons.star,
              description: "Rate your satisfaction with service, food, and overall experience.",
              isCompleted: csatDone,
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CSATPage(restaurantId: widget.restaurantId),
                  ),
                );
                _checkSurveyStatus();
              },
            ),
            const SizedBox(height: 16),

            _buildSurveyCard(
              title: "CES Survey",
              icon: Icons.handshake,
              description: "Tell us how easy it was to order, get help, or resolve issues.",
              isCompleted: cesDone,
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CESPage(restaurantId: widget.restaurantId),
                  ),
                );
                _checkSurveyStatus();
              },
            ),
            const SizedBox(height: 16),

            _buildSurveyCard(
              title: "NPS Survey",
              icon: Icons.thumb_up,
              description: "Would you recommend this restaurant to friends or family?",
              isCompleted: npsDone,
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NPSPage(restaurantId: widget.restaurantId),
                  ),
                );
                _checkSurveyStatus();
              },
            ),

            const Spacer(),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.indigo.withOpacity(0.04),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.indigo.withOpacity(0.7),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Completed surveys are marked with a green badge. You may retake any survey.",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.indigo.withOpacity(0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSurveyCard({
    required String title,
    required IconData icon,
    required String description,
    required bool isCompleted,
    required VoidCallback onTap,
  }) {
    final cardColor = isCompleted ? Colors.green.shade50 : Colors.white;
    final iconColor = _getStatusColor(isCompleted);

    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: cardColor,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: iconColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isCompleted)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              "Completed",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        else
                          Icon(Icons.arrow_forward_ios,
                              size: 16, color: Colors.grey),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}