// lib/settings_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_cxapp/login_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // ✅ Initialize with safe defaults (no `late`)
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
    }
  }

  Future<void> _changeLanguage(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', lang);
    if (mounted) {
      setState(() => _language = lang);
    }
  }

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // Appearance
                ListTile(
                  leading: const Icon(Icons.dark_mode),
                  title: const Text("Appearance"),
                  subtitle: Text(_isDarkMode ? "Dark mode" : "Light mode"),
                  trailing: Switch(
                    value: _isDarkMode,
                    onChanged: _toggleTheme,
                    activeColor: Colors.indigo,
                  ),
                ),
                const Divider(),

                // Language
                ListTile(
                  leading: const Icon(Icons.language),
                  title: const Text("Language"),
                  subtitle: Text(_language == 'en' ? "English" : "Bahasa Malaysia"),
                  onTap: () {
                    final newLang = _language == 'en' ? 'ms' : 'en';
                    _changeLanguage(newLang);
                  },
                ),
                const Divider(),

                // Logout
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text("Logout", style: TextStyle(color: Colors.red)),
                  onTap: () => _logout(context),
                ),
              ],
            ),
    );
  }
}