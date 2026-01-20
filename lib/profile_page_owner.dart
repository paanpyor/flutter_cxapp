// lib/profile_page_owner.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'app_theme.dart';
import 'custom_button.dart';



class ProfilePageOwner extends StatefulWidget {
  const ProfilePageOwner({super.key});

  @override
  State<ProfilePageOwner> createState() => _ProfilePageOwnerState();
}

class _ProfilePageOwnerState extends State<ProfilePageOwner> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final TextEditingController _nameController = TextEditingController();
  
  bool _loading = true;
  bool _uploadingImage = false;
  String _email = "";
  String _profileImageUrl = "https://cdn-icons-png.flaticon.com/512/3135/3135715.png";

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
    
    setState(() => _uploadingImage = true);

    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;
      final ref = _storage.ref().child("profile_images/$uid.jpg");
      await ref.putFile(File(picked.path));
      final downloadUrl = await ref.getDownloadURL();
      await _db.child("users/$uid/profileImage").set(downloadUrl);
      if (mounted) setState(() => _profileImageUrl = downloadUrl);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error uploading image: $e")));
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  Future<void> _saveProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    
    // Basic validation
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Name cannot be empty")));
      return;
    }

    await _db.child("users/$uid/name").set(_nameController.text.trim());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile updated successfully!")));
    }
  }

  Future<void> _logout() async {
    await _auth.signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("Edit Profile"),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: _logout,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  
                  // Avatar Section
                  GestureDetector(
                    onTap: _uploadProfileImage,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundImage: NetworkImage(_profileImageUrl),
                          backgroundColor: Colors.grey.shade200,
                        ),
                        if (_uploadingImage)
                          const CircularProgressIndicator(color: AppTheme.primary)
                        else
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 24),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text("Tap to change photo", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  const SizedBox(height: 40),

                  // Name Input
                  TextField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: "Full Name",
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Email Input (Read Only)
                  TextField(
                    readOnly: true,
                    controller: TextEditingController(text: _email),
                    decoration: InputDecoration(
                      labelText: "Email Address",
                      prefixIcon: const Icon(Icons.email_outlined),
                      hintText: _email,
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Save Button
                  AppButton(
                    text: "Save Changes",
                    icon: Icons.save,
                    onPressed: _saveProfile,
                  ),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}