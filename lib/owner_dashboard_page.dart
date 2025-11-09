import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_cxapp/add_restaurant_page.dart';
import 'package:flutter_cxapp/login_page.dart';
import 'package:flutter_cxapp/restaurant_details_owner.dart';
import 'profile_page_owner.dart';

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

  @override
  void initState() {
    super.initState();
    _loadOwnerRestaurants();
  }

  Future<void> _loadOwnerRestaurants() async {
    final ownerId = _auth.currentUser?.uid;
    if (ownerId == null) return;

    final snap = await _db.child("restaurants").get();
    if (!snap.exists) {
      setState(() => _loading = false);
      return;
    }

    final data = (snap.value as Map).cast<String, dynamic>();
    final owned = data.entries
        .where((e) => (e.value["ownerId"] ?? "") == ownerId)
        .map((e) {
      final map = Map<String, dynamic>.from(e.value);
      return {
        "id": e.key,
        "name": map["name"],
        "location": map["location"],
        "imageUrl": map["imageUrl"] ??
            "https://cdn-icons-png.flaticon.com/512/857/857681.png",
        "surveys": map["surveys"] ?? {},
      };
    }).toList();

    _calculateAverages(owned);
    setState(() {
      _restaurants = owned;
      _loading = false;
    });
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
        content:
            const Text("Are you sure you want to delete this restaurant?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel")),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("🗑 Restaurant deleted")),
      );
      _loadOwnerRestaurants();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting: $e")),
      );
    }
  }

  // 🔹 Enhanced Logout with animation + confirmation
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
    // show loading spinner
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.3),
      pageBuilder: (_, __, ___) =>
          const Center(child: CircularProgressIndicator(color: Colors.white)),
    );

    try {
      await _auth.signOut();
      Navigator.pop(context); // close spinner
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Signed out successfully 👋"),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Logout failed: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Owner Dashboard"),
        backgroundColor: Colors.indigo,
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(user?.displayName ?? "Owner"),
              accountEmail: Text(user?.email ?? "No email"),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: Colors.indigo, size: 40),
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.indigo, Colors.blueAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text("Dashboard"),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.add_business),
              title: const Text("Add Restaurant"),
              onTap: () async {
                Navigator.pop(context);
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AddRestaurantPage()),
                );
                _loadOwnerRestaurants();
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text("Profile"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ProfilePageOwner()));
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text("Logout",
                  style: TextStyle(color: Colors.redAccent)),
              onTap: _confirmLogout,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AddRestaurantPage()));
          _loadOwnerRestaurants();
        },
        label: const Text("Add Restaurant"),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.indigo,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildChartSection(),
                  const SizedBox(height: 20),
                  _restaurants.isEmpty
                      ? const Text("You have no restaurants yet.")
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _restaurants.length,
                          itemBuilder: (context, index) {
                            final r = _restaurants[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    r["imageUrl"],
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                title: Text(r["name"]),
                                subtitle: Text(r["location"]),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.redAccent),
                                  onPressed: () =>
                                      _deleteRestaurant(r["id"], r["imageUrl"]),
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => RestaurantDetailsOwnerPage(
                                          restaurantId: r["id"]),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
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
            const Text(
              "Overall Performance",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              child: BarChart(
                BarChartData(
                  maxY: 10,
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(toY: _avgCSAT, color: Colors.indigo)
                      ],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(toY: _avgCES, color: Colors.green)
                      ],
                    ),
                    BarChartGroupData(
                      x: 2,
                      barRods: [
                        BarChartRodData(toY: _avgNPS, color: Colors.pink)
                      ],
                    ),
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
}
