import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:get/get.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  String barcode = 'Scan a QR code';
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          automaticallyImplyLeading: false,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue, Colors.pink],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: AppBar(
              centerTitle: true,
              backgroundColor: Colors.transparent.withOpacity(0.20),
              elevation: 50,
              title: const Text(
                'Scan Bus Code',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  Get.back();
                },
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: MobileScanner(
              controller: controller,
              onDetect: (BarcodeCapture capture) {
                final List<Barcode> barcodes = capture.barcodes;
                if (barcodes.isNotEmpty) {
                  final String? scannedValue = barcodes.first.rawValue;
                  debugPrint("Barcode scanned: $scannedValue");

                  // Update UI with scanned data
                  setState(() {
                    barcode = scannedValue ?? 'Failed to scan';
                  });

                  // Show scanned result as a Snackbar
                  if (scannedValue != null && scannedValue.isNotEmpty) {
                    Get.snackbar(
                      'QR Code Scanned',
                      'Bus code: $scannedValue',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.green,
                      colorText: Colors.white,
                      duration: const Duration(seconds: 3),
                    );
                  }
                }
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Scan Result:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      barcode,
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
