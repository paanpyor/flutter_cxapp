import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'survey_type_page.dart';


// 1. Define the StatefulWidget
class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
} 

// 2. Define the State
class _QRScannerPageState extends State<QRScannerPage> {
  // 3. Define necessary state/objects
  late MobileScannerController _cameraController;
  bool _isScanning = true; // State to control the scan process

  @override
  void initState() {
    super.initState();
    _cameraController = MobileScannerController(
      // Configuration can go here
    );
  }

  // 4. The corrected function definition, now inside the State class
  void _parseScanResult(String rawValue) {
    // Stop the camera right after a scan is received to prevent multiple events
    _cameraController.stop(); 
    setState(() => _isScanning = false); // Update state

    final Uri? uri = Uri.tryParse(rawValue);
    
    // Use widget.context if you are calling it from a different part of the State class,
    // but typically just 'context' is available here.
    if (uri != null &&
        uri.scheme.toLowerCase() == 'cxapp' &&
        uri.host == 'survey' &&
        uri.queryParameters.containsKey('restaurantId')) {
      final restaurantId = uri.queryParameters['restaurantId']!;
      
      // Accessing context directly is fine inside the State class
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => SurveyTypePage(restaurantId: restaurantId),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Invalid QR: Must be 'cxapp://survey?restaurantId=...'"),
          backgroundColor: Colors.red,
        ),
      );
      
      // Delay before restarting scan
      Future.delayed(const Duration(seconds: 2), () {
        // setState is available here!
        setState(() => _isScanning = true);
        _cameraController.start();
      });
    }
  }

  // 5. Build method where the MobileScanner widget is used
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QR Scanner')),
      body: MobileScanner(
        controller: _cameraController,
        // The onDetect callback will provide the scan result
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          if (barcodes.isNotEmpty && _isScanning) {
            // Check _isScanning state to process only one scan
            final String? rawValue = barcodes.first.rawValue;
            if (rawValue != null) {
              _parseScanResult(rawValue);
            }
          }
        },
      ),
    );
  }
  
  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }
}