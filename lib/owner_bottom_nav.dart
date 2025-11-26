// lib/owner_bottom_nav.dart
import 'package:flutter/material.dart';
import 'package:flutter_cxapp/owner_dashboard_page.dart';
import 'package:flutter_cxapp/near_me_page.dart';
import 'package:flutter_cxapp/profile_page_owner.dart';
import 'package:flutter_cxapp/settings_page.dart';
import 'package:flutter_cxapp/add_restaurant_page.dart';

class OwnerBottomNav extends StatefulWidget {
  const OwnerBottomNav({super.key});

  @override
  State<OwnerBottomNav> createState() => _OwnerBottomNavState();
}

class _OwnerBottomNavState extends State<OwnerBottomNav> {
  int _currentIndex = 0;

  static const List<Widget> _pages = [
    OwnerDashboardPage(),
    NearMePage(),
    ProfilePageOwner(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
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
              const SizedBox(width: 40), // Space for FAB
              _buildNavItem(Icons.person, "Profile", 2),
              _buildNavItem(Icons.settings, "Settings", 3),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddRestaurantPage()),
          );
          // Optionally: refresh dashboard if needed
        },
        backgroundColor: Colors.indigo, // or Color(0xFFE53935)
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