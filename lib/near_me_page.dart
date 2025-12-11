// lib/near_me_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_cxapp/restaurant_details_customer.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_cxapp/restaurant_details_page.dart';
import 'package:url_launcher/url_launcher.dart'; // ✅ Added

class NearMePage extends StatefulWidget {
  const NearMePage({super.key});

  @override
  State<NearMePage> createState() => _NearMePageState();
}

class _NearMePageState extends State<NearMePage> {
  bool _loading = true;
  Position? _currentPosition;
  List<Map<String, dynamic>> _nearbyRestaurants = [];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showError("Please enable Location Services.");
      setState(() => _loading = false);
      return;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showError("Location permission denied.");
        setState(() => _loading = false);
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      _showError("Please enable location in app settings.");
      setState(() => _loading = false);
      return;
    }
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
        await _loadNearbyRestaurants(position);
      }
    } catch (e) {
      _showError("Failed to get location: $e");
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadNearbyRestaurants(Position userPos) async {
    try {
      final snap = await FirebaseDatabase.instance.ref().child("restaurants").get();
      if (snap.exists) {
        final data = (snap.value as Map).cast<String, dynamic>();
        final List<Map<String, dynamic>> restaurants = [];
        final entries = data.entries;
        for (var entry in entries) {
          final map = Map<String, dynamic>.from(entry.value);
          final lat = map["latitude"];
          final lng = map["longitude"];
          if (lat != null && lng != null) {
            double distanceInMeters = Geolocator.distanceBetween(
              userPos.latitude,
              userPos.longitude,
              (lat as num).toDouble(),
              (lng as num).toDouble(),
            );
            restaurants.add({
              "id": entry.key,
              "name": map["name"] ?? "Unnamed Restaurant",
              "location": map["location"] ?? "Unknown",
              "imageUrl": map["imageUrl"] ??
                  "https://cdn-icons-png.flaticon.com/512/857/857681.png",
              "distance": distanceInMeters / 1000, // in kilometers
              "latitude": (lat).toDouble(), // ✅ Store latitude
              "longitude": (lng).toDouble(), // ✅ Store longitude
            });
          }
        }
        restaurants.sort((a, b) => a["distance"].compareTo(b["distance"]));
        if (mounted) {
          setState(() {
            _nearbyRestaurants = restaurants;
            _loading = false;
          });
        }
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (e) {
      _showError("Error loading restaurants: $e");
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  String _formatDistance(double km) {
    if (km < 1) {
      return "${(km * 1000).toInt()} m";
    } else {
      return "${km.toStringAsFixed(1)} km";
    }
  }

  // ✅ Added: Launch Maps with Directions
  Future<void> _launchMapsDirections(
    double userLat,
    double userLng,
    double destLat,
    double destLng,
  ) async {
    final googleMapsUrl =
        'https://www.google.com/maps/dir/?api=1&origin=$userLat,$userLng&destination=$destLat,$destLng&travelmode=driving';

    if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
      await launchUrl(
        Uri.parse(googleMapsUrl),
        mode: LaunchMode.externalApplication,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open maps")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Near Me"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.indigo))
          : _currentPosition == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_off, size: 60, color: Colors.grey),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _getCurrentLocation,
                        child: const Text("Retry Location"),
                      ),
                    ],
                  ),
                )
              : _nearbyRestaurants.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.storefront, size: 60, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            "No restaurants nearby",
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _nearbyRestaurants.length,
                      itemBuilder: (context, index) {
                        final r = _nearbyRestaurants[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    r["imageUrl"],
                                    width: 70,
                                    height: 70,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        Container(
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.restaurant, size: 30),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        r["name"],
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "${r["location"]} • ${_formatDistance(r["distance"])}",
                                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // ✅ Navigate Button
                                    ElevatedButton.icon(
                                      onPressed: () => _launchMapsDirections(
                                        _currentPosition!.latitude,
                                        _currentPosition!.longitude,
                                        r["latitude"],
                                        r["longitude"],
                                      ),
                                      icon: const Icon(Icons.directions, size: 16),
                                      label: const Text("Navigate", style: TextStyle(fontSize: 12)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.indigo,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    // View Details Button
                                    TextButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => RestaurantDetailsCustomerPage(restaurantId: r["id"]),
                                          ),
                                        );
                                      },
                                      child: const Text("View Details", style: TextStyle(fontSize: 12)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}