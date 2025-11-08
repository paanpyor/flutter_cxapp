import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class RestaurantDetailsPage extends StatefulWidget {
  final String restaurantId;
  const RestaurantDetailsPage({super.key, required this.restaurantId});

  @override
  State<RestaurantDetailsPage> createState() => _RestaurantDetailsPageState();
}

class _RestaurantDetailsPageState extends State<RestaurantDetailsPage> {
  final _db = FirebaseDatabase.instance.ref();
  Map<String, dynamic>? restaurantData;
  List<Map<String, dynamic>> feedbackList = [];

  double avgCSAT = 0.0;
  double avgCES = 0.0;
  double avgNPS = 0.0;
  double lat = 0.0;
  double lng = 0.0;

  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadRestaurantDetails();
  }

  Future<void> _loadRestaurantDetails() async {
    final snap =
        await _db.child("restaurants/${widget.restaurantId}").get();

    if (!snap.exists) {
      setState(() => loading = false);
      return;
    }

    final data = Map<String, dynamic>.from(snap.value as Map);
    restaurantData = data;

    final surveys = (data["surveys"] ?? {}) as Map<dynamic, dynamic>;
    feedbackList = surveys.entries.map((e) {
      final s = Map<String, dynamic>.from(e.value);
      return {
        "type": s["type"] ?? "Unknown",
        "feedback": s["feedback"] ?? "",
        "csat": s["csat"] ?? 0,
        "ces": s["ces"] ?? 0,
        "nps": s["nps"] ?? 0,
        "date": s["date"] ?? "",
      };
    }).toList();

    _calculateAverages();
    if (data["lat"] != null && data["lng"] != null) {
      lat = (data["lat"] as num).toDouble();
      lng = (data["lng"] as num).toDouble();
    }

    setState(() => loading = false);
  }

  void _calculateAverages() {
    double totalCSAT = 0, totalCES = 0, totalNPS = 0;
    int countCSAT = 0, countCES = 0, countNPS = 0;

    for (var s in feedbackList) {
      if (s["csat"] != null && s["csat"] > 0) {
        totalCSAT += double.tryParse(s["csat"].toString()) ?? 0;
        countCSAT++;
      }
      if (s["ces"] != null && s["ces"] > 0) {
        totalCES += double.tryParse(s["ces"].toString()) ?? 0;
        countCES++;
      }
      if (s["nps"] != null && s["nps"] > 0) {
        totalNPS += double.tryParse(s["nps"].toString()) ?? 0;
        countNPS++;
      }
    }

    avgCSAT = countCSAT > 0 ? totalCSAT / countCSAT : 0;
    avgCES = countCES > 0 ? totalCES / countCES : 0;
    avgNPS = countNPS > 0 ? totalNPS / countNPS : 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(restaurantData?["name"] ?? "Restaurant Details"),
        backgroundColor: Colors.indigo,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildAnalysisChart(),
                  const SizedBox(height: 20),
                  _buildMapSection(),
                  const SizedBox(height: 20),
                  _buildFeedbackSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.network(
              restaurantData?["imageUrl"] ??
                  "https://cdn-icons-png.flaticon.com/512/857/857681.png",
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          ListTile(
            title: Text(
              restaurantData?["name"] ?? "Unnamed Restaurant",
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 20),
            ),
            subtitle: Text(restaurantData?["location"] ?? "No location"),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisChart() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "Survey Analysis",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.indigo),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  maxY: 10,
                  barGroups: [
                    BarChartGroupData(
                        x: 0,
                        barRods: [
                          BarChartRodData(toY: avgCSAT, color: Colors.amber)
                        ]),
                    BarChartGroupData(
                        x: 1,
                        barRods: [
                          BarChartRodData(toY: avgCES, color: Colors.green)
                        ]),
                    BarChartGroupData(
                        x: 2,
                        barRods: [
                          BarChartRodData(toY: avgNPS, color: Colors.pink)
                        ]),
                  ],
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, _) {
                          switch (v.toInt()) {
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
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Overall CSAT: ${avgCSAT.toStringAsFixed(1)}  |  CES: ${avgCES.toStringAsFixed(1)}  |  NPS: ${avgNPS.toStringAsFixed(1)}",
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapSection() {
    return lat == 0.0 || lng == 0.0
        ? const Text("📍 Location not available",
            style: TextStyle(fontStyle: FontStyle.italic))
        : Card(
            elevation: 3,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: SizedBox(
              height: 220,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(lat, lng),
                    initialZoom: 15,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                      subdomains: const ['a', 'b', 'c'],
                    ),
                    MarkerLayer(markers: [
                      Marker(
                        point: LatLng(lat, lng),
                        width: 40,
                        height: 40,
                        child: const Icon(Icons.location_pin,
                            color: Colors.red, size: 40),
                      )
                    ])
                  ],
                ),
              ),
            ),
          );
  }

  Widget _buildFeedbackSection() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Recent Feedback",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.indigo),
            ),
            const SizedBox(height: 10),
            feedbackList.isEmpty
                ? const Text("No feedback yet.")
                : ListView.builder(
                    itemCount: feedbackList.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, i) {
                      final f = feedbackList[i];
                      return ListTile(
                        leading: Icon(
                          f["type"] == "CSAT"
                              ? Icons.star
                              : f["type"] == "CES"
                                  ? Icons.handshake
                                  : Icons.favorite,
                          color: f["type"] == "CSAT"
                              ? Colors.amber
                              : f["type"] == "CES"
                                  ? Colors.green
                                  : Colors.pink,
                        ),
                        title: Text(
                          f["feedback"].isEmpty
                              ? "(No comment)"
                              : f["feedback"],
                        ),
                        subtitle: Text(
                            "${f["type"]} Score: ${f["csat"] ?? f["ces"] ?? f["nps"]}"),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
