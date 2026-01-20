// lib/near_me_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'app_theme.dart';
import 'common_widget.dart'; // Import EmptyState

class NearMePage extends StatefulWidget {
  const NearMePage({super.key});

  @override
  State<NearMePage> createState() => _NearMePageState();
}

class _NearMePageState extends State<NearMePage> {
  bool _loading = true;
  String _errorMessage = ""; // Holds specific error messages
  Position? _currentPosition;
  List<Map<String, dynamic>> _nearbyRestaurants = [];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _loading = true;
      _errorMessage = "";
    });

    try {
      // 1. Check Service
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showError("Location services are disabled. Please enable GPS.");
        return;
      }

      // 2. Check Permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showError("Location permission denied.");
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showError("Location permissions are permanently denied. Please enable in settings.");
        return;
      }

      // 3. Get Position
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
            // Calculate Distance in Meters
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
              "imageUrl": map["imageUrl"] ?? "https://cdn-icons-png.flaticon.com/512/857/857681.png",
              "distance": distanceInMeters / 1000, // Store in Km
              "latitude": (lat).toDouble(),
              "longitude": (lng).toDouble(),
            });
          }
        }

        // Sort by distance (closest first)
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
    }
  }

  void _showError(String message) {
    if (mounted) {
      setState(() {
        _errorMessage = message;
        _loading = false;
      });
    }
  }

  String _formatDistance(double km) {
    if (km < 1) {
      return "${(km * 1000).toInt()} m";
    } else {
      return "${km.toStringAsFixed(1)} km";
    }
  }

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not open maps")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("Near Me"),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primary,
        elevation: 0,
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_off, size: 60, color: Colors.red),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(_errorMessage, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _getCurrentLocation,
                        icon: const Icon(Icons.refresh),
                        label: const Text("Retry"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                )
              : _nearbyRestaurants.isEmpty
                  ? const EmptyState(
                      message: "No restaurants found nearby.",
                      icon: Icons.storefront_outlined,
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _nearbyRestaurants.length,
                      itemBuilder: (context, index) {
                        final r = _nearbyRestaurants[index];
                        final distKm = r["distance"];
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                // Image
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    r["imageUrl"],
                                    width: 70,
                                    height: 70,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: Colors.grey[200],
                                      width: 70,
                                      height: 70,
                                      child: const Icon(Icons.restaurant, size: 30, color: Colors.grey),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                
                                // Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        r["name"],
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              r["location"],
                                              style: const TextStyle(color: Colors.grey, fontSize: 13),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Actions Column
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Distance Badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        _formatDistance(distKm),
                                        style: const TextStyle(
                                          color: AppTheme.primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    
                                    // Navigate Button
                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: _currentPosition == null ? null : () => _launchMapsDirections(
                                          _currentPosition!.latitude,
                                          _currentPosition!.longitude,
                                          r["latitude"],
                                          r["longitude"],
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                        child: const Padding(
                                          padding: EdgeInsets.all(8),
                                          child: Icon(Icons.directions, color: AppTheme.primary, size: 20),
                                        ),
                                      ),
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