import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_cxapp/login_page.dart';

class ProfilePageCustomer extends StatefulWidget {
  const ProfilePageCustomer({super.key});

  @override
  State<ProfilePageCustomer> createState() => _ProfilePageCustomerState();
}

class _ProfilePageCustomerState extends State<ProfilePageCustomer> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  final TextEditingController _nameController = TextEditingController();

  bool _loading = true;
  String _email = "";
  String _role = "customer";
  String _profileImageUrl =
      "https://cdn-icons-png.flaticon.com/512/3135/3135715.png";

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final snap = await _db.child("users/$uid").get();
    if (snap.exists) {
      final data = Map<String, dynamic>.from(snap.value as Map);
      setState(() {
        _nameController.text = data["name"] ?? "";
        _email = data["email"] ?? "";
        _role = data["role"] ?? "customer";
        _profileImageUrl = data["profileImage"] ?? _profileImageUrl;
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _uploadProfileImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked == null) return;

    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final ref = _storage.ref().child("profile_images/$uid.jpg");
    await ref.putFile(File(picked.path));
    final downloadUrl = await ref.getDownloadURL();

    await _db.child("users/$uid/profileImage").set(downloadUrl);

    setState(() => _profileImageUrl = downloadUrl);
  }

  Future<void> _saveProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _db.child("users/$uid/name").set(_nameController.text);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Profile updated successfully")),
    );
  }

  Future<void> _logout() async {
    await _auth.signOut();
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
      backgroundColor: const Color(0xfff8f9fa),
      appBar: AppBar(
        title: const Text("My Profile"),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _uploadProfileImage,
                    child: CircleAvatar(
                      radius: 60,
                      backgroundImage: NetworkImage(_profileImageUrl),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text("Tap image to change",
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: "Full Name",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: "Email",
                      border: const OutlineInputBorder(),
                      hintText: _email,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: "Role",
                      border: const OutlineInputBorder(),
                      hintText: _role,
                    ),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    onPressed: _saveProfile,
                    label: const Text("Save Changes"),
                  ),
                ],
              ),
            ),
    );
  }
}
