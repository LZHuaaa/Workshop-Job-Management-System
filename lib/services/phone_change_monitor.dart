import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class PhoneChangeMonitor {
  static final PhoneChangeMonitor _instance = PhoneChangeMonitor._internal();
  factory PhoneChangeMonitor() => _instance;
  PhoneChangeMonitor._internal();

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  StreamSubscription<DocumentSnapshot>? _userProfileSubscription;
  BuildContext? _context;
  VoidCallback? _onPhoneUpdated;
  String? _originalPhoneNumber;
  bool _isMonitoring = false;

  // Start monitoring for phone number changes
  void startPhoneChangeMonitoring(BuildContext context, String? originalPhoneNumber, VoidCallback onPhoneUpdated) {
    if (_isMonitoring) {
      stopMonitoring();
    }

    _context = context;
    _onPhoneUpdated = onPhoneUpdated;
    _originalPhoneNumber = originalPhoneNumber;
    _isMonitoring = true;

    final user = _firebaseAuth.currentUser;
    if (user == null) return;

    print('📱 Starting phone change monitoring for user: ${user.uid}');
    print('📱 Original phone number: $_originalPhoneNumber');

    // Listen to user profile changes in Firestore
    _userProfileSubscription = _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen(
          _handleUserProfileChange,
          onError: (error) {
            print('❌ Error monitoring phone changes: $error');
          },
        );
  }

  // Handle user profile changes
  void _handleUserProfileChange(DocumentSnapshot snapshot) {
    if (!_isMonitoring || _context == null) return;

    try {
      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>?;
      if (data == null) return;

      final currentPhoneNumber = data['phoneNumber'] as String?;
      
      print('📱 Phone change check: original=$_originalPhoneNumber, current=$currentPhoneNumber');

      // Check if phone number has changed
      if (currentPhoneNumber != _originalPhoneNumber && currentPhoneNumber != null) {
        print('✅ Phone number change detected! New number: $currentPhoneNumber');
        _handlePhoneChangeSuccess(currentPhoneNumber);
      }
    } catch (e) {
      print('❌ Error handling phone profile change: $e');
    }
  }

  // Handle successful phone number change
  void _handlePhoneChangeSuccess(String newPhoneNumber) {
    if (_context == null || !_isMonitoring) return;

    print('🎉 Phone number successfully updated to: $newPhoneNumber');

    // Show success message
    ScaffoldMessenger.of(_context!).showSnackBar(
      SnackBar(
        content: Text(
          'Phone number updated successfully to $newPhoneNumber',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        backgroundColor: AppColors.successGreen,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(_context!).hideCurrentSnackBar();
          },
        ),
      ),
    );

    // Trigger UI refresh
    if (_onPhoneUpdated != null) {
      _onPhoneUpdated!();
    }

    // Stop monitoring after successful change
    stopMonitoring();
  }

  // Stop monitoring
  void stopMonitoring() {
    if (!_isMonitoring) return;

    print('📱 Stopping phone change monitoring');
    
    _userProfileSubscription?.cancel();
    _userProfileSubscription = null;
    _context = null;
    _onPhoneUpdated = null;
    _originalPhoneNumber = null;
    _isMonitoring = false;
  }

  // Check if currently monitoring
  bool get isMonitoring => _isMonitoring;

  // Get current monitoring status
  String? get originalPhoneNumber => _originalPhoneNumber;
}
