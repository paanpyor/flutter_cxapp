import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_cxapp/image_upload_service.dart';

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
          "https://cdn-icons-png.flaticon.com/512/857/857681.png";

      if (_pickedImage != null) {
        final uploadedUrl =
            await ImgbbService.uploadImage(File(_pickedImage!.path));
        if (uploadedUrl != null) {
          imageUrl = uploadedUrl;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to upload image.")),
          );
        }
      }

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
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xfff8f9fa), Color(0xffedf2ff)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: const Text("Add Restaurant", style: TextStyle(color: Colors.indigo)),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.indigo),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Restaurant Details",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Restaurant Name
                    const Text(
                      "Restaurant Name",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.indigo),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.indigo, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Location Name
                    const Text(
                      "Location Name",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.indigo),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _locationController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.indigo, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Image Upload
                    const Text(
                      "Restaurant Image",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.indigo),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Column(
                        children: [
                          ElevatedButton.icon(
                            onPressed: _isSaving ? null : _pickImage,
                            icon: const Icon(Icons.image, size: 20),
                            label: const Text ("Choose Image",style: TextStyle (color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isSaving ? Colors.grey : Colors.indigo,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (_pickedImage != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.file(
                                File(_pickedImage!.path),
                                width: 180,
                                height: 140,
                                fit: BoxFit.cover,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Map Picker
                    const Text(
                      "Select Location on Map",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.indigo),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 260,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: FlutterMap(
                          options: MapOptions(
                            initialCenter: const LatLng(3.139, 101.6869),
                            initialZoom: 13,
                            onTap: _isSaving ? null : (tapPosition, point) {
                              setState(() => _selectedLatLng = point);
                            },
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                              userAgentPackageName: 'com.example.app.flutter_cxapp',
                            ),
                            if (_selectedLatLng != null)
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: _selectedLatLng!,
                                    width: 50,
                                    height: 50,
                                    child: const Icon(
                                      Icons.location_pin,
                                      color: Colors.redAccent,
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
                          ? "${_locationController.text.isEmpty ? 'Location' : _locationController.text}\n(${_selectedLatLng!.latitude.toStringAsFixed(5)}, ${_selectedLatLng!.longitude.toStringAsFixed(5)})"
                          : "Tap on the map to select a location",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: _selectedLatLng != null ? Colors.green : Colors.grey,
                        fontWeight: _selectedLatLng != null ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveRestaurant,
                        icon: _isSaving
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                            : const Icon(Icons.save, size: 20),
                        label: Text(_isSaving ? "Saving..." : "Save Restaurant", style: const TextStyle(fontSize: 16, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isSaving ? Colors.grey : Colors.indigo,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}