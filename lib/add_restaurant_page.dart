import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_cxapp/image_upload_service.dart'; // ✅ Added Imgbb API service

class AddRestaurantPage extends StatefulWidget {
  const AddRestaurantPage({super.key});

  @override
  State<AddRestaurantPage> createState() => _AddRestaurantPageState();
}

class _AddRestaurantPageState extends State<AddRestaurantPage> {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseDatabase.instance.ref();

  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  XFile? _pickedImage;
  LatLng? _selectedLatLng;

  bool _isSaving = false;

  // 🔹 Pick image from gallery
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (img != null) {
      setState(() => _pickedImage = img);
    }
  }

  // 🔹 Save restaurant info
  Future<void> _saveRestaurant() async {
    if (_nameController.text.isEmpty ||
        _locationController.text.isEmpty ||
        _selectedLatLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all fields and select a location."),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final uid = _auth.currentUser!.uid;
      String imageUrl =
          "https://cdn-icons-png.flaticon.com/512/857/857681.png"; // default image

      // ✅ Upload to Imgbb if image selected
      if (_pickedImage != null) {
        final uploadedUrl =
            await ImgbbService.uploadImage(File(_pickedImage!.path));
        if (uploadedUrl != null) {
          imageUrl = uploadedUrl;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to upload image to Imgbb.")),
          );
        }
      }

      // ✅ Save restaurant info in Firebase Realtime Database
      final restaurantRef = _db.child("restaurants").push();
      await restaurantRef.set({
        "name": _nameController.text.trim(),
        "location": _locationController.text.trim(),
        "latitude": _selectedLatLng!.latitude,
        "longitude": _selectedLatLng!.longitude,
        "imageUrl": imageUrl,
        "ownerId": uid,
        "createdAt": ServerValue.timestamp,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Restaurant added successfully!")),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save restaurant: $e")),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Restaurant"),
        backgroundColor: Colors.indigo,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Restaurant name
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Restaurant Name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // 🔹 Location name
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: "Location Name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // 🔹 Image Picker
            Center(
              child: Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.image),
                    label: const Text("Upload Image"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_pickedImage != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(_pickedImage!.path),
                        width: 200,
                        height: 150,
                        fit: BoxFit.cover,
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // 🔹 Map Picker
            const Text(
              "Select Restaurant Location:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Container(
              height: 250,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: const LatLng(3.139, 101.6869), // Kuala Lumpur
                    initialZoom: 13,
                    onTap: (tapPosition, point) {
                      setState(() => _selectedLatLng = point);
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                    ),
                    if (_selectedLatLng != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _selectedLatLng!,
                            width: 60,
                            height: 60,
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 40,
                            ),
                          )
                        ],
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),
            Text(
              _selectedLatLng != null
                  ? "Selected: ${_selectedLatLng!.latitude.toStringAsFixed(5)}, "
                      "${_selectedLatLng!.longitude.toStringAsFixed(5)}"
                  : "No location selected yet",
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 25),

            // 🔹 Save button
            Center(
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveRestaurant,
                icon: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Icon(Icons.save),
                label: Text(_isSaving ? "Saving..." : "Save Restaurant"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 40, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
