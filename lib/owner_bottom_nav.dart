// lib/owner_bottom_nav.dart
import 'package:flutter/material.dart';
import 'owner_dashboard_page.dart';
import 'near_me_page.dart';
import 'profile_page_owner.dart';
import 'settings_page.dart';
import 'add_restaurant_page.dart';
import 'app_theme.dart';

class OwnerBottomNav extends StatefulWidget {
  const OwnerBottomNav({super.key});

  @override
  State<OwnerBottomNav> createState() => _OwnerBottomNavState();
}

class _OwnerBottomNavState extends State<OwnerBottomNav> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const OwnerDashboardPage(),
    const NearMePage(),
    const ProfilePageOwner(),
    const SettingsPage(),
  ];

  void _onPageTapped(int index) {
    setState(() {
      _currentIndex = index;
    });

    // If user tapped Dashboard, ensure data is refreshed
    // Note: This is a simple example. In a real app, 
    // you might use a GlobalKey to call a refresh method on DashboardPage.
    if (index == 0) {
       // Logic to refresh Dashboard can go here
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddRestaurantPage()),
          );
          // Optional: Force refresh after adding restaurant
          if (mounted) {
             // If you passed a key to OwnerDashboardPage, you could use it here
          }
        },
        backgroundColor: AppTheme.primary,
        elevation: 8,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        height: 65,
        elevation: 10,
        color: Colors.white,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left Side
            _buildNavItem(Icons.dashboard_rounded, "Dashboard", 0),
            _buildNavItem(Icons.location_on_rounded, "Near Me", 1),
            
            // Spacer for FAB
            const SizedBox(width: 48),
            
            // Right Side
            _buildNavItem(Icons.person_rounded, "Profile", 2),
            _buildNavItem(Icons.settings_rounded, "Settings", 3),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => _onPageTapped(index),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? AppTheme.primary : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isActive ? AppTheme.primary : Colors.grey,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}