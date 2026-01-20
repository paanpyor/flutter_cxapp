// lib/restaurant_insights_page_owner.dart
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'app_theme.dart';
import 'common_widget.dart'; // Import AppCard, EmptyState

class RestaurantInsightsPageOwner extends StatefulWidget {
  final String restaurantId;
  final String restaurantName;
  
  const RestaurantInsightsPageOwner({
    super.key, 
    required this.restaurantId, 
    required this.restaurantName
  });

  @override
  State<RestaurantInsightsPageOwner> createState() => _RestaurantInsightsPageOwnerState();
}

class _RestaurantInsightsPageOwnerState extends State<RestaurantInsightsPageOwner> {
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
          
          // Calculate Averages
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

          // Gather Feedback
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
          _recentFeedback = feedbackList.reversed.take(10).toList();
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      debugPrint("Error loading insights: $e");
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("Insights"),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primary,
        elevation: 0,
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Chart Section
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Survey Performance", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text("Last 30 Days", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 200,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: 10,
                              barGroups: [
                                BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: _avgCSAT, color: Colors.orange, width: 24, borderRadius: BorderRadius.circular(6))]),
                                BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: _avgCES, color: Colors.green, width: 24, borderRadius: BorderRadius.circular(6))]),
                                BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: _avgNPS, color: AppTheme.primary, width: 24, borderRadius: BorderRadius.circular(6))]),
                              ],
                              titlesData: FlTitlesData(
                                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v,_) {
                                  return Padding(padding: const EdgeInsets.only(top: 8), child: Text(getLabel(v.toInt()), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)));
                                })),
                              ),
                              borderData: FlBorderData(show: false),
                              gridData: FlGridData(show: false),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),

                  // Feedback Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Recent Customer Feedback", style: Theme.of(context).textTheme.headlineMedium),
                      Text("Last 10", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    ],
                  ),
                  
                  const SizedBox(height: 16),

                  // Feedback List
                  _recentFeedback.isEmpty
                      ? const EmptyState(message: "No feedback available yet.", icon: Icons.rate_review)
                      : Column(
                          children: _recentFeedback.map((f) => _buildFeedbackTile(f)).toList(),
                        ),
                ],
              ),
            ),
    );
  }

  Widget _buildFeedbackTile(Map<String, dynamic> f) {
    Color typeColor = Colors.grey;
    if (f['type'] == "NPS") typeColor = AppTheme.primary;
    if (f['type'] == "CSAT") typeColor = Colors.orange;
    if (f['type'] == "CES") typeColor = Colors.green;

    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar/Type Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: typeColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.comment, color: typeColor, size: 20),
          ),
          const SizedBox(width: 12),
          
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: typeColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(f['type'], style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                    Text(f['date'] != null ? f['date'].toString().split('T').first : "", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(f['comment'] ?? "", style: const TextStyle(fontSize: 14, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String getLabel(int index) {
    switch (index) {
      case 0: return "CSAT";
      case 1: return "CES";
      case 2: return "NPS";
      default: return "";
    }
  }
}