// lib/restaurant_insights_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'qr_generate_page.dart';
import 'package:intl/intl.dart';

class RestaurantInsightsPage extends StatefulWidget {
  final String restaurantId;
  final String restaurantName;
  const RestaurantInsightsPage({super.key, required this.restaurantId, required this.restaurantName});

  @override
  State<RestaurantInsightsPage> createState() => _RestaurantInsightsPageState();
}

class _RestaurantInsightsPageState extends State<RestaurantInsightsPage> {
  final _db = FirebaseDatabase.instance.ref();
  bool _loading = true;
  double _avgCSAT = 0, _avgCES = 0, _avgNPS = 0;
  List<Map<String, dynamic>> _recentFeedback = [];

  @override
  void initState() {
    super.initState();
    _loadInsights();
  }

  Future<void> _loadInsights() async {
    try {
      final snap = await _db.child("restaurants/${widget.restaurantId}/surveys").get();
      if (snap.exists) {
        final surveys = (snap.value as Map).cast<String, dynamic>();
        double totalCSAT = 0, totalCES = 0, totalNPS = 0;
        int countCSAT = 0, countCES = 0, countNPS = 0;
        List<Map<String, dynamic>> feedbackList = [];
        surveys.forEach((_, value) {
          final survey = Map<String, dynamic>.from(value);
          final type = survey['type'];
          final comment = survey['comment'] as String?;
          if (type == "CSAT") {
            totalCSAT += (survey['csat'] ?? 0).toDouble();
            countCSAT++;
          } else if (type == "CES") {
            totalCES += (survey['ces'] ?? 0).toDouble();
            countCES++;
          } else if (type == "NPS") {
            totalNPS += (survey['nps'] ?? 0).toDouble();
            countNPS++;
          }
          if (comment != null && comment.isNotEmpty) {
            feedbackList.add({
              'type': type,
              'comment': comment,
              'date': survey['date'],
            });
          }
        });
        setState(() {
          _avgCSAT = countCSAT > 0 ? totalCSAT / countCSAT : 0;
          _avgCES = countCES > 0 ? totalCES / countCES : 0;
          _avgNPS = countNPS > 0 ? totalNPS / countNPS : 0;
          _recentFeedback = feedbackList.reversed.take(5).toList();
          _loading = false;
        });
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.restaurantName),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => QrGeneratorPage(
                  restaurantId: widget.restaurantId,
                  restaurantName: widget.restaurantName,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Chart
                SizedBox(
                  height: 200,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: 10,
                          barGroups: [
                            BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: _avgCSAT, color: Colors.blue)]),
                            BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: _avgCES, color: Colors.green)]),
                            BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: _avgNPS, color: Colors.pink)]),
                          ],
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(sideTitles: SideTitles(getTitlesWidget: (v, _) {
                              switch (v.toInt()) {
                                case 0: return const Text("CSAT");
                                case 1: return const Text("CES");
                                case 2: return const Text("NPS");
                              }
                              return const Text("");
                            })),
                            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 2)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Feedback
                const Text("Recent Feedback", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                ..._recentFeedback.map((f) => Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    title: Text(f['comment'] ?? '', style: const TextStyle(fontStyle: FontStyle.italic)),
                    subtitle: Text("${f['type']} • ${f['date'] != null ? DateFormat('MMM dd').format(DateTime.parse(f['date'])) : ''}"),
                  ),
                )),
              ],
            ),
    );
  }
}