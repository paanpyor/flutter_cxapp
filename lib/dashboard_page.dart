// lib/dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_cxapp/restaurant_details_customer.dart';
import 'package:flutter_cxapp/profile_page_customer.dart';
import 'package:flutter_cxapp/settings_page.dart';
import 'package:flutter_cxapp/near_me_page.dart';
import 'package:flutter_cxapp/qr_scanner_page.dart';
import 'package:intl/intl.dart';
import 'app_theme.dart';
import 'common_header.dart'; 

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
  
  final Map<String, bool> _restaurantSurveyStatus = {}; 
  
  final TextEditingController _searchController = TextEditingController();
  String _selectedSort = "A–Z";
  String _selectedLocation = "All";
  
  String? _userName;
  String? _profileImageUrl; // Added to store profile image
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

  // --- HELPER: Get Dynamic Greeting ---
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning";
    if (hour < 17) return "Good Afternoon";
    return "Good Evening";
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user == null) return;
    _userName = user.displayName ?? user.email?.split('@').first ?? "User";
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final userRef = _db.child("users/${user.uid}");
    
    // 1. Streak
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

    // 2. Load Profile Image
    final profileSnap = await userRef.get();
    if (profileSnap.exists) {
      final data = Map<String, dynamic>.from(profileSnap.value as Map);
      _profileImageUrl = data["profileImageUrl"];
    }

    // 3. Mood
    final moodSnap = await userRef.child("moods/$today").get();
    if (moodSnap.exists) {
      _todayMood = moodSnap.value as String?;
    } else {
      _todayMood = null;
    }

    // 4. Load User Surveys
    final surveysSnap = await _db.child("user_surveys/${user.uid}").get();
    _surveysTaken = surveysSnap.exists ? (surveysSnap.value as Map?)?.length ?? 0 : 0;

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

  Future<void> _loadRestaurants() async {
    try {
      final snap = await _db.child("restaurants").get();
      if (snap.exists && snap.value != null) {
        final data = (snap.value as Map).cast<String, dynamic>();
        final list = data.entries.map((e) {
          final map = Map<String, dynamic>.from(e.value);
          
          // --- Calculate Average Rating from quickRatings ---
          double rating = 0.0;
          int ratingCount = 0;
          
          if (map.containsKey("quickRatings") && map["quickRatings"] != null) {
            final ratings = Map<String, dynamic>.from(map["quickRatings"]);
            double sum = 0;
            ratings.forEach((k, v) {
              sum += (v["rating"] as num?)?.toDouble() ?? 0.0;
              ratingCount++;
            });
            if (ratingCount > 0) {
              rating = sum / ratingCount;
            }
          }

          // --- Count Total Surveys ---
          int totalSurveys = 0;
          if (map.containsKey("surveys") && map["surveys"] != null) {
             totalSurveys = (map["surveys"] as Map).length;
          }

          return {
            "id": e.key,
            "name": map["name"] ?? "Unnamed",
            "location": map["location"] ?? "Unknown",
            "imageUrl": map["imageUrl"] ?? "https://cdn-icons-png.flaticon.com/512/857/857681.png",
            "rating": rating,
            "ratingCount": ratingCount,
            "totalSurveys": totalSurveys,
          };
        }).toList();
        
        // --- FIX: Check Survey Status using Correct Path ---
        await _checkSurveyStatus(list);

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

  // --- FIX: CHECK SURVEY STATUS ---
  // Changed to check 'completedSurveys' path specifically for each restaurant
  Future<void> _checkSurveyStatus(List<dynamic> restaurants) async {
    final user = _auth.currentUser;
    if (user == null) return;

    for (var r in restaurants) {
      final String rId = r["id"];
      
      // Check the specific node where survey pages save data
      // Path: users/{uid}/completedSurveys/{restaurantId}
      final snap = await _db.child("users/${user.uid}/completedSurveys/$rId").get();

      if (snap.exists && snap.value != null) {
        final data = Map<String, dynamic>.from(snap.value as Map);
        // If 'completed' flag is true, set status to true
        _restaurantSurveyStatus[rId] = data["completed"] == true;
      } else {
        // If node doesn't exist yet, it's not done
        _restaurantSurveyStatus[rId] = false;
      }
    }
    
    if (mounted) setState(() {});
  }

  Future<void> _saveQuickRating(String restaurantId, int rating) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _db.child("restaurants/$restaurantId/quickRatings/${user.uid}").set({
      "rating": rating,
      "date": DateTime.now().toIso8601String()
    });
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Rating saved!"))
    );
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
            width: 2, // Thicker border for selected state
          ),
        ),
        child: Text(
          emoji, 
          style: const TextStyle(fontSize: 20)
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeContent(),
          const NearMePage(),
          const ProfilePageCustomer(),
          const SettingsPage(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const QRScannerPage())),
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.qr_code_scanner, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildHomeContent() {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80), 
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CommonHeader(title: "CXTRACKER"),
          const SizedBox(height: 16),
          
          // --- IMPROVED GREETING HEADER ---
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
                    const SizedBox(height: 6), // Added spacing
                    Text(
                      _userName ?? "User",
                      style: const TextStyle(
                        fontSize: 24, // Bigger name for impact
                        fontWeight: FontWeight.w800, // Extra Bold
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.5, // Modern tight tracking
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
                      backgroundImage: /* If you have image url */
                                 _profileImageUrl != null && _profileImageUrl!.isNotEmpty 
                                     ? NetworkImage(_profileImageUrl!) 
                                     : null,
                      child: /* Fallback icon if no image */
                          (_profileImageUrl == null || _profileImageUrl!.isEmpty)
                              ? const Icon(Icons.person_rounded, 
                                 color: AppTheme.primary, 
                                 size: 26)
                              : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // -------------------------------------
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Row(children: [Icon(Icons.local_fire_department, size: 16, color: Colors.orange), const SizedBox(width: 4), Text("$_currentStreak-Day Streak", style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold))]),
              ),
              const Spacer(),
              const Text("Mood: ", style: TextStyle(fontSize: 12)),
              _buildMoodButton("🙂", "Happy"),
              const SizedBox(width: 8),
              _buildMoodButton("😐", "Okay"),
              const SizedBox(width: 8),
              _buildMoodButton("😢", "Sad"),
            ],
          ),
          const SizedBox(height: 20),

          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: "Search restaurants...",
              prefixIcon: const Icon(Icons.search, color: AppTheme.primary),
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(child: DropdownButtonFormField<String>(initialValue: _selectedLocation, decoration: const InputDecoration(labelText: "Location"), items: _uniqueLocations.map((loc) => DropdownMenuItem(value: loc, child: Text(loc))).toList(), onChanged: (val) { setState(() { _selectedLocation = val!; _applyFilters(); }); })),
              const SizedBox(width: 12),
              Expanded(child: DropdownButtonFormField<String>(initialValue: _selectedSort, decoration: const InputDecoration(labelText: "Sort"), items: const [DropdownMenuItem(value: "A–Z", child: Text("Name A–Z")), DropdownMenuItem(value: "Z–A", child: Text("Name Z–A")), DropdownMenuItem(value: "Location", child: Text("By Location"))], onChanged: (val) { setState(() { _selectedSort = val!; _applyFilters(); }); })),
            ],
          ),
          const SizedBox(height: 24),

          _filteredRestaurants.isEmpty ? const Center(child: Text("No restaurants found.", style: TextStyle(fontSize: 16)))
          : GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.7, crossAxisSpacing: 16, mainAxisSpacing: 16),
              itemCount: _filteredRestaurants.length,
              itemBuilder: (context, index) {
                final r = _filteredRestaurants[index];
                final bool isSurveyTaken = _restaurantSurveyStatus[r["id"]] ?? false;
                return _buildRestaurantCard(r, isSurveyTaken);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildRestaurantCard(Map<String, dynamic> r, bool isSurveyTaken) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RestaurantDetailsCustomerPage(restaurantId: r["id"]))),
      borderRadius: BorderRadius.circular(16),
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Image.network(r["imageUrl"], width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.grey[200], child: const Icon(Icons.restaurant))),
                  Positioned(
                    top: 8, right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(12)),
                      child: Text(r["location"], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  if(isSurveyTaken)
                    Positioned(
                      top: 8, left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(8)),
                        child: const Text("Done", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    )
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r["name"], style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RestaurantDetailsCustomerPage(restaurantId: r["id"]))),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSurveyTaken ? Colors.green : Colors.grey,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(isSurveyTaken ? "Survey Completed" : "Take Survey", style: const TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Row: Rating and Survey Count
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // RATING DISPLAY
                      Row(
                        children: [
                          const Icon(Icons.star, color: AppTheme.primary, size: 14),
                          const SizedBox(width: 2),
                          Text(
                            r["rating"] != null ? (r["rating"] as double).toStringAsFixed(1) : "0.0",
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 12),
                          ),
                          if (r["ratingCount"] != null && r["ratingCount"] > 0)
                            Padding(
                              padding: const EdgeInsets.only(left: 4.0),
                              child: Text("(${r["ratingCount"]})", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                            ),
                        ],
                      ),

                      // SURVEY COUNT DISPLAY
                      Row(
                        children: [
                          Icon(Icons.poll, size: 12, color: Colors.grey[600]),
                          const SizedBox(width: 2),
                          Text(
                            "${r["totalSurveys"] ?? 0}",
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text("Surveys", style: TextStyle(fontSize: 10, color: Colors.grey)),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  BottomNavigationBar _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (i) {
         if (i == 0) { setState(() => _currentIndex = i); _loadRestaurants(); } else { setState(() => _currentIndex = i); }
      },
      selectedItemColor: AppTheme.primary,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: "Home"),
        BottomNavigationBarItem(icon: Icon(Icons.map_rounded), label: "Near Me"),
        BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: "Profile"),
        BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: "Settings"),
      ],
    );
  }
}