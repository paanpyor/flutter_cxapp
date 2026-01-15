// lib/restaurant_details_owner.dart
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_cxapp/report_generator.dart'; // ← Required for PDF
import 'package:printing/printing.dart'; // ← Required for sharing
import 'dart:io'; // ← Required for file handling

class RestaurantDetailsOwnerPage extends StatefulWidget {
  final String restaurantId;
  const RestaurantDetailsOwnerPage({super.key, required this.restaurantId});

  @override
  State<RestaurantDetailsOwnerPage> createState() =>
      _RestaurantDetailsOwnerPageState();
}

class _RestaurantDetailsOwnerPageState
    extends State<RestaurantDetailsOwnerPage> {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  Map<String, dynamic>? _restaurant;
  bool _loading = true;
  double _avgCSAT = 0.0;
  double _avgCES = 0.0;
  double _avgNPS = 0.0;
  List<Map<String, dynamic>> _feedbackList = [];
  LatLng? _restaurantLocation;
  LatLng? _currentLocation;
  double? _distanceKm;

  @override
  void initState() {
    super.initState();
    _loadRestaurantDetails();
    _getCurrentLocation();
  }

  Future<void> _loadRestaurantDetails() async {
    final snap = await _db.child("restaurants/${widget.restaurantId}").get();
    if (snap.exists && snap.value is Map) {
      final data = Map<String, dynamic>.from(snap.value as Map);
      if (mounted) setState(() => _restaurant = data);
      if (data["latitude"] != null && data["longitude"] != null) {
        _restaurantLocation = LatLng(
          (data["latitude"] as num).toDouble(),
          (data["longitude"] as num).toDouble(),
        );
      }
      await _calculateAverages();
      await _loadFeedback();
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;
    final pos = await Geolocator.getCurrentPosition();
    if (mounted) {
      setState(() {
        _currentLocation = LatLng(pos.latitude, pos.longitude);
        _calculateDistance();
      });
    }
  }

  void _calculateDistance() {
    if (_restaurantLocation == null || _currentLocation == null) return;
    final distance = Geolocator.distanceBetween(
      _currentLocation!.latitude,
      _currentLocation!.longitude,
      _restaurantLocation!.latitude,
      _restaurantLocation!.longitude,
    );
    setState(() => _distanceKm = distance / 1000);
  }

  Future<void> _calculateAverages() async {
    final surveysSnap =
        await _db.child("restaurants/${widget.restaurantId}/surveys").get();
    if (!surveysSnap.exists) return;
    final surveys = (surveysSnap.value as Map).cast<String, dynamic>();
    double totalCSAT = 0, totalCES = 0, totalNPS = 0;
    int count = 0;
    for (final entry in surveys.entries) {
      final survey = Map<String, dynamic>.from(entry.value);
      totalCSAT += _toDouble(survey["csat"]);
      totalCES += _toDouble(survey["ces"]);
      totalNPS += _toDouble(survey["nps"]);
      count++;
    }
    if (count > 0) {
      _avgCSAT = totalCSAT / count;
      _avgCES = totalCES / count;
      _avgNPS = totalNPS / count;
    } else {
      _avgCSAT = _avgCES = _avgNPS = 0.0;
    }
    if (mounted) setState(() {});
  }

  double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  Future<void> _loadFeedback() async {
    final snap =
        await _db.child("restaurants/${widget.restaurantId}/feedback").get();
    if (!snap.exists) return;
    final data = (snap.value as Map).cast<String, dynamic>();
    final feedbacks = data.entries.map((e) {
      final val = Map<String, dynamic>.from(e.value);
      return {
        "user": val["user"] ?? "Anonymous",
        "comment": val["comment"] ?? "",
        "date": val["date"] ?? "",
      };
    }).toList();
    feedbacks.sort((a, b) => (b["date"] ?? "").compareTo(a["date"] ?? ""));
    if (mounted) setState(() => _feedbackList = feedbacks);
  }

  String _generateAnalysis() {
  final StringBuffer analysis = StringBuffer();

  // ===== NPS ANALYSIS (STRONGEST INDICATOR OF LOYALTY) =====
  analysis.writeln("🎯 Net Promoter Score (NPS) Insights");
  if (_avgNPS < 0) {
    analysis.writeln("Your NPS is negative (-${(-_avgNPS).toStringAsFixed(1)}), which means you have more Detractors than Promoters.");
    analysis.writeln("➡️ Priority Action: Identify unhappy customers immediately.");
    analysis.writeln("   • Contact recent detractors for 1:1 feedback.");
    analysis.writeln("   • Train staff on service recovery protocols.");
    analysis.writeln("   • Add a comment box in your survey asking 'What disappointed you?'");
  } else if (_avgNPS >= 0 && _avgNPS < 50) {
    analysis.writeln("Your NPS (${_avgNPS.toStringAsFixed(1)}) is average. Many customers are satisfied but not enthusiastic enough to refer you.");
    analysis.writeln("➡️ Priority Action: Turn 'Passive' customers into 'Promoters'.");
    analysis.writeln("   • Offer a referral discount: 'Refer a friend, get 10% off next visit'");
    analysis.writeln("   • Surprise loyal customers with a free dessert or drink.");
    analysis.writeln("   • Share positive reviews on your social media to build social proof.");
  } else {
    analysis.writeln("🎉 Excellent! Your NPS (${_avgNPS.toStringAsFixed(1)}) is strong — customers are likely to refer you!");
    analysis.writeln("➡️ Priority Action: Leverage your promoters.");
    analysis.writeln("   • Ask happy customers to leave Google/Facebook reviews.");
    analysis.writeln("   • Feature testimonials on your menu or website.");
    analysis.writeln("   • Create a 'VIP Loyalty Program' to reward repeat visits.");
  }
  analysis.writeln("");

  // ===== CSAT ANALYSIS (OVERALL SATISFACTION) =====
  analysis.writeln("😊 Customer Satisfaction (CSAT) Insights");
  if (_avgCSAT < 5) {
    analysis.writeln("Your CSAT (${_avgCSAT.toStringAsFixed(1)}/10) indicates significant dissatisfaction.");
    analysis.writeln("➡️ Priority Action: Audit your core experience.");
    analysis.writeln("   • Food: Check ingredient freshness, portion sizes, and consistency.");
    analysis.writeln("   • Service: Mystery shop your staff — are they attentive & polite?");
    analysis.writeln("   • Ambiance: Ensure tables are clean, music isn't too loud, AC works.");
  } else if (_avgCSAT >= 5 && _avgCSAT < 8) {
    analysis.writeln("Your CSAT (${_avgCSAT.toStringAsFixed(1)}/10) shows room for improvement – customers are 'okay' but not wowed.");
    analysis.writeln("➡️ Priority Action: Add 'WOW' moments.");
    analysis.writeln("   • Train staff to greet by name (use order tags).");
    analysis.writeln("   • Offer complimentary water with lemon/mint.");
    analysis.writeln("   • Send a post-visit SMS: 'How was your meal? Reply with feedback!'");
  } else {
    analysis.writeln("🌟  Outstanding! Your CSAT (${_avgCSAT.toStringAsFixed(1)}/10) shows customers are very satisfied.");
    analysis.writeln("➡️  Priority Action : Protect this quality.");
    analysis.writeln("   • Document your service standards and retrain monthly.");
    analysis.writeln("   • Monitor for any dip in scores — act fast if it drops.");
    analysis.writeln("   • Celebrate your team’s success publicly.");
  }
  analysis.writeln("");

  // ===== CES ANALYSIS (EFFORT = FRICTION) =====
  analysis.writeln("⚡ Customer Effort Score (CES) Insights");
  if (_avgCES > 7) {
    analysis.writeln("Your CES (**${_avgCES.toStringAsFixed(1)}/10) is high — customers find it too hard to interact with you.");
    analysis.writeln("➡️ **Priority Action**: Remove friction points.");
    analysis.writeln("   • **Online**: Simplify your website ordering flow (max 3 steps).");
    analysis.writeln("   • **In-store**: Add table QR codes for digital menus & quick feedback.");
    analysis.writeln("   • **Staff**: Empower them to resolve issues without manager approval.");
  } else if (_avgCES >= 5 && _avgCES <= 7) {
    analysis.writeln("Your CES (**${_avgCES.toStringAsFixed(1)}/10) is moderate — some processes are smooth, others aren’t.");
    analysis.writeln("➡️ Priority Action: Streamline 1 key process.");
    analysis.writeln("   • If ordering is slow → add more POS terminals.");
    analysis.writeln("   • If payment is confusing → accept e-wallets (Touch 'n Go, etc.).");
    analysis.writeln("   • If wait time is long → implement table reservation system.");
  } else {
    analysis.writeln("✅  Excellent!  Your CES (**${_avgCES.toStringAsFixed(1)}/10) is low — customers find it easy to do business with you.");
    analysis.writeln("➡️  Priority Action : Maintain & promote this ease.");
    analysis.writeln("   • Add a tagline: 'Quick, Easy, Delicious!'");
    analysis.writeln("   • Highlight fast service in your Google Business profile.");
    analysis.writeln("   • Keep your app/website updated and intuitive.");
  }
  analysis.writeln("");

  // ===== STRATEGIC SUMMARY =====
  analysis.writeln("📌 Your 30-Day Improvement Plan:");
  int priorityCount = 0;

  if (_avgNPS < 50) {
    priorityCount++;
    analysis.writeln("$priorityCount. Focus on customer recovery & referral program(NPS).");
  }
  if (_avgCSAT < 8) {
    priorityCount++;
    analysis.writeln("$priorityCount. Improve food quality & staff friendliness (CSAT).");
  }
  if (_avgCES > 6) {
    priorityCount++;
    analysis.writeln("$priorityCount. Reduce friction in ordering/payment(CES).");
  }

  if (priorityCount == 0) {
    analysis.writeln("• Maintain excellence! Focus on scaling your success.");
  }

  return analysis.toString();
}

  // ✅ NEW: Generate and download PDF Report
  Future<void> _generateAndDownloadReport() async {
    if (_avgNPS == 0 && _avgCSAT == 0 && _avgCES == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No survey data to generate report.")),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final report = RestaurantReputationReport(
        restaurantName: _restaurant!["name"] ?? "Unnamed Restaurant",
        location: _restaurant!["location"] ?? "Unknown",
        avgNPS: _avgNPS,
        avgCSAT: _avgCSAT,
        avgCES: _avgCES,
        analysis: _generateAnalysis(),
        feedbackList: _feedbackList,
      );

      final file = await report.generatePdf();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✅ Report saved!'),
          action: SnackBarAction(
            label: 'Open',
            onPressed: () async {
              await Printing.sharePdf(
                bytes: await file.readAsBytes(),
                filename: file.path.split('/').last,
              );
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed to generate report: $e")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff8f9fa),
      appBar: AppBar(
        title: const Text("Restaurant Insights"),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
            onPressed: _generateAndDownloadReport,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.indigo))
          : _restaurant == null
              ? const Center(child: Text("Restaurant not found"))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hero Image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.network(
                          _restaurant!["imageUrl"] ??
                              "https://cdn-icons-png.flaticon.com/512/857/857681.png",
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.image, size: 40, color: Colors.grey),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Restaurant Name & Location
                      Text(
                        _restaurant!["name"] ?? "Unnamed Restaurant",
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.grey, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            _restaurant!["location"] ?? "Unknown Location",
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                      if (_distanceKm != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          "📍 Distance from you: ${_distanceKm!.toStringAsFixed(2)} km",
                          style: const TextStyle(color: Colors.indigo, fontSize: 14),
                        ),
                      ],
                      const SizedBox(height: 24),

                      // Chart
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: SizedBox(
                            height: 180,
                            child: BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                maxY: 10,
                                barGroups: [
                                  BarChartGroupData(
                                    x: 0,
                                    barRods: [BarChartRodData(toY: _avgCSAT, color: Colors.indigo)],
                                  ),
                                  BarChartGroupData(
                                    x: 1,
                                    barRods: [BarChartRodData(toY: _avgCES, color: Colors.green)],
                                  ),
                                  BarChartGroupData(
                                    x: 2,
                                    barRods: [BarChartRodData(toY: _avgNPS, color: Colors.pink)],
                                  ),
                                ],
                                titlesData: FlTitlesData(
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (v, _) {
                                        switch (v.toInt()) {
                                          case 0: return const Text("CSAT");
                                          case 1: return const Text("CES");
                                          case 2: return const Text("NPS");
                                        }
                                        return const Text("");
                                      },
                                    ),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: true, interval: 2),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // AI Analysis
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "📊 AI-Powered Insights",
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo),
                              ),
                              const SizedBox(height: 10),
                              Text(_generateAnalysis(), style: const TextStyle(fontSize: 15)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Feedback List
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "💬 Recent Feedback",
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo),
                              ),
                              const SizedBox(height: 8),
                              _feedbackList.isEmpty
                                  ? const Text("No feedback yet.", style: TextStyle(color: Colors.grey))
                                  : ListView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: _feedbackList.length,
                                      itemBuilder: (context, i) {
                                        final f = _feedbackList[i];
                                        return ListTile(
                                          leading: const CircleAvatar(
                                            backgroundColor: Colors.indigo,
                                            child: Icon(Icons.person, color: Colors.white),
                                          ),
                                          title: Text(f["user"]),
                                          subtitle: Text(f["comment"]),
                                          trailing: Text(
                                            f["date"].toString().split('T').first,
                                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                                          ),
                                        );
                                      },
                                    ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Map
                      if (_restaurantLocation != null)
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: SizedBox(
                            height: 300,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: FlutterMap(
                                options: MapOptions(initialCenter: _restaurantLocation!, initialZoom: 15),
                                children: [
                                  TileLayer(urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png"),
                                  MarkerLayer(
                                    markers: [
                                      Marker(
                                        point: _restaurantLocation!,
                                        child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                                      ),
                                      if (_currentLocation != null)
                                        Marker(
                                          point: _currentLocation!,
                                          child: const Icon(Icons.my_location, color: Colors.blue, size: 30),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
    );
  }
}