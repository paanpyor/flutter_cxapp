// lib/customer_bottom_nav.dart
import 'package:flutter/material.dart';
import 'package:flutter_cxapp/dashboard_page.dart';
import 'package:flutter_cxapp/near_me_page.dart';
import 'package:flutter_cxapp/profile_page_customer.dart';
import 'package:flutter_cxapp/settings_page.dart';

class CustomerBottomNav extends StatefulWidget {
  const CustomerBottomNav({super.key});

  @override
  State<CustomerBottomNav> createState() => _CustomerBottomNavState();
}

class _CustomerBottomNavState extends State<CustomerBottomNav> {
  int _currentIndex = 0;

  static const List<Widget> _pages = [
    DashboardPage(),   // No const—some pages may need rebuilds
    NearMePage(),
    ProfilePageCustomer(),
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
              _buildNavItem(Icons.home, "Home", 0),
              _buildNavItem(Icons.location_on, "Near Me", 1),
              const SizedBox(width: 40), // Space for FAB
              _buildNavItem(Icons.person, "Profile", 2),
              _buildNavItem(Icons.settings, "Settings", 3),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Optional: Open quick survey or mood check
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Quick feedback coming soon!")),
          );
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