import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'login_page.dart';
import 'dashboard_page.dart';
import 'owner_dashboard_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkUser();
  }

  Future<void> _checkUser() async {
    await Future.delayed(const Duration(seconds: 2));
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
      backgroundColor: const Color(0xFF4F46E5),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.insights_rounded, color: Colors.white, size: 80),
            const SizedBox(height: 20),
            Text("CX Tracker", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}