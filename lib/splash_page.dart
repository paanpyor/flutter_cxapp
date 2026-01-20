// lib/splash_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'login_page.dart';
import 'dashboard_page.dart';
import 'owner_dashboard_page.dart';
import 'app_theme.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    
    // Setup Animation
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _controller.forward();
    _checkUser();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkUser() async {
    // Wait for animation to start
    await Future.delayed(const Duration(milliseconds: 1500));
    
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
    } else {
      final snap = await FirebaseDatabase.instance.ref("users/${user.uid}/role").get();
      final role = snap.value?.toString() ?? "customer";
      
      if (!mounted) return;
      if (role == "owner") {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const OwnerDashboardPage()));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardPage()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary, // Indigo Background
      body: Center(
        child: FadeTransition(
          opacity: _animation,
          child: ScaleTransition(
            scale: _animation,
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Logo
                Icon(
                  Icons.insights_rounded, 
                  color: Colors.white, 
                  size: 80,
                  shadows: [Shadow(color: Colors.black26, blurRadius: 10)],
                ),
                SizedBox(height: 24),
                Text(
                  "CX Tracker", 
                  style: TextStyle(
                    color: Colors.white, 
                    fontSize: 32, 
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}