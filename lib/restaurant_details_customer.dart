// lib/restaurant_details_customer.dart
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
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

  Widget _buildInfoCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.indigo)))
          : _restaurant == null
              ? const Scaffold(body: Center(child: Text("Restaurant not found")))
              : CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      expandedHeight: 250,
                      pinned: true,
                      flexibleSpace: FlexibleSpaceBar(
                        title: Text(_restaurant!["name"], style: const TextStyle(color: Colors.white, shadows: [Shadow(color: Colors.black45, blurRadius: 10)])),
                        background: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              _restaurant!["imageUrl"],
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(color: Colors.grey[300]),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.location_on, color: Colors.indigo),
                                const SizedBox(width: 8),
                                Text(_restaurant!["location"] ?? "Unknown Location", style: const TextStyle(fontSize: 16, color: Colors.grey)),
                              ],
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SurveyTypePage(restaurantId: widget.restaurantId))),
                                icon: const Icon(Icons.assignment_outlined, color: Colors.white),
                                label: const Text("Start Survey", style: TextStyle(fontSize: 18, color: Colors.white)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.indigo,
                                  padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            const Text("Insights", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(child: _buildInfoCard("NPS", _avgNPS.toStringAsFixed(1), Colors.blue)),
                                const SizedBox(width: 12),
                                Expanded(child: _buildInfoCard("CSAT", _avgCSAT.toStringAsFixed(1), Colors.orange)),
                                const SizedBox(width: 12),
                                Expanded(child: _buildInfoCard("CES", _avgCES.toStringAsFixed(1), Colors.green)),
                              ],
                            ),
                            const SizedBox(height: 32),
                            if (_restaurantLocation != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: SizedBox(
                                  height: 200,
                                  child: FlutterMap(
                                    options: MapOptions(initialCenter: _restaurantLocation!, initialZoom: 15),
                                    children: [
                                      TileLayer(urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png"),
                                      MarkerLayer(
                                        markers: [
                                          Marker(point: _restaurantLocation!, child: const Icon(Icons.location_on, color: Colors.red, size: 40)),
                                          if (_currentLocation != null)
                                            Marker(point: _currentLocation!, child: const Icon(Icons.my_location, color: Colors.blue, size: 30)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            const SizedBox(height: 50),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}