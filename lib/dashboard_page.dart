import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_cxapp/login_page.dart';
import 'package:flutter_cxapp/restaurant_details_customer.dart';
import 'package:flutter_cxapp/restaurant_details_page.dart';
import 'package:flutter_cxapp/profile_page_customer.dart'; // ✅ Added import

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _loading = true;
  List<Map<String, dynamic>> _restaurants = [];
  List<Map<String, dynamic>> _filteredRestaurants = [];
  List<String> _uniqueLocations = [];
  final TextEditingController _searchController = TextEditingController();

  String _selectedSort = "A–Z";
  String _selectedLocation = "All";

  @override
  void initState() {
    super.initState();
    _loadRestaurants();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRestaurants() async {
    final snap = await _db.child("restaurants").get();

    if (snap.exists) {
      final data = (snap.value as Map).cast<String, dynamic>();
      final list = data.entries.map((e) {
        final map = Map<String, dynamic>.from(e.value);
        return {
          "id": e.key,
          "name": map["name"] ?? "Unnamed",
          "location": map["location"] ?? "Unknown",
          "imageUrl": map["imageUrl"] ??
              "https://cdn-icons-png.flaticon.com/512/857/857681.png",
        };
      }).toList();

      final locations = list
          .map((r) => r["location"] as String)
          .toSet()
          .toList()
        ..sort();

      setState(() {
        _restaurants = list;
        _filteredRestaurants = list;
        _uniqueLocations = ["All", ...locations];
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  void _onSearchChanged() => _applyFilters();

  void _applyFilters() {
    String query = _searchController.text.toLowerCase();
    String selectedLocation = _selectedLocation;

    List<Map<String, dynamic>> result = _restaurants.where((r) {
      final name = r["name"].toString().toLowerCase();
      final location = r["location"].toString().toLowerCase();
      bool matchesQuery = name.contains(query) || location.contains(query);
      bool matchesLocation =
          selectedLocation == "All" || r["location"] == selectedLocation;
      return matchesQuery && matchesLocation;
    }).toList();

    if (_selectedSort == "A–Z") {
      result.sort((a, b) => a["name"].compareTo(b["name"]));
    } else if (_selectedSort == "Z–A") {
      result.sort((a, b) => b["name"].compareTo(a["name"]));
    } else if (_selectedSort == "Location") {
      result.sort((a, b) => a["location"].compareTo(b["location"]));
    }

    setState(() => _filteredRestaurants = result);
  }

  Future<void> _logout() async {
    await _auth.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff8f9fa),
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        title: const Text("Explore Restaurants"),
        leading: IconButton( // ✅ Added profile icon
          icon: const Icon(Icons.person),
          tooltip: "Profile",
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfilePageCustomer()),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Logout",
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        children: [
          // 🔍 Search & filter
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Search by name or location...",
                    prefixIcon: const Icon(Icons.search, color: Colors.indigo),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide:
                          const BorderSide(color: Colors.indigo, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide:
                          const BorderSide(color: Colors.indigo, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedLocation,
                        decoration: InputDecoration(
                          labelText: "Filter by Location",
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: _uniqueLocations
                            .map((loc) => DropdownMenuItem(
                                  value: loc,
                                  child: Text(loc),
                                ))
                            .toList(),
                        onChanged: (val) {
                          setState(() => _selectedLocation = val!);
                          _applyFilters();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedSort,
                        decoration: InputDecoration(
                          labelText: "Sort By",
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: "A–Z", child: Text("Name A–Z")),
                          DropdownMenuItem(value: "Z–A", child: Text("Name Z–A")),
                          DropdownMenuItem(
                              value: "Location", child: Text("By Location")),
                        ],
                        onChanged: (val) {
                          setState(() => _selectedSort = val!);
                          _applyFilters();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 📋 Restaurant list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filteredRestaurants.isEmpty
                    ? const Center(
                        child: Text(
                          "No restaurants found.",
                          style:
                              TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _filteredRestaurants.length,
                        itemBuilder: (context, index) {
                          final r = _filteredRestaurants[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(15),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => RestaurantDetailsPage(
                                        restaurantId: r["id"]),
                                  ),
                                );
                              },
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(15),
                                      bottomLeft: Radius.circular(15),
                                    ),
                                    child: Image.network(
                                      r["imageUrl"],
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 100,
                                        height: 100,
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.restaurant,
                                            size: 40, color: Colors.grey),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            r["name"],
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(Icons.location_on,
                                                  size: 16,
                                                  color: Colors.indigo),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  r["location"],
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.black54,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Align(
                                            alignment: Alignment.bottomRight,
                                            child: TextButton.icon(
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        RestaurantDetailsCustomerPage(
                                                            restaurantId:
                                                                r["id"]),
                                                  ),
                                                );
                                              },
                                              icon: const Icon(
                                                  Icons.arrow_forward_ios,
                                                  size: 16,
                                                  color: Colors.indigo),
                                              label: const Text(
                                                "Take Survey",
                                                style: TextStyle(
                                                    color: Colors.indigo),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
