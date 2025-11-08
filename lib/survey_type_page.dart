import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'csat_page.dart';
import 'ces_page.dart';
import 'nps_page.dart';

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

  Color _getColor(bool done) => done ? Colors.green : Colors.red;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Choose Survey Type"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _surveyCard(
              context,
              title: "CSAT Survey",
              color: _getColor(csatDone),
              icon: Icons.star,
              description:
                  "CSAT (Customer Satisfaction Score) mengukur kepuasan pelanggan terhadap perkhidmatan anda.",
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
            const SizedBox(height: 20),
            _surveyCard(
              context,
              title: "CES Survey",
              color: _getColor(cesDone),
              icon: Icons.handshake,
              description:
                  "CES (Customer Effort Score) mengukur kemudahan pelanggan berurusan dengan anda.",
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
            const SizedBox(height: 20),
            _surveyCard(
              context,
              title: "NPS Survey",
              color: _getColor(npsDone),
              icon: Icons.favorite,
              description:
                  "NPS (Net Promoter Score) mengukur kesetiaan pelanggan dan kebarangkalian mereka mencadangkan anda.",
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
          ],
        ),
      ),
    );
  }

  Widget _surveyCard(BuildContext context,
      {required String title,
      required String description,
      required IconData icon,
      required Color color,
      required VoidCallback onTap}) {
    return Card(
      color: color.withOpacity(0.1),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 40),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, color: color),
                ],
              ),
              const SizedBox(height: 10),
              Text(description,
                  style: const TextStyle(fontSize: 14, color: Colors.black54)),
            ],
          ),
        ),
      ),
    );
  }
}
