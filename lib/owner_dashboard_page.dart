import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_cxapp/add_restaurant_page.dart';
import 'package:flutter_cxapp/login_page.dart';
import 'package:flutter_cxapp/restaurant_details_owner.dart';
import 'package:flutter_cxapp/profile_page_owner.dart';

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
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
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
              leading: const Icon(Icons.dashboard, color: Colors.indigo),
              title: const Text("Dashboard"),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.add_business, color: Colors.indigo),
              title: const Text("Add Restaurant"),
              onTap: () async {
                Navigator.pop(context);
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddRestaurantPage()),
                );
                _loadOwnerRestaurants();
              },
            ),
            ListTile(
              leading: const Icon(Icons.person, color: Colors.indigo),
              title: const Text("Profile"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfilePageOwner()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text("Logout", style: TextStyle(color: Colors.redAccent)),
              onTap: _confirmLogout,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddRestaurantPage()),
          );
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildChartSection(),
                  const SizedBox(height: 24),
                  const Text(
                    "Your Restaurants",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_restaurants.isEmpty)
                    const Center(
                      child: Text(
                        "You haven't added any restaurants yet.",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  else
                    ..._restaurants.map((r) => _buildRestaurantCard(r)),
                ],
              ),
            ),
    );
  }

  Widget _buildRestaurantCard(Map<String, dynamic> r) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RestaurantDetailsOwnerPage(restaurantId: r["id"]),
            ),
          );
        },
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
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.restaurant, size: 32, color: Colors.grey),
                    );
                  },
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r["name"],
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 16, color: Colors.indigo),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            r["location"],
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                        height: 36,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RestaurantDetailsOwnerPage(
                                  restaurantId: r["id"],
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.visibility, size: 16, color: Colors.indigo),
                          label: const Text(
                            "View Details",
                            style: TextStyle(color: Colors.indigo, fontSize: 13),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.indigo),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Delete button on far right
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: () => _deleteRestaurant(r["id"], r["imageUrl"]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartSection() {
    return Card(
      elevation: 3,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                        BarChartRodData(toY: _avgNPS, color: Colors.pinkAccent)
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
                              return const Text("CSAT", style: TextStyle(fontSize: 12));
                            case 1:
                              return const Text("CES", style: TextStyle(fontSize: 12));
                            case 2:
                              return const Text("NPS", style: TextStyle(fontSize: 12));
                          }
                          return const Text("");
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(show: true, drawHorizontalLine: true),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}