import 'package:flutter/material.dart';
import 'login_page.dart';


class ProfilePage extends StatelessWidget {
  final String username;
  final String role;

  const ProfilePage({super.key, required this.username, required this.role});

  void _logout(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Logout",
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          elevation: 8,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.indigo,
                  child: Icon(Icons.person, color: Colors.white, size: 50),
                ),
                const SizedBox(height: 20),
                Text(username,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(role,
                    style: TextStyle(
                        fontSize: 16,
                        color: role == "owner"
                            ? Colors.indigo
                            : Colors.green.shade700)),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.logout),
                  label: const Text("Logout"),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10))),
                  onPressed: () => _logout(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
