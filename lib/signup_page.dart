import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_cxapp/login_page.dart';


class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseDatabase.instance.ref();

  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  String _role = 'customer';
  bool _loading = false;

  Future<void> _signup() async {
    if (_email.text.isEmpty || _password.text.isEmpty || _name.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    setState(() => _loading = true);

    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text.trim(),
      );

      final uid = cred.user!.uid;
      await _db.child("users/$uid").set({
        "name": _name.text.trim(),
        "email": _email.text.trim(),
        "role": _role,
        "createdAt": ServerValue.timestamp,
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Account created!")));

    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sign Up"), backgroundColor: Colors.indigo),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            TextField(controller: _name, decoration: const InputDecoration(labelText: "Full Name")),
            const SizedBox(height: 10),
            TextField(controller: _email, decoration: const InputDecoration(labelText: "Email")),
            const SizedBox(height: 10),
            TextField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: "Password")),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _role,
              decoration: const InputDecoration(labelText: "Select Role"),
              items: const [
                DropdownMenuItem(value: "customer", child: Text("Customer")),
                DropdownMenuItem(value: "owner", child: Text("Restaurant Owner")),
              ],
              onChanged: (v) => setState(() => _role = v!),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _signup,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("SIGN UP", style: TextStyle(fontSize: 18)),
            ),
            TextButton(
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              ),child: const Text("Already have an account? Login"),
            )
          ],
        ),
      ),
    );
  }
}
