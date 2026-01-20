// lib/settings_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';
import 'app_theme.dart';
import 'common_widget.dart'; // Import for AppCard

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isDarkMode = false;
  String _language = 'en';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final isDarkMode = prefs.getBool('isDarkMode') ?? false;
    final language = prefs.getString('language') ?? 'en';

    if (mounted) {
      setState(() {
        _isDarkMode = isDarkMode;
        _language = language;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleTheme(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', value);
    if (mounted) {
      setState(() => _isDarkMode = value);
      // Note: You would need to wrap your MaterialApp with 
      // ValueListenableBuilder or Provider to actually update theme 
      // immediately across the whole app. For now, this saves preference.
    }
  }

  Future<void> _changeLanguage() async {
    final newLang = _language == 'en' ? 'ms' : 'en';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', newLang);
    if (mounted) {
      setState(() => _language = newLang);
    }
  }

  Future<void> _logout(BuildContext context) async {
    // Confirmation Dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Log Out", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Are you sure you want to sign out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Log Out"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primary,
        elevation: 0,
        centerTitle: true,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text("Preferences", style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),

                  // Appearance Card
                  AppCard(
                    child: Column(
                      children: [
                        // Dark Mode Toggle
                        SwitchListTile(
                          secondary: Icon(
                            _isDarkMode ? Icons.dark_mode : Icons.light_mode,
                            color: AppTheme.primary,
                          ),
                          title: const Text("Dark Mode"),
                          subtitle: const Text("Switch to dark theme"),
                          value: _isDarkMode,
                          onChanged: _toggleTheme,
                          contentPadding: EdgeInsets.zero,
                        ),
                        const Divider(height: 1),
                        // Language Toggle
                        ListTile(
                          leading: const Icon(Icons.language, color: AppTheme.primary),
                          title: const Text("Language"),
                          subtitle: Text(_language == 'en' ? "English" : "Bahasa Malaysia"),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: _changeLanguage,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),

                  // Account Header
                  Text("Account", style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),

                  // Logout Card
                  AppCard(
                    color: Colors.red.withOpacity(0.05),
                    child: ListTile(
                      leading: const Icon(Icons.logout, color: Colors.red),
                      title: const Text("Log Out", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      subtitle: const Text("Sign out of your account"),
                      onTap: () => _logout(context),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Version Info
                  Center(
                    child: Text(
                      "Version 0.1.0",
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}