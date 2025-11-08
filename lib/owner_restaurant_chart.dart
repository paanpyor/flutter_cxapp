import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';

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
  double csat = 0, ces = 0, nps = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSurveyData();
  }

  Future<void> _loadSurveyData() async {
    final snap =
        await _db.child("restaurants/${widget.restaurantId}/surveys").get();

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
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.restaurantName),
        backgroundColor: Colors.indigo,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text("Survey Averages",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Expanded(
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: 10,
                        barGroups: [
                          BarChartGroupData(
                              x: 0,
                              barRods: [
                                BarChartRodData(
                                    toY: csat, color: Colors.blue)
                              ],
                              showingTooltipIndicators: [0]),
                          BarChartGroupData(
                              x: 1,
                              barRods: [
                                BarChartRodData(
                                    toY: ces, color: Colors.green)
                              ],
                              showingTooltipIndicators: [0]),
                          BarChartGroupData(
                              x: 2,
                              barRods: [
                                BarChartRodData(
                                    toY: nps, color: Colors.pink)
                              ],
                              showingTooltipIndicators: [0]),
                        ],
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles:
                                SideTitles(showTitles: true, interval: 2),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, _) {
                                switch (value.toInt()) {
                                  case 0:
                                    return const Text("CSAT");
                                  case 1:
                                    return const Text("CES");
                                  case 2:
                                    return const Text("NPS");
                                }
                                return const Text("");
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
