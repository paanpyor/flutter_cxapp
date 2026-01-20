// lib/profile_page_customer.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_cxapp/metric_bento_card.dart';
import 'package:flutter_cxapp/review_history.dart';
import 'package:intl/intl.dart';
import 'app_theme.dart';
import 'common_widget.dart';
import 'review_history.dart';

class ProfilePageCustomer extends StatefulWidget {
  const ProfilePageCustomer({super.key});

  @override
  State<ProfilePageCustomer> createState() => _ProfilePageCustomerState();
}

class _ProfilePageCustomerState extends State<ProfilePageCustomer> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  bool _loading = true;
  String _userName = "User";
  String _email = "";
  String _profileImageUrl = "https://cdn-icons-png.flaticon.com/512/3135/3135715.png";
  int _streak = 0;
  List<Map<String, dynamic>> _surveyHistory = [];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    _email = user.email ?? "No Email";

    try {
      // 1. Load User Data (Streak)
      final userRef = _db.child("users").child(user.uid);
      final snap = await userRef.get();
      final userData = snap.value as Map<dynamic, dynamic>?;

      final today = DateTime.now();
      
      if (userData != null) {
        _userName = userData["name"] ?? "Customer";
        _profileImageUrl = userData["profileImageUrl"] ?? _profileImageUrl;
        _streak = (userData["streak"] as num?)?.toInt() ?? 0;
        
        final lastLoginStr = userData["lastLogin"] as String?;
        if (lastLoginStr != null) {
          try {
            final lastLogin = DateTime.parse(lastLoginStr);
            final lastLoginDate = DateUtils.dateOnly(lastLogin);
            final todayDate = DateUtils.dateOnly(today);
            final yesterdayDate = DateUtils.dateOnly(today.subtract(const Duration(days: 1)));

            if (lastLoginDate.isAtSameMomentAs(yesterdayDate)) {
              _streak++;
              await userRef.update({"lastLogin": today.toIso8601String(), "streak": _streak});
            } else if (lastLoginDate.isBefore(yesterdayDate)) {
              _streak = 1;
              await userRef.update({"lastLogin": today.toIso8601String(), "streak": _streak});
            }
          } catch (e) {
            debugPrint("Date parsing error: $e");
            _streak = 1;
          }
        } else {
           _streak = 1;
           await userRef.update({"lastLogin": today.toIso8601String(), "streak": _streak});
        }
      } else {
        _streak = 1;
        await userRef.set({"lastLogin": today.toIso8601String(), "streak": 1});
      }
      
      // 2. Load All Restaurants (Map for lookup)
      final restSnap = await _db.child("restaurants").get();
      Map<String, dynamic> allRestaurants = {};
      if (restSnap.exists) {
        allRestaurants = Map<String, dynamic>.from(restSnap.value as Map);
      }

      // 3. Load Completed Surveys (CHECKING 'completedSurveys' NODE)
      // Path: users/{uid}/completedSurveys
      final completedSnap = await _db.child("users/${user.uid}/completedSurveys").get();
      List<Map<String, dynamic>> history = [];
      
      if (completedSnap.exists) {
        final completedData = Map<String, dynamic>.from(completedSnap.value as Map);
        
        // Iterate through restaurant IDs that have data in 'completedSurveys'
        for (var rId in completedData.keys) {
          final completedInfo = Map<String, dynamic>.from(completedData[rId]);
          
          // If 'completed' is true, it means the user has taken this survey
          if (completedInfo["completed"] == true) {
            final restaurant = allRestaurants[rId] ?? {};
            
            // Gather the CSAT, CES, NPS scores from the 'completedSurveys' data
            // This data comes from csat_page, ces_page, nps_page overwrites
            final csat = completedInfo["csat"] as num?;
            final ces = completedInfo["ces"] as num?;
            final nps = completedInfo["nps"] as num?;

            history.add({
              "restaurantId": rId,
              "restaurantName": restaurant["name"] ?? "Unknown Restaurant",
              "location": restaurant["location"] ?? "Unknown Location",
              "imageUrl": restaurant["imageUrl"] ?? "https://cdn-icons-png.flaticon.com/512/857/857681.png",
              "date": completedInfo["date"] ?? DateTime.now().toIso8601String(),
              // STORE SCORES FOR REVIEW
              "csat": csat,
              "ces": ces,
              "nps": nps,
            });
          }
        }

        // Sort by Date (Newest First)
        history.sort((a, b) => (b["date"] as String).compareTo(a["date"] as String));
      }

      debugPrint("Loaded Streak: $_streak");
      debugPrint("Loaded Surveys (Taken Count): ${history.length}");

      if (mounted) {
        setState(() {
          _surveyHistory = history;
        });
      }

    } catch (e) {
      debugPrint("Error loading profile: $e");
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _showEditProfileDialog() async {
    TextEditingController nameController = TextEditingController(text: _userName);
    TextEditingController imageController = TextEditingController(text: _profileImageUrl);

    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Profile"),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Name"),
                validator: (v) => v!.isEmpty ? "Name required" : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: imageController,
                decoration: const InputDecoration(labelText: "Image URL"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final user = _auth.currentUser;
                if (user != null) {
                  await _db.child("users/${user.uid}").update({
                    "name": nameController.text,
                    "profileImageUrl": imageController.text,
                  });
                  if (mounted) {
                    setState(() {
                      _userName = nameController.text;
                      _profileImageUrl = imageController.text;
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile updated!")));
                  }
                }
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("My Profile"),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primary,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  
                  // Profile Picture
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundImage: NetworkImage(_profileImageUrl),
                          backgroundColor: AppTheme.primary.withOpacity(0.1),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: InkWell(
                            onTap: _showEditProfileDialog, 
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: AppTheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.edit, color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  Text(
                    _userName,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _email,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 30),
                  
                  // Stats Row
                  Row(
                    children: [
                      Expanded(
                        child: MetricBentoCard(
                          title: "Day Streak",
                          value: "$_streak",
                          icon: Icons.local_fire_department,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: MetricBentoCard(
                          title: "Surveys Taken",
                          value: "${_surveyHistory.length}", // Counts from completedSurveys
                          icon: Icons.assignment_turned_in,
                          color: AppTheme.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  
                  // Account Info
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.person, color: AppTheme.primary),
                            const SizedBox(width: 12),
                            Text("Account Details", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                        const Divider(height: 30),
                        _buildDetailRow("Name", _userName),
                        const SizedBox(height: 12),
                        _buildDetailRow("Email", _email),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 30),

                  // Survey History Section (Mini Preview)
                  if (_surveyHistory.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                         const Text("Recent Activity", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ..._surveyHistory.take(3).map((survey) => _buildHistoryCard(survey)),
                  ],

                  const SizedBox(height: 30),
                  
                  // Settings Actions
                  AppCard(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.history, color: AppTheme.primary),
                          title: const Text("Review History", style: TextStyle(fontWeight: FontWeight.bold)),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                             Navigator.push(
                               context,
                               MaterialPageRoute(
                                 builder: (_) => ReviewHistoryPage(surveys: _surveyHistory),
                               ),
                             );
                          },
                        ),
                        
                        const Divider(),
                        
                        ListTile(
                          leading: const Icon(Icons.logout, color: Colors.red),
                          title: const Text("Log Out", style: TextStyle(color: Colors.red)),
                          onTap: () async {
                            await _auth.signOut();
                            if (mounted) {
                              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      ],
    );
  }

  // Widget to display mini history card (for profile page)
  Widget _buildHistoryCard(Map<String, dynamic> survey) {
    DateTime date = DateTime.parse(survey["date"]);
    String formattedDate = DateFormat('dd MMM yyyy').format(date);

    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Survey at ${survey["restaurantName"]}")));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                survey["imageUrl"],
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 50, height: 50, color: Colors.grey[300],
                  child: const Icon(Icons.restaurant, size: 24),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    survey["restaurantName"],
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    survey["location"],
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Text(
              formattedDate,
              style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}