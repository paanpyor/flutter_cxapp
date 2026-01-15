import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';


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
  int _surveysTaken = 0;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  /// Fetches user data, calculates and updates the login streak, and counts surveys taken.
  Future<void> _loadUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    _email = user.email ?? "No Email";

    try {
      final userRef = _db.child("users").child(user.uid);
      final snap = await userRef.get();
      final userData = snap.value as Map<dynamic, dynamic>?;

      if (userData != null) {
        _userName = userData["name"] ?? "Customer";
        _profileImageUrl = userData["profileImageUrl"] ?? _profileImageUrl;
        _streak = userData["streak"] ?? 0;
        final lastLoginStr = userData["lastLogin"] as String?;

        // --- Streak Calculation Logic ---
        int newStreak = _streak;
        DateTime lastLogin = DateTime.now().subtract(const Duration(days: 2));
        if (lastLoginStr != null) {
          lastLogin = DateTime.parse(lastLoginStr);
        }
        
        final today = DateTime.now();
        // Use DateUtils.dateOnly to ignore time components for date comparison
        final lastLoginDate = DateUtils.dateOnly(lastLogin);
        final todayDate = DateUtils.dateOnly(today);
        final yesterdayDate = DateUtils.dateOnly(today.subtract(const Duration(days: 1)));

        if (lastLoginDate.isAtSameMomentAs(todayDate)) {
          // Logged in today, streak is maintained (no change)
        } else if (lastLoginDate.isAtSameMomentAs(yesterdayDate)) {
          // Logged in yesterday, increment streak
          newStreak = _streak + 1;
        } else {
          // Streak broken (or first login), reset to 1
          newStreak = 1;
        }

        // Update DB if streak changed or this is the first login of the day
        if (newStreak != _streak || !lastLoginDate.isAtSameMomentAs(todayDate)) {
          await userRef.update({
            "lastLogin": today.toIso8601String(),
            "streak": newStreak,
          });
          _streak = newStreak;
        }
      } else {
        // Handle first-time user initialization... (omitted for brevity, see original plan)
        _streak = 1; 
      }
      
      // --- Surveys Taken Count ---
      // Assumes a dedicated node 'user_surveys/{userId}' tracks all surveys taken by the user.
      final surveysSnap = await _db.child("user_surveys/${user.uid}").get();
      if (surveysSnap.exists) {
        final surveyData = surveysSnap.value as Map<dynamic, dynamic>;
        _surveysTaken = surveyData.length;
      }

    } catch (e) {
      print("Error loading profile: $e");
    } finally {
      if(mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Profile", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo,
        actions: [
       
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: NetworkImage(_profileImageUrl),
                    backgroundColor: Colors.indigo.shade100,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _userName,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _email,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 30),
                  
                  // Stats Card
                  Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Your Stats",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo),
                          ),
                          const SizedBox(height: 15),
                          Row(
                            children: [
                              // Day Streak
                              Expanded(
                                child: _buildStatItem(
                                  icon: Icons.local_fire_department,
                                  iconColor: _streak > 0 ? Colors.orange : Colors.grey,
                                  value: "$_streak",
                                  label: "Day Streak",
                                ),
                              ),
                              // Surveys Taken
                              Expanded(
                                child: _buildStatItem(
                                  icon: Icons.assignment_turned_in,
                                  iconColor: Colors.green,
                                  value: "$_surveysTaken",
                                  label: "Surveys Taken",
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  // Other Profile Sections (Simplified)
                
                ],
              ),
            ),
    );
  }
  
  Widget _buildStatItem({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, size: 30, color: iconColor),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    );
  }
}


