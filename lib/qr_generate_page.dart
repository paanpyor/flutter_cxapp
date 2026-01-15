// lib/qr_generator_page.dart
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrGeneratorPage extends StatelessWidget {
  final String restaurantId;
  final String restaurantName;
  const QrGeneratorPage({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
  });

  String get _qrData => "cxapp://survey?restaurantId=$restaurantId";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Generate Survey QR', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.indigo,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text("QR for: $restaurantName", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo)),
            const SizedBox(height: 10),
            const Text("Customers scan this to start a survey.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),

            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
              ),
              child: QrImageView(
                data: _qrData,
                version: QrVersions.auto,
                size: 250.0,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(color: Colors.indigo),
                dataModuleStyle: const QrDataModuleStyle(color: Colors.black),
              ),
            ),

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("QR saved to gallery!")));
                },
                icon: const Icon(Icons.file_download),
                label: const Text("Save QR Image"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}