import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'signup_page.dart';
import 'dashboard_page.dart';
import 'owner_dashboard_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;

  Future<void> _login() async {
    setState(() => _loading = true);
    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      final uid = cred.user!.uid;
      final snap = await FirebaseDatabase.instance.ref("users/$uid/role").get();
      final role = snap.value.toString();
      if (!mounted) return;
      if (role == "owner") {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const OwnerDashboardPage()));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardPage()));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Login Failed: ${e.toString()}")));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F46E5).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_open_rounded, size: 48, color: Color(0xFF4F46E5)),
                ),
              ),
              const SizedBox(height: 24),
              const Text("Welcome Back", textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black)),
              const SizedBox(height: 8),
              const Text("Sign in to continue", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 40),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: "Email",
                  prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF4F46E5)),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Password",
                  prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF4F46E5)),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Sign In", style: TextStyle(fontSize: 17, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupPage())),
                child: const Text("Don’t have an account? Sign up"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}