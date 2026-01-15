// lib/dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_cxapp/login_page.dart';
import 'package:flutter_cxapp/restaurant_details_customer.dart';
import 'package:flutter_cxapp/profile_page_customer.dart';
import 'package:flutter_cxapp/settings_page.dart';
import 'package:flutter_cxapp/near_me_page.dart';
import 'package:flutter_cxapp/qr_scanner_page.dart';
import 'package:intl/intl.dart';

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
  String? _userName;
  int _currentStreak = 0;
  int _surveysTaken = 0;
  String? _todayMood;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadRestaurants();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user == null) return;
    _userName = user.displayName ?? user.email?.split('@').first ?? "User";
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final userRef = _db.child("users/${user.uid}");
    
    // Load streak
    final streakSnap = await userRef.child("loginStreak").get();
    int streak = 0;
    String? lastLoginDate;
    if (streakSnap.exists) {
      final data = Map<String, dynamic>.from(streakSnap.value as Map);
      streak = (data["streak"] as num?)?.toInt() ?? 0;
      lastLoginDate = data["lastLogin"] as String?;
    }
    if (lastLoginDate == today) {
      _currentStreak = streak;
    } else {
      final yesterday = DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 1)));
      if (lastLoginDate == yesterday) {
        streak++;
      } else {
        streak = 1;
      }
      await userRef.child("loginStreak").set({"streak": streak, "lastLogin": today});
      _currentStreak = streak;
    }

    // Load mood
    final moodSnap = await userRef.child("moods/$today").get();
    if (moodSnap.exists) {
      _todayMood = moodSnap.value as String?;
    }

    // Load surveys taken
    final surveysSnap = await _db.child("user_surveys/${user.uid}").get();
    _surveysTaken = surveysSnap.exists ? (surveysSnap.value as Map?)?.length ?? 0 : 0;

    if (mounted) setState(() {});
  }

  Future<void> _saveMood(String mood) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await _db.child("users/${user.uid}/moods/$today").set(mood);
    if (mounted) setState(() => _todayMood = mood);
  }

  Future<void> _loadRestaurants() async {
    try {
      final snap = await _db.child("restaurants").get();
      if (snap.exists && snap.value != null) {
        final data = (snap.value as Map).cast<String, dynamic>();
        final list = data.entries.map((e) {
          final map = Map<String, dynamic>.from(e.value);
          return {
            "id": e.key,
            "name": map["name"] ?? "Unnamed",
            "location": map["location"] ?? "Unknown",
            "imageUrl": map["imageUrl"] ?? "https://cdn-icons-png.flaticon.com/512/857/857681.png",
          };
        }).toList();
        final locations = list.map((r) => r["location"] as String).toSet().toList()..sort();
        _restaurants = list;
        _filteredRestaurants = list;
        _uniqueLocations = ["All", ...locations];
      }
    } catch (e) {
      _restaurants = [];
      _filteredRestaurants = [];
      _uniqueLocations = ["All"];
    }
    if (mounted) setState(() => _loading = false);
  }

  void _onSearchChanged() => _applyFilters();

  void _applyFilters() {
    String query = _searchController.text.toLowerCase();
    String selectedLocation = _selectedLocation;
    List<Map<String, dynamic>> result = _restaurants.where((r) {
      final name = r["name"].toString().toLowerCase();
      final location = r["location"].toString().toLowerCase();
      bool matchesQuery = name.contains(query) || location.contains(query);
      bool matchesLocation = selectedLocation == "All" || r["location"] == selectedLocation;
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

  Future<void> _confirmLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirm Logout"),
        content: const Text("Are you sure you want to sign out?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Logout"),
          ),
        ],
      ),
    );
    if (confirm == true) _handleLogout();
  }

  Future<void> _handleLogout() async {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.3),
      pageBuilder: (_, __, ___) => const Center(child: CircularProgressIndicator(color: Colors.white)),
    );
    try {
      await _auth.signOut();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Signed out successfully"),
        backgroundColor: Colors.indigo,
      ));
      await Future.delayed(const Duration(milliseconds: 400));
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 700),
          pageBuilder: (_, animation, __) => FadeTransition(opacity: animation, child: const LoginPage()),
        ),
        (route) => false,
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Logout failed: $e")));
    }
  }

  Widget _buildMoodButton(String emoji, String value) {
    final isSelected = _todayMood == value;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.indigo : Colors.grey[200],
        foregroundColor: isSelected ? Colors.white : Colors.black,
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(12),
      ),
      onPressed: () => _saveMood(value),
      child: Text(emoji, style: const TextStyle(fontSize: 20)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final homeContent = _loading
        ? const Center(child: CircularProgressIndicator(color: Colors.indigo))
        : SingleChildScrollView(
            padding: const EdgeInsets.only(top: 0, left: 16, right: 16, bottom: 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Good Morning,", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      Text(
                        _userName ?? "User",
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.orangeAccent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.local_fire_department, size: 16, color: Colors.orange),
                                const SizedBox(width: 4),
                                Text("$_currentStreak-Day Streak", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.greenAccent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.assignment_turned_in, size: 16, color: Colors.green),
                                const SizedBox(width: 4),
                                Text("$_surveysTaken Completed", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text("How are you feeling today?", style: TextStyle(fontSize: 14)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildMoodButton("🙂", "Happy"),
                          const SizedBox(width: 8),
                          _buildMoodButton("😐", "Okay"),
                          const SizedBox(width: 8),
                          _buildMoodButton("😢", "Sad"),
                        ],
                      ),
                    ],
                  ),
                ),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Search restaurants...",
                    prefixIcon: const Icon(Icons.search, color: Colors.indigo),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: const BorderSide(color: Colors.indigo, width: 2)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedLocation,
                        decoration: InputDecoration(
                          labelText: "Location", filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: _uniqueLocations.map((loc) => DropdownMenuItem(value: loc, child: Text(loc))).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedLocation = val!;
                            _applyFilters();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedSort,
                        decoration: InputDecoration(
                          labelText: "Sort", filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: const [
                          DropdownMenuItem(value: "A–Z", child: Text("Name A–Z")),
                          DropdownMenuItem(value: "Z–A", child: Text("Name Z–A")),
                          DropdownMenuItem(value: "Location", child: Text("By Location")),
                        ],
                        onChanged: (val) {
                          setState(() {
                            _selectedSort = val!;
                            _applyFilters();
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _filteredRestaurants.isEmpty
                    ? const Center(child: Text("No restaurants found.", style: TextStyle(fontSize: 16, color: Colors.grey)))
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _filteredRestaurants.length,
                        itemBuilder: (context, index) {
                          final r = _filteredRestaurants[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => RestaurantDetailsCustomerPage(restaurantId: r["id"])),
                              ),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
                                    child: SizedBox(
                                      width: 90,
                                      height: 90,
                                      child: Image.network(
                                        r["imageUrl"],
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(color: Colors.grey[200], child: const Icon(Icons.restaurant, size: 32, color: Colors.grey)),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(r["name"], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(Icons.location_on, size: 14, color: Colors.indigo),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(r["location"], style: const TextStyle(fontSize: 13, color: Colors.black54), maxLines: 1, overflow: TextOverflow.ellipsis),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: SizedBox(
                                              height: 32,
                                              child: ElevatedButton(
                                                onPressed: () => Navigator.push(
                                                  context,
                                                  MaterialPageRoute(builder: (_) => RestaurantDetailsCustomerPage(restaurantId: r["id"])),
                                                ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.indigo,
                                                  foregroundColor: Colors.white,
                                                  padding: EdgeInsets.zero,
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                                ),
                                                child: const Text("Take Survey", style: TextStyle(fontSize: 12)),
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
              ],
            ),
          );

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: const Text("Restaurants", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.logout, color: Colors.grey), onPressed: _confirmLogout),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          homeContent,
          const NearMePage(),
          const ProfilePageCustomer(),
          const SettingsPage(),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        height: 64,
        color: Colors.white,
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home, "Home", 0),
              _buildNavItem(Icons.location_on, "Near Me", 1),
              const SizedBox(width: 40),
              _buildNavItem(Icons.person, "Profile", 2),
              _buildNavItem(Icons.settings, "Settings", 3),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const QRScannerPage())),
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.qr_code_scanner, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isActive ? Colors.indigo : Colors.grey, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isActive ? Colors.indigo : Colors.grey,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}