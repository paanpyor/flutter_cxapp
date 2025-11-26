// lib/owner_dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_cxapp/add_restaurant_page.dart';
import 'package:flutter_cxapp/login_page.dart';
import 'package:flutter_cxapp/restaurant_details_owner.dart';
import 'package:flutter_cxapp/profile_page_owner.dart';
import 'package:flutter_cxapp/near_me_page.dart';
import 'package:flutter_cxapp/settings_page.dart';
import 'package:intl/intl.dart';

class OwnerDashboardPage extends StatefulWidget {
  const OwnerDashboardPage({super.key});

  @override
  State<OwnerDashboardPage> createState() => _OwnerDashboardPageState();
}

class _OwnerDashboardPageState extends State<OwnerDashboardPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  bool _loading = true;
  List<Map<String, dynamic>> _restaurants = [];
  double _avgCSAT = 0.0;
  double _avgCES = 0.0;
  double _avgNPS = 0.0;
  String? _userName;
  int _currentStreak = 0;
  String? _todayMood;

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadOwnerRestaurants();
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user == null) return;
    _userName = user.displayName ?? user.email?.split('@').first ?? "Owner";
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final userRef = _db.child("users/${user.uid}");
    final snap = await userRef.child("loginStreak").get();
    int streak = 0;
    String? lastLoginDate;
    if (snap.exists) {
      final data = Map<String, dynamic>.from(snap.value as Map);
      streak = (data["streak"] as num?)?.toInt() ?? 0;
      lastLoginDate = data["lastLogin"] as String?;
    }
    if (lastLoginDate == today) {
      _currentStreak = streak;
      final moodSnap = await userRef.child("moods/$today").get();
      if (moodSnap.exists) {
        _todayMood = moodSnap.value as String?;
      }
    } else {
      final yesterday = DateFormat('yyyy-MM-dd')
          .format(DateTime.now().subtract(const Duration(days: 1)));
      if (lastLoginDate == yesterday) {
        streak++;
      } else {
        streak = 1;
      }
      await userRef.child("loginStreak").set({
        "streak": streak,
        "lastLogin": today,
      });
      _currentStreak = streak;
    }
    if (mounted) setState(() {});
  }

  Future<void> _saveMood(String mood) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await _db.child("users/${user.uid}/moods/$today").set(mood);
    if (mounted) setState(() => _todayMood = mood);
  }

  Future<void> _loadOwnerRestaurants() async {
    try {
      final ownerId = _auth.currentUser?.uid;
      if (ownerId == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      final snap = await _db.child("restaurants").get();
      if (snap.exists && snap.value != null) {
        final data = (snap.value as Map).cast<String, dynamic>();
        final owned = data.entries
            .where((e) => (e.value["ownerId"] ?? "") == ownerId)
            .map((e) {
          final map = Map<String, dynamic>.from(e.value);
          return {
            "id": e.key,
            "name": map["name"] ?? "Unnamed",
            "location": map["location"] ?? "Unknown",
            "imageUrl": map["imageUrl"] ??
                "https://cdn-icons-png.flaticon.com/512/857/857681.png",
            "surveys": map["surveys"] ?? {},
          };
        }).toList();
        _calculateAverages(owned);
        if (mounted) {
          setState(() {
            _restaurants = owned;
            _loading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _restaurants = [];
            _loading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _restaurants = [];
          _loading = false;
        });
      }
    }
  }

  void _calculateAverages(List<Map<String, dynamic>> list) {
    double totalCSAT = 0, totalCES = 0, totalNPS = 0;
    int count = 0;
    for (final r in list) {
      final surveys = (r["surveys"] as Map?) ?? {};
      for (final s in surveys.values) {
        final survey = Map<String, dynamic>.from(s);
        totalCSAT += _toDouble(survey["csat"]);
        totalCES += _toDouble(survey["ces"]);
        totalNPS += _toDouble(survey["nps"]);
        count++;
      }
    }
    if (count > 0) {
      _avgCSAT = totalCSAT / count;
      _avgCES = totalCES / count;
      _avgNPS = totalNPS / count;
    } else {
      _avgCSAT = _avgCES = _avgNPS = 0;
    }
  }

  double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  Future<void> _deleteRestaurant(String id, String imageUrl) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Restaurant"),
        content: const Text("Are you sure you want to delete this restaurant?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _db.child("restaurants/$id").remove();
      if (imageUrl.contains("firebase")) {
        final ref = FirebaseStorage.instance.refFromURL(imageUrl);
        await ref.delete();
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("🗑 Restaurant deleted")));
      _loadOwnerRestaurants();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error deleting: $e")));
    }
  }

  Future<void> _confirmLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirm Logout"),
        content: const Text("Are you sure you want to sign out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
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
      pageBuilder: (_, __, ___) =>
          const Center(child: CircularProgressIndicator(color: Colors.white)),
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
          pageBuilder: (_, animation, __) => FadeTransition(
            opacity: animation,
            child: const LoginPage(),
          ),
        ),
        (route) => false,
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Logout failed: $e")));
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

  Widget _buildChartSection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Performance Metrics", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              child: BarChart(
                BarChartData(
                  maxY: 10,
                  barGroups: [
                    BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: _avgCSAT, color: Colors.indigo)]),
                    BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: _avgCES, color: Colors.green)]),
                    BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: _avgNPS, color: Colors.pinkAccent)]),
                  ],
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, _) {
                          switch (v.toInt()) {
                            case 0: return const Text("CSAT", style: TextStyle(fontSize: 12));
                            case 1: return const Text("CES", style: TextStyle(fontSize: 12));
                            case 2: return const Text("NPS", style: TextStyle(fontSize: 12));
                          }
                          return const Text("");
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(show: true),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dashboardContent = _loading
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
                      Row(
                        children: [
                          const Text("Hello,", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          Text(
                            _userName ?? "Owner",
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo),
                          ),
                        ],
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
                              children:  [
                                Icon(Icons.local_fire_department, size: 16, color: Colors.orange),
                                SizedBox(width: 4),
                                Text("$_currentStreak-Day Streak", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text("How are you today?", style: TextStyle(fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildMoodButton(" 🙂", "Happy"),
                          const SizedBox(width: 8),
                          _buildMoodButton(" 😐", "Okay"),
                          const SizedBox(width: 8),
                          _buildMoodButton(" 😫", "Stressed"),
                        ],
                      ),
                    ],
                  ),
                ),
                const Text("Customer Experience", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildChartSection(),
                const SizedBox(height: 28),
                const Text("Your Restaurants", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                if (_restaurants.isEmpty)
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.storefront_outlined, size: 80, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text("No restaurants added", style: TextStyle(fontSize: 18, color: Colors.grey)),
                        const SizedBox(height: 8),
                        const Text("Tap the + button to add your first restaurant.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _restaurants.length,
                    itemBuilder: (context, index) {
                      final r = _restaurants[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => RestaurantDetailsOwnerPage(restaurantId: r["id"])),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  bottomLeft: Radius.circular(16),
                                ),
                                child: SizedBox(
                                  width: 90,
                                  height: 90,
                                  child: Image.network(
                                    r["imageUrl"],
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      color: Colors.grey[200],
                                      child: const Icon(Icons.restaurant, size: 32, color: Colors.grey),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        r["name"],
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on, size: 14, color: Colors.indigo),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              r["location"],
                                              style: const TextStyle(fontSize: 13, color: Colors.black54),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: SizedBox(
                                          height: 32,
                                          child: OutlinedButton(
                                            onPressed: () => Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => RestaurantDetailsOwnerPage(restaurantId: r["id"]),
                                              ),
                                            ),
                                            style: OutlinedButton.styleFrom(
                                              side: const BorderSide(color: Colors.indigo),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                            ),
                                            child: const Text("View Insights", style: TextStyle(color: Colors.indigo, fontSize: 12)),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteRestaurant(r["id"], r["imageUrl"]),
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
        title: const Text("Dashboard", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          dashboardContent,        // Dashboard
          const NearMePage(),      // Near Me
          const ProfilePageOwner(),// Profile
          const SettingsPage(),    // Settings
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
              _buildNavItem(Icons.dashboard, "Dashboard", 0),
              _buildNavItem(Icons.location_on, "Near Me", 1),
              const SizedBox(width: 40),
              _buildNavItem(Icons.person, "Profile", 2),
              _buildNavItem(Icons.settings, "Settings", 3),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddRestaurantPage()));
          _loadOwnerRestaurants();
        },
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add, color: Colors.white),
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
          Icon(
            icon,
            color: isActive ? Colors.indigo : Colors.grey,
            size: 24,
          ),
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