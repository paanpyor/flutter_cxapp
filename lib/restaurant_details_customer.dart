import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_cxapp/survey_type_page.dart';

class RestaurantDetailsCustomerPage extends StatefulWidget {
  final String restaurantId;

  const RestaurantDetailsCustomerPage({super.key, required this.restaurantId});

  @override
  State<RestaurantDetailsCustomerPage> createState() =>
      _RestaurantDetailsCustomerPageState();
}

class _RestaurantDetailsCustomerPageState
    extends State<RestaurantDetailsCustomerPage> {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  Map<String, dynamic>? _restaurant;
  bool _loading = true;

  double _avgCSAT = 0.0;
  double _avgCES = 0.0;
  double _avgNPS = 0.0;

  LatLng? _restaurantLocation;
  LatLng? _currentLocation;

  List<Map<String, dynamic>> _feedbackList = [];
  final _feedbackController = TextEditingController();

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
      setState(() => _currentLocation = LatLng(pos.latitude, pos.longitude));
    }
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

  Future<void> _submitFeedback() async {
    final comment = _feedbackController.text.trim();
    if (comment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please write a feedback first.")),
      );
      return;
    }

    final feedbackRef = _db
        .child("restaurants/${widget.restaurantId}/feedback")
        .push();

    await feedbackRef.set({
      "user": "Customer",
      "comment": comment,
      "date": DateTime.now().toIso8601String(),
    });

    _feedbackController.clear();
    await _loadFeedback();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ Feedback submitted!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff8f9fa),
      appBar: AppBar(
        title: const Text("Restaurant Details"),
        backgroundColor: Colors.indigo,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _restaurant == null
              ? const Center(child: Text("Restaurant not found"))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: _restaurant!["imageUrl"] != null &&
                                _restaurant!["imageUrl"].toString().startsWith("http")
                            ? Image.network(_restaurant!["imageUrl"],
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover)
                            : Image.asset("assets/default_restaurant.jpg",
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _restaurant!["name"] ?? "Unnamed Restaurant",
                        style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.location_on,
                              color: Colors.grey, size: 18),
                          const SizedBox(width: 6),
                          Text(_restaurant!["location"] ?? "Unknown",
                              style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildChartSection(),
                      const SizedBox(height: 20),
                      _buildMapSection(),
                      const SizedBox(height: 25),
                      _buildFeedbackSection(),
                      const SizedBox(height: 25),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SurveyTypePage(
                                  restaurantId: widget.restaurantId),
                            ),
                          );
                        },
                        icon: const Icon(Icons.assignment_outlined),
                        label: const Text("Start Survey",
                            style: TextStyle(fontSize: 18)),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 36, vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30))),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildChartSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text("Customer Satisfaction Overview",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo)),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 10,
                  barGroups: [
                    BarChartGroupData(x: 0, barRods: [
                      BarChartRodData(toY: _avgCSAT, color: Colors.indigo)
                    ]),
                    BarChartGroupData(x: 1, barRods: [
                      BarChartRodData(toY: _avgCES, color: Colors.green)
                    ]),
                    BarChartGroupData(x: 2, barRods: [
                      BarChartRodData(toY: _avgNPS, color: Colors.pink)
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
                  ),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        height: 300,
        width: double.infinity,
        child: _restaurantLocation == null
            ? const Center(child: Text("No location data."))
            : ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: _restaurantLocation!,
                    initialZoom: 15,
                  ),
                  children: [
                    TileLayer(
                        urlTemplate:
                            "https://tile.openstreetmap.org/{z}/{x}/{y}.png"),
                    MarkerLayer(markers: [
                      Marker(
                        point: _restaurantLocation!,
                        width: 80,
                        height: 80,
                        child: const Icon(Icons.location_on,
                            color: Colors.red, size: 40),
                      ),
                      if (_currentLocation != null)
                        Marker(
                          point: _currentLocation!,
                          width: 80,
                          height: 80,
                          child: const Icon(Icons.my_location,
                              color: Colors.blue, size: 30),
                        ),
                    ]),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildFeedbackSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Customer Feedback",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo)),
            const SizedBox(height: 10),
            TextField(
              controller: _feedbackController,
              decoration: InputDecoration(
                hintText: "Write your feedback...",
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send, color: Colors.indigo),
                  onPressed: _submitFeedback,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 10),
            _feedbackList.isEmpty
                ? const Center(
                    child: Text("No feedback yet.",
                        style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _feedbackList.length,
                    itemBuilder: (context, i) {
                      final f = _feedbackList[i];
                      return ListTile(
                        leading: const CircleAvatar(
                            backgroundColor: Colors.indigo,
                            child:
                                Icon(Icons.person, color: Colors.white)),
                        title: Text(f["user"]),
                        subtitle: Text(f["comment"]),
                        trailing: Text(
                          f["date"].toString().split('T').first,
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
