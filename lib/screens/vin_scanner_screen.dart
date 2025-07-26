import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/app_colors.dart';

class VINScannerScreen extends StatefulWidget {
  final Function(String) onVINScanned;

  const VINScannerScreen({
    super.key,
    required this.onVINScanned,
  });

  @override
  State<VINScannerScreen> createState() => _VINScannerScreenState();
}

class _VINScannerScreenState extends State<VINScannerScreen> {
  MobileScannerController controller = MobileScannerController();
  bool _isScanning = true;
  bool _flashOn = false;
  String? _scannedVIN;

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
  }

  Future<void> _requestCameraPermission() async {
    try {
      final status = await Permission.camera.request();
      if (status.isDenied && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Camera permission is required to scan VIN codes',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppColors.errorRed,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        print('Camera permission request failed: $e');
      }
    }
  }

  @override
  void dispose() {
    try {
      controller.dispose();
    } catch (e) {
      // Handle disposal errors gracefully
      print('Scanner controller disposal error: $e');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          'Scan VIN Code',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _flashOn ? Icons.flash_on : Icons.flash_off,
              color: Colors.white,
            ),
            onPressed: _toggleFlash,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: Stack(
              children: [
                MobileScanner(
                  controller: controller,
                  onDetect: _onDetect,
                ),
                if (_scannedVIN != null)
                  Positioned(
                    top: 20,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.successGreen,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'VIN Detected: $_scannedVIN',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.black,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Position the VIN code within the frame',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'VIN codes are typically 17 characters long',
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _isScanning ? _pauseScanning : _resumeScanning,
                        icon: Icon(_isScanning ? Icons.pause : Icons.play_arrow),
                        label: Text(_isScanning ? 'Pause' : 'Resume'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryPink,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _enterManually,
                        icon: const Icon(Icons.keyboard),
                        label: const Text('Enter Manually'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.textSecondary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onDetect(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    if (_isScanning && barcodes.isNotEmpty) {
      final scannedText = barcodes.first.rawValue ?? '';
      if (_isValidVIN(scannedText)) {
        setState(() {
          _scannedVIN = scannedText;
          _isScanning = false;
        });
        _confirmVIN(scannedText);
      }
    }
  }

  bool _isValidVIN(String vin) {
    // Basic VIN validation - 17 characters, alphanumeric (excluding I, O, Q)
    if (vin.length != 17) return false;
    final vinRegex = RegExp(r'^[A-HJ-NPR-Z0-9]{17}$');
    return vinRegex.hasMatch(vin.toUpperCase());
  }

  void _confirmVIN(String vin) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'VIN Detected',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Scanned VIN:',
              style: GoogleFonts.poppins(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                vin,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Is this correct?',
              style: GoogleFonts.poppins(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resumeScanning();
            },
            child: Text(
              'Scan Again',
              style: GoogleFonts.poppins(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onVINScanned(vin);
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPink,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Use This VIN',
              style: GoogleFonts.poppins(),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleFlash() async {
    try {
      await controller.toggleTorch();
      if (mounted) {
        setState(() {
          _flashOn = !_flashOn;
        });
      }
    } catch (e) {
      print('Flash toggle error: $e');
    }
  }

  void _pauseScanning() {
    try {
      controller.stop();
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    } catch (e) {
      print('Scanner pause error: $e');
    }
  }

  void _resumeScanning() {
    try {
      controller.start();
      if (mounted) {
        setState(() {
          _isScanning = true;
          _scannedVIN = null;
        });
      }
    } catch (e) {
      print('Scanner resume error: $e');
    }
  }

  void _enterManually() {
    final TextEditingController vinController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Enter VIN Manually',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: vinController,
              decoration: InputDecoration(
                labelText: 'VIN (17 characters)',
                hintText: 'Enter vehicle VIN code',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              textCapitalization: TextCapitalization.characters,
              maxLength: 17,
            ),
            const SizedBox(height: 8),
            Text(
              'VIN should be exactly 17 characters',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final vin = vinController.text.trim().toUpperCase();
              if (_isValidVIN(vin)) {
                Navigator.of(context).pop();
                widget.onVINScanned(vin);
                Navigator.of(context).pop();
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Please enter a valid 17-character VIN',
                        style: GoogleFonts.poppins(),
                      ),
                      backgroundColor: AppColors.errorRed,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPink,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Use VIN',
              style: GoogleFonts.poppins(),
            ),
          ),
        ],
      ),
    );
  }


}
