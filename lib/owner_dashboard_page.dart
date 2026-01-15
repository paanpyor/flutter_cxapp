// lib/owner_dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'add_restaurant_page.dart';
import 'restaurant_details_owner.dart';
import 'profile_page_owner.dart';
import 'near_me_page.dart';
import 'settings_page.dart';
import 'package:intl/intl.dart';
import 'login_page.dart';

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
      if (moodSnap.exists) _todayMood = moodSnap.value as String?;
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
      if (ownerId == null) return;
      final snap = await _db.child("restaurants").get();
      if (snap.exists && snap.value != null) {
        final data = (snap.value as Map).cast<String, dynamic>();
        final owned = data.entries.where((e) => (e.value["ownerId"] ?? "") == ownerId).map((e) {
          final map = Map<String, dynamic>.from(e.value);
          return {
            "id": e.key,
            "name": map["name"] ?? "Unnamed",
            "location": map["location"] ?? "Unknown",
            "imageUrl": map["imageUrl"] ?? "https://cdn-icons-png.flaticon.com/512/857/857681.png",
            "surveys": map["surveys"] ?? {},
          };
        }).toList();
        _calculateAverages(owned);
        _restaurants = owned;
      }
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
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
    }
  }

  double _toDouble(dynamic v) => (v is num) ? v.toDouble() : double.tryParse(v.toString()) ?? 0.0;

  Future<void> _deleteRestaurant(String id, String imageUrl) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Restaurant"),
        content: const Text("Are you sure you want to delete this restaurant?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(context, true), child: const Text("Delete")),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _db.child("restaurants/$id").remove();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Restaurant deleted")));
      _loadOwnerRestaurants();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _confirmLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirm Logout"),
        content: const Text("Are you sure you want to sign out?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(context, true), child: const Text("Logout")),
        ],
      ),
    );
    if (confirm == true) _handleLogout();
  }

  Future<void> _handleLogout() async {
    await _auth.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
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
    final dashboardContent = _loading
        ? const Center(child: CircularProgressIndicator(color: Colors.indigo))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text("Hello,", style: TextStyle(color: Colors.grey)),
                      Text(_userName ?? "Owner", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    ]),
                    FloatingActionButton.small(
                      onPressed: () async {
                        await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddRestaurantPage()));
                        _loadOwnerRestaurants();
                      },
                      backgroundColor: const Color(0xFF4F46E5),
                      child: const Icon(Icons.add, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.orangeAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                    child: Row(children: [
                      Icon(Icons.local_fire_department, size: 16, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text("$_currentStreak-Day Streak", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                    ]),
                  ),
                  const SizedBox(width: 12),
                  const Text("How are you today?", style: TextStyle(fontSize: 14)),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  _buildMoodButton("🙂", "Happy"),
                  const SizedBox(width: 8),
                  _buildMoodButton("😐", "Okay"),
                  const SizedBox(width: 8),
                  _buildMoodButton("😢", "Stressed"),
                ]),
                const SizedBox(height: 30),
                const Text("Your Restaurants", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ..._restaurants.map((r) => Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(r["imageUrl"], width: 60, height: 60, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.grey[200], width: 60, height: 60)),
                    ),
                    title: Text(r["name"], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(r["location"]),
                    trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteRestaurant(r["id"], r["imageUrl"])),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RestaurantDetailsOwnerPage(restaurantId: r["id"]))),
                  ),
                )),
              ],
            ),
          );

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          SafeArea(child: dashboardContent),
          const NearMePage(),
          const ProfilePageOwner(),
          const SettingsPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) {
          if (i == 0) _confirmLogout();
          setState(() => _currentIndex = i);
        },
        selectedItemColor: const Color(0xFF4F46E5),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: "Dashboard"),
          BottomNavigationBarItem(icon: Icon(Icons.map_rounded), label: "Near Me"),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: "Profile"),
          BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: "Settings"),
        ],
      ),
    );
  }
}