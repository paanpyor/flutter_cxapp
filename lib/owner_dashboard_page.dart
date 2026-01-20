// lib/owner_dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

// Page Imports
import 'app_theme.dart';
import 'common_header.dart';
import 'add_restaurant_page.dart';
import 'edit_restaurant_page.dart';
import 'restaurant_details_owner.dart';
import 'near_me_page.dart';
import 'profile_page_owner.dart';
import 'settings_page.dart';

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
  
  // Metrics
  double _avgCSAT = 0.0;
  double _avgCES = 0.0;
  double _avgNPS = 0.0;
  double _overallRating = 0.0; 
  
  // User Data
  String? _userName;
  int _currentStreak = 0;
  String? _todayMood;
  int _currentIndex = 0;

  // Chart Data (Merged from Code 2)
  List<Map<String, dynamic>> _recentSurveyData = []; // For Line Chart
  Map<String, int> _surveyTypeCounts = {}; // For Pie Chart

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadOwnerRestaurants();
  }

  // --- HELPER: Get Dynamic Greeting ---
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning";
    if (hour < 17) return "Good Afternoon";
    return "Good Evening";
  }

  // --- LOGIC: LOAD USER DATA (Streak & Mood) ---
  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user == null) return;
    _userName = user.displayName ?? user.email?.split('@').first ?? "Owner";
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final userRef = _db.child("users/${user.uid}");
    
    final streakSnap = await userRef.child("loginStreak").get();
    int streak = 0;
    String? lastLoginDate;
    
    if (streakSnap.exists) {
      final data = Map<String, dynamic>.from(streakSnap.value as Map);
      streak = (data["streak"] as num?)?.toInt() ?? 0;
      lastLoginDate = data["lastLogin"] as String?;
    }
    
    // Logic to check consecutive days
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

  // --- IMPROVED: SAVE MOOD WITH ERROR HANDLING ---
  Future<void> _saveMood(String mood) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint("User is null in _saveMood");
        return;
      }
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      
      // 1. Save to Database
      await _db.child("users/${user.uid}/moods/$today").set(mood);
      
      // 2. Update UI State
      if (mounted) {
        setState(() => _todayMood = mood);
        
        // 3. Show Visual Feedback
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Mood updated! 💖"),
            duration: Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      // Catch errors
      debugPrint("Error saving mood: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error saving mood: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // --- LOGIC: LOAD RESTAURANTS & CALCULATE STATS ---
  Future<void> _loadOwnerRestaurants() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      
      final snap = await _db.child("restaurants").get();
      if (snap.exists && snap.value != null) {
        final data = (snap.value as Map).cast<String, dynamic>();
        final owned = data.entries.where((e) => (e.value["ownerId"] ?? "") == user.uid).map((e) {
          final map = Map<String, dynamic>.from(e.value);
          return {
            "id": e.key,
            "name": map["name"] ?? "Unnamed",
            "location": map["location"] ?? "Unknown",
            "imageUrl": map["imageUrl"] ?? "https://cdn-icons-png.flaticon.com/512/857/857681.png",
            "surveys": map["surveys"] ?? {},
          };
        }).toList();
        
        // Combined Calculation Logic
        _calculateOverallRating(owned);
        _restaurants = owned;
      }
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _calculateOverallRating(List<dynamic> list) {
    double totalCSAT = 0, totalCES = 0, totalNPS = 0;
    int count = 0;
    
    // Prepare Chart Data Containers
    List<Map<String, dynamic>> allSurveys = [];
    Map<String, int> surveyTypeCounts = {};

    for (final r in list) {
      final surveys = (r["surveys"] as Map?) ?? {};
      for (final s in surveys.values) {
        final survey = Map<String, dynamic>.from(s);
        
        // Basic Totals
        totalCSAT += _toDouble(survey["csat"]);
        totalCES += _toDouble(survey["ces"]);
        totalNPS += _toDouble(survey["nps"]);
        count++;

        // Line Chart Data Prep
        if (survey["date"] != null) {
          try {
            allSurveys.add({
              "date": DateTime.parse(survey["date"]),
              "nps": _toDouble(survey["nps"]),
            });
          } catch (e) {
            // Handle date parsing errors gracefully
          }
        }

        // Pie Chart Data Prep
        final type = survey["type"] ?? "Other";
        surveyTypeCounts[type] = (surveyTypeCounts[type] ?? 0) + 1;
      }
    }

    // Calculate Averages
    if (count > 0) {
      _avgCSAT = totalCSAT / count;
      _avgCES = totalCES / count;
      _avgNPS = totalNPS / count;
      _overallRating = (_avgCSAT + _avgCES + _avgNPS) / 3;
    }

    // Sort surveys for Line Chart (Chronological)
    allSurveys.sort((a, b) => a["date"].compareTo(b["date"]));
    _recentSurveyData = allSurveys.take(7).toList(); // Take last 7
    
    // Update State for Pie Chart
    _surveyTypeCounts = surveyTypeCounts;
  }

  double _toDouble(dynamic v) => (v is num) ? v.toDouble() : double.tryParse(v.toString()) ?? 0.0;

  // --- LOGIC: DELETE RESTAURANT ---
  Future<void> _deleteRestaurant(String id) async {
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
    if (confirm == true) {
      try {
        await _db.child("restaurants/$id").remove();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Restaurant deleted")));
        _loadOwnerRestaurants();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }
  
  // --- IMPROVED: BUILD MOOD BUTTON ---
  Widget _buildMoodButton(String emoji, String value) {
    final isSelected = _todayMood == value;
    return InkWell(
      onTap: () => _saveMood(value),
      borderRadius: BorderRadius.circular(20),
      // ADDED: Visual Splash Effect
      splashColor: AppTheme.primary.withOpacity(0.2),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withOpacity(0.1) : Colors.grey[100],
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? AppTheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Text(
          emoji, 
          style: const TextStyle(fontSize: 20)
        ),
      ),
    );
  }

  String _getDetailedInsights() {
    final insights = StringBuffer();
    insights.writeln("📊 Performance Analysis");
    insights.writeln("Your restaurant's overall rating is ${_overallRating.toStringAsFixed(1)}/10.");
    if (_overallRating < 4) {
       insights.writeln("• Critical Status: Performance is below average.");
       insights.writeln("• Action: Review food quality immediately.");
    } else if (_overallRating < 7) {
       insights.writeln("• Needs Improvement: Moderate performance.");
       insights.writeln("• Action: Focus on staff training.");
    } else {
       insights.writeln("• Good Performance: Keep it up!");
    }
    insights.writeln("");
    insights.writeln("📈 Trend Analysis:");
    if (_avgCES > 6) {
       insights.writeln("• High Effort: Simplify the ordering process.");
    } else {
       insights.writeln("• Low Effort: Customers love the ease of use.");
    }
    return insights.toString();
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(16), 
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[700])), 
            Icon(icon, color: color, size: 24)
          ]),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  // Chart UI Helpers (From Code 2)
  List<PieChartSectionData> _getPieSections() {
    final List<MapEntry<String, int>> entries = _surveyTypeCounts.entries.toList();
    if (entries.isEmpty) return [];
    
    final int total = entries.fold(0, (sum, item) => sum + item.value);
    
    return entries.map((e) {
      final isNPS = e.key == "NPS";
      final isCSAT = e.key == "CSAT";
      final color = isNPS ? AppTheme.primary : (isCSAT ? Colors.orange : Colors.green); // Using AppTheme colors
      
      return PieChartSectionData(
        color: color,
        value: e.value.toDouble(),
        title: '${((e.value / total) * 100).toInt()}%',
        radius: 50,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();
  }

  Widget _buildChartCard(String title, Widget child) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            child,
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
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HEADER
                const CommonHeader(title: "CXTRACKER"),
                const SizedBox(height: 20),

                // --- IMPROVED WELCOME SECTION ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Left Side: Greeting & Name
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${_getGreeting()}", // Dynamic Greeting
                            style: const TextStyle(
                              fontSize: 14, 
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 6), 
                          Text(
                            _userName ?? "Owner",
                            style: const TextStyle(
                              fontSize: 24, 
                              fontWeight: FontWeight.w800, 
                              color: AppTheme.textPrimary,
                              letterSpacing: -0.5, 
                            ),
                          ),
                        ],
                      ),
                      
                      // Right Side: Profile Avatar (New)
                      GestureDetector(
                        onTap: () {
                          // Optional: Navigate to Profile
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 26,
                            backgroundColor: AppTheme.primary.withOpacity(0.1),
                            child: Icon(Icons.person_rounded, 
                               color: AppTheme.primary, 
                               size: 26
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // -------------------------------------

                const SizedBox(height: 12),

                // Streak & Mood Row (Merged Logic)
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                      child: Row(children: [
                        const Icon(Icons.local_fire_department, size: 16, color: Colors.orange),
                        const SizedBox(width: 4),
                        Text("$_currentStreak-Day Streak", style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                      ]),
                    ),
                    const Spacer(),
                    const Text("Mood: ", style: TextStyle(fontSize: 14)),
                    _buildMoodButton("🙂", "Happy"),
                    const SizedBox(width: 4),
                    _buildMoodButton("😐", "Okay"),
                    const SizedBox(width: 4),
                    _buildMoodButton("😢", "Stressed"),
                  ],
                ),
                const SizedBox(height: 30),

                // Bento Grid Stats
                Row(
                  children: [
                    Expanded(child: _buildStatCard("NPS", _avgNPS.toStringAsFixed(1), Icons.thumb_up, AppTheme.primary)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatCard("CSAT", _avgCSAT.toStringAsFixed(1), Icons.sentiment_satisfied, Colors.orange)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildStatCard("CES", _avgCES.toStringAsFixed(1), Icons.access_time, Colors.green)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatCard("Overall", _overallRating.toStringAsFixed(1), Icons.star, Colors.purple)),
                  ],
                ),
                const SizedBox(height: 24),

                // --- NEW CHART 1: Performance Trend (Line Chart) ---
                _buildChartCard(
                  "NPS Trend (Last 7 Entries)",
                  _recentSurveyData.isEmpty
                      ? const Center(child: Text("No data for trend", style: TextStyle(color: Colors.grey)))
                      : SizedBox(
                          height: 200,
                          child: LineChart(
                            LineChartData(
                              gridData: FlGridData(show: false),
                              titlesData: FlTitlesData(show: false),
                              borderData: FlBorderData(show: false),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: _recentSurveyData.asMap().entries.map((e) {
                                    return FlSpot(e.key.toDouble(), e.value["nps"]);
                                  }).toList(),
                                  isCurved: true,
                                  color: AppTheme.primary,
                                  barWidth: 3,
                                  dotData: const FlDotData(show: true),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: AppTheme.primary.withOpacity(0.2),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 16),

                // --- NEW CHART 2: Survey Type Distribution (Pie Chart) ---
                _buildChartCard(
                  "Survey Participation",
                  _surveyTypeCounts.isEmpty
                      ? const Center(child: Text("No data available", style: TextStyle(color: Colors.grey)))
                      : SizedBox(
                          height: 200,
                          child: PieChart(
                            PieChartData(
                              sectionsSpace: 2,
                              centerSpaceRadius: 40,
                              sections: _getPieSections(),
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 24),

                // AI Insights (Fixed BoxDecoration)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [Icon(Icons.lightbulb, color: AppTheme.primary), const SizedBox(width: 8), const Text("AI Insights", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))]),
                      const SizedBox(height: 8),
                      Text(_getDetailedInsights(), style: const TextStyle(fontSize: 14, height: 1.4)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Restaurant List
                const Text("Your Restaurants", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ..._restaurants.map((r) => Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        r["imageUrl"],
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[200],
                          width: 60,
                          height: 60,
                          child: const Icon(Icons.restaurant),
                        ),
                      ),
                    ),
                    title: Text(r["name"], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(r["location"]),
                    
                    // --- UPDATED TRAILING SECTION ---
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 1. Edit Button
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: AppTheme.primary),
                          onPressed: () {
                            // Navigate to Edit Page and refresh on return
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditRestaurantPage(restaurantId: r["id"]),
                              ),
                            ).then((_) => _loadOwnerRestaurants());
                          },
                        ),
                        // 2. Delete Button
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent), 
                          onPressed: () => _deleteRestaurant(r["id"])
                        ),
                      ],
                    ),
                    // ------------------------------------
                    
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RestaurantDetailsOwnerPage(restaurantId: r["id"]),
                      ),
                    ),
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
           if (i == 0) { _loadOwnerRestaurants(); }
           setState(() => _currentIndex = i);
        },
        selectedItemColor: AppTheme.primary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Dashboard"),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: "Near Me"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
           await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddRestaurantPage()));
           _loadOwnerRestaurants();
        }, 
        backgroundColor: AppTheme.primary, 
        child: const Icon(Icons.add, color: Colors.white)
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}