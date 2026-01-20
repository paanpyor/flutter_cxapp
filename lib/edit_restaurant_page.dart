import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart'; 
import 'package:flutter_cxapp/image_upload_service.dart';
import 'app_theme.dart';

class EditRestaurantPage extends StatefulWidget {
  final String restaurantId;

  const EditRestaurantPage({super.key, required this.restaurantId});

  @override
  State<EditRestaurantPage> createState() => _EditRestaurantPageState();
}

class _EditRestaurantPageState extends State<EditRestaurantPage> {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseDatabase.instance.ref();
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final MapController _mapController = MapController();

  XFile? _pickedImage;
  LatLng? _selectedLatLng;
  
  // Holds the existing image URL so we don't lose it if user doesn't upload a new one
  String? _currentImageUrl; 

  bool _isSaving = false;
  bool _isLocating = false;
  bool _isLoadingData = true; // Loading state when fetching existing data

  @override
  void initState() {
    super.initState();
    _loadRestaurantData();
  }

  // --- 1. LOAD EXISTING DATA ---
  Future<void> _loadRestaurantData() async {
    try {
      final snap = await _db.child("restaurants/${widget.restaurantId}").get();
      if (snap.exists && snap.value != null) {
        final data = Map<String, dynamic>.from(snap.value as Map);
        
        setState(() {
          _nameController.text = data["name"] ?? "";
          _locationController.text = data["location"] ?? "";
          _currentImageUrl = data["imageUrl"];
          
          // Load Map Location
          if (data["latitude"] != null && data["longitude"] != null) {
            _selectedLatLng = LatLng(data["latitude"], data["longitude"]);
            // Move map after UI is built
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _mapController.move(_selectedLatLng!, 15.0);
            });
          }
          _isLoadingData = false;
        });
      }
    } catch (e) {
      print("Error loading restaurant: $e");
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  // --- 2. IMAGE PICKING ---
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

  // --- 3. LOCATION HANDLING ---
  Future<void> _getCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
          throw Exception("Location permissions are required.");
        }
      }
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final newLatLng = LatLng(position.latitude, position.longitude);

      setState(() {
        _selectedLatLng = newLatLng;
        _locationController.text = "Current Location (Tap to refine)";
      });
      
      _mapController.move(newLatLng, 15.0); 
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching location: ${e.toString()}")),
      );
    } finally {
      setState(() => _isLocating = false);
    }
  }

  // --- 4. SAVE FUNCTION (UPDATE) ---
  Future<void> _updateRestaurant() async {
    if (!_formKey.currentState!.validate() || _selectedLatLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all required fields and select a location."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final uid = _auth.currentUser!.uid;
      
      // Logic: Use existing image if no new one picked, otherwise upload new one
      String imageUrl = _currentImageUrl ?? "https://cdn-icons-png.flaticon.com/512/857/857681.png";

      if (_pickedImage != null) {
        final uploadedUrl = await ImgbbService.uploadImage(File(_pickedImage!.path));
        if (uploadedUrl != null) {
          imageUrl = uploadedUrl;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Image upload failed, keeping existing image.")),
          );
        }
      }

      // --- UPDATE SPECIFIC NODE ---
      await _db.child("restaurants/${widget.restaurantId}").update({
        "name": _nameController.text.trim(),
        "location": _locationController.text.trim(),
        "latitude": _selectedLatLng!.latitude,
        "longitude": _selectedLatLng!.longitude,
        "imageUrl": imageUrl,
        "ownerId": uid,
        "updatedAt": ServerValue.timestamp,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Restaurant updated successfully!"), backgroundColor: Colors.green),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update restaurant: $e"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  // --- BUILD WIDGETS ---

  Widget _buildTextField(TextEditingController controller, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF303F9F))),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.grey)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.indigo, width: 2)),
            errorStyle: const TextStyle(color: Colors.red),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return '$label is required.';
            return null;
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildMapPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Select Location on Map", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF303F9F))),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: (_isSaving || _isLocating) ? null : _getCurrentLocation,
            icon: _isLocating ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.my_location, size: 20),
            label: Text(_isLocating ? "Acquiring Location..." : "Use Current Location"),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blueGrey,
              side: const BorderSide(color: Colors.blueGrey),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 260,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _selectedLatLng != null ? Colors.green : Colors.grey.shade300, width: 2),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _selectedLatLng ?? const LatLng(3.139, 101.6869),
                initialZoom: 13,
                onTap: _isSaving ? null : (tapPosition, point) {
                  setState(() => _selectedLatLng = point);
                },
              ),
              children: [
                TileLayer(urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png", userAgentPackageName: 'com.example.app.flutter_cxapp'),
                if (_selectedLatLng != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _selectedLatLng!,
                        width: 50,
                        height: 50,
                        child: Icon(Icons.location_pin, color: _selectedLatLng != null ? Colors.redAccent : Colors.grey, size: 40),
                      )
                    ],
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: Text(
            _selectedLatLng != null ? "Location Selected: Lat ${_selectedLatLng!.latitude.toStringAsFixed(5)}, Lon ${_selectedLatLng!.longitude.toStringAsFixed(5)}" : "Tap on the map above to set the exact restaurant location.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: _selectedLatLng != null ? Colors.green.shade700 : Colors.grey.shade700, fontWeight: _selectedLatLng != null ? FontWeight.bold : FontWeight.normal),
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xfff8f9fa), Color(0xffedf2ff)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        ),
        child: Column(
          children: [
            AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: const Text("Edit Restaurant", style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
              centerTitle: true,
              leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.indigo), onPressed: () => Navigator.pop(context)),
            ),
            Expanded(
              child: _isLoadingData 
                ? const Center(child: CircularProgressIndicator(color: Colors.indigo))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- Image Upload Section ---
                          _buildImageUploadSection(),
                          const SizedBox(height: 24),
                          
                          // --- Text Fields ---
                          const Text("Restaurant Details", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF303F9F))),
                          const SizedBox(height: 16),
                          _buildTextField(_nameController, "Restaurant Name"),
                          _buildTextField(_locationController, "Location/Address Nickname"),

                          // --- Map Picker Section ---
                          _buildMapPicker(),

                          // --- Save Button ---
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isSaving ? null : _updateRestaurant,
                              icon: _isSaving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.check_circle, size: 20),
                              label: Text(_isSaving ? "Updating..." : "Update Restaurant", style: const TextStyle(fontSize: 18, color: Colors.white)),
                              style: ElevatedButton.styleFrom(backgroundColor: _isSaving ? Colors.grey : Colors.indigo, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 8),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Restaurant Image (Optional)", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF303F9F))),
        const SizedBox(height: 12),
        Center(
          child: GestureDetector(
            onTap: _isSaving ? null : _pickImage,
            child: Container(
              width: 200,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _pickedImage != null ? Colors.green : Colors.grey.shade300, width: 2),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: _pickedImage != null
                  ? ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.file(File(_pickedImage!.path), fit: BoxFit.cover))
                  // If no new image picked, show the existing network image
                  : (_currentImageUrl != null && _currentImageUrl!.isNotEmpty)
                      ? ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.network(_currentImageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 50)))
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt, color: Colors.indigo, size: 40),
                            SizedBox(height: 8),
                            Text("Tap to Select Image", style: TextStyle(color: Colors.indigo)),
                          ],
                        ),
            ),
          ),
        ),
      ],
    );
  }
}