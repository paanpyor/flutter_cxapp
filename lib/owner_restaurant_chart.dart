// lib/owner_restaurant_chart.dart
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'app_theme.dart';
import 'common_widget.dart';
 // Import for AppCard & EmptyState

class OwnerRestaurantChart extends StatefulWidget {
  final String restaurantId;
  final String restaurantName;

  const OwnerRestaurantChart({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
  });

  @override
  State<OwnerRestaurantChart> createState() => _OwnerRestaurantChartState();
}

class _OwnerRestaurantChartState extends State<OwnerRestaurantChart> {
  final _db = FirebaseDatabase.instance.ref();
  
  // Metrics
  double csat = 0, ces = 0, nps = 0;
  
  // UI State
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSurveyData();
  }

  Future<void> _loadSurveyData() async {
    final snap = await _db.child("restaurants/${widget.restaurantId}/surveys").get();

    if (snap.exists) {
      final data = (snap.value as Map).cast<String, dynamic>();
      double totalCSAT = 0, totalCES = 0, totalNPS = 0;
      int countCSAT = 0, countCES = 0, countNPS = 0;

      for (var e in data.values) {
        final m = Map<String, dynamic>.from(e);
        if (m["type"] == "CSAT") {
          totalCSAT += (m["csat"] ?? 0).toDouble();
          countCSAT++;
        } else if (m["type"] == "CES") {
          totalCES += (m["ces"] ?? 0).toDouble();
          countCES++;
        } else if (m["type"] == "NPS") {
          totalNPS += (m["nps"] ?? 0).toDouble();
          countNPS++;
        }
      }

      setState(() {
        csat = countCSAT > 0 ? totalCSAT / countCSAT : 0;
        ces = countCES > 0 ? totalCES / countCES : 0;
        nps = countNPS > 0 ? totalNPS / countNPS : 0;
        _loading = false;
      });
    } else {
      // No surveys yet
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("Performance Analytics"),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primary,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info
            Text(
              widget.restaurantName,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Survey Averages (Last 30 Days)",
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // Chart Card
            AppCard(
              child: _loading 
                  ? const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()))
                  : (csat == 0 && ces == 0 && nps == 0)
                      ? const SizedBox(
                          height: 200,
                          child: EmptyState(
                            message: "No survey data available yet.",
                            icon: Icons.bar_chart,
                          ),
                        )
                      : SizedBox(
                          height: 300, // Height for the chart
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: 10, // Scale is 0-10
                              minY: 0,
                              groupsSpace: 20,
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                horizontalInterval: 2,
                                getDrawingHorizontalLine: (value) {
                                  return const FlLine(
                                    color: Colors.grey,
                                    strokeWidth: 0.5,
                                  );
                                },
                              ),
                              titlesData: FlTitlesData(
                                show: true,
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    interval: 2,
                                    reservedSize: 40,
                                    getTitlesWidget: (value, meta) {
                                      return Text(
                                        value.toInt().toString(),
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      );
                                    },
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 10),
                                        child: Text(
                                          getBarTitle(value.toInt()),
                                          style: const TextStyle(
                                            fontSize: 12, 
                                            fontWeight: FontWeight.bold, 
                                            color: Colors.black87
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              borderData: FlBorderData(
                                show: false,
                              ),
                              barGroups: [
                                // CSAT Bar
                                BarChartGroupData(
                                  x: 0,
                                  barRods: [
                                    BarChartRodData(
                                      toY: csat,
                                      color: Colors.orange,
                                      width: 20,
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(6),
                                        topRight: Radius.circular(6),
                                      ),
                                    ),
                                  ],
                                  showingTooltipIndicators: csat > 0 ? [0] : [],
                                ),
                                // CES Bar
                                BarChartGroupData(
                                  x: 1,
                                  barRods: [
                                    BarChartRodData(
                                      toY: ces,
                                      color: Colors.green,
                                      width: 20,
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(6),
                                        topRight: Radius.circular(6),
                                      ),
                                    ),
                                  ],
                                  showingTooltipIndicators: ces > 0 ? [0] : [],
                                ),
                                // NPS Bar
                                BarChartGroupData(
                                  x: 2,
                                  barRods: [
                                    BarChartRodData(
                                      toY: nps,
                                      color: AppTheme.primary,
                                      width: 20,
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(6),
                                        topRight: Radius.circular(6),
                                      ),
                                    ),
                                  ],
                                  showingTooltipIndicators: nps > 0 ? [0] : [],
                                ),
                              ],
                            ),
                          ),
                        ),
            ),
            const SizedBox(height: 20),

            // Simple Metric Summaries below chart
            if (!_loading && (csat > 0 || ces > 0 || nps > 0)) ...[
              Row(
                children: [
                  Expanded(child: _buildMiniMetric("CSAT", csat, Colors.orange)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildMiniMetric("CES", ces, Colors.green)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildMiniMetric("NPS", nps, AppTheme.primary)),
                ],
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildMiniMetric(String label, double value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(value.toStringAsFixed(1), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  String getBarTitle(int index) {
    switch (index) {
      case 0: return "CSAT";
      case 1: return "CES";
      case 2: return "NPS";
      default: return "";
    }
  }
}