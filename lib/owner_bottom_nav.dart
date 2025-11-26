// lib/bottom_nav/owner_bottom_nav.dart
import 'package:flutter/material.dart';
import 'package:flutter_cxapp/owner_dashboard_page.dart';
import 'package:flutter_cxapp/near_me_page.dart';
import 'package:flutter_cxapp/profile_page_owner.dart';
import 'package:flutter_cxapp/settings_page.dart';

class OwnerBottomNav extends StatefulWidget {
  const OwnerBottomNav({super.key});

  @override
  State<OwnerBottomNav> createState() => _OwnerBottomNavState();
}

class _OwnerBottomNavState extends State<OwnerBottomNav> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const OwnerDashboardPage(), // index 0
    const NearMePage(),         // index 1 (optional for owner)
    const ProfilePageOwner(),   // index 2
    const SettingsPage(),       // index 3
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Dashboard"),
          BottomNavigationBarItem(icon: Icon(Icons.location_on), label: "Near Me"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
        ],
      ),
    );
  }
}