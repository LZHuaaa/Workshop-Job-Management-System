import 'dart:async';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class PhoneVerificationService {
  static final PhoneVerificationService _instance = PhoneVerificationService._internal();
  factory PhoneVerificationService() => _instance;
  PhoneVerificationService._internal();

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Send verification email for phone number change
  Future<void> sendPhoneVerificationEmail(String userEmail, String newPhoneNumber, String userId) async {
    try {
      print('🚀 PHONE VERIFICATION: Starting verification process...');
      print('📧 PHONE VERIFICATION: User email: $userEmail');
      print('📱 PHONE VERIFICATION: New phone number: $newPhoneNumber');
      print('👤 PHONE VERIFICATION: User ID: $userId');

      // Generate a secure verification token
      final verificationToken = _generateVerificationToken();
      final expirationTime = DateTime.now().add(const Duration(hours: 24));

      print('🔑 PHONE VERIFICATION: Generated token: $verificationToken');

      // Store verification data in Firestore
      print('💾 PHONE VERIFICATION: Storing verification data in Firestore...');
      await _firestore.collection('phoneVerifications').doc(userId).set({
        'userId': userId,
        'userEmail': userEmail,
        'newPhoneNumber': newPhoneNumber,
        'verificationToken': verificationToken,
        'expiresAt': Timestamp.fromDate(expirationTime),
        'createdAt': FieldValue.serverTimestamp(),
        'verified': false,
        'verificationUrl': _generateVerificationUrl(verificationToken, userId),
      });

      print('✅ PHONE VERIFICATION: Verification data stored successfully');

      // In a real app, you would send an actual email here using a service like SendGrid, AWS SES, etc.
      // For demo purposes, we'll show a dialog with the verification link
      print('📧 PHONE VERIFICATION: Email would be sent to: $userEmail');
      print('🔗 PHONE VERIFICATION: Verification URL: ${_generateVerificationUrl(verificationToken, userId)}');
      print('⏰ PHONE VERIFICATION: Will auto-verify in 5 seconds...');

      // For demo: simulate clicking the verification link after 5 seconds
      Timer(const Duration(seconds: 5), () async {
        print('🔗 PHONE VERIFICATION: Simulating verification link click...');
        await _simulateVerificationLinkClick(verificationToken, userId);
      });

    } catch (e) {
      print('❌ PHONE VERIFICATION ERROR: Failed to send verification email: $e');
      print('❌ PHONE VERIFICATION ERROR: Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  // Generate a secure verification token
  String _generateVerificationToken() {
    final random = Random.secure();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomBytes = List.generate(16, (i) => random.nextInt(256));
    final tokenData = '$timestamp${randomBytes.join('')}';
    return 'phone_verify_${tokenData.hashCode.abs()}';
  }

  // Generate verification URL (in production, this would be your app's deep link or web URL)
  String _generateVerificationUrl(String token, String userId) {
    return 'https://yourapp.com/verify-phone?token=$token&userId=$userId';
  }

  // Simulate clicking the verification link (in production, this would be triggered by the actual link)
  Future<void> _simulateVerificationLinkClick(String token, String userId) async {
    try {
      print('🔗 PHONE VERIFICATION: Simulating verification link click...');
      final success = await verifyPhoneNumber(token, userId);
      if (success) {
        print('✅ PHONE VERIFICATION: Link simulation successful');
      } else {
        print('❌ PHONE VERIFICATION: Link simulation failed');
      }
    } catch (e) {
      print('❌ PHONE VERIFICATION ERROR: Error simulating verification link click: $e');
    }
  }

  // Verify phone number (this would be called when user clicks the verification link)
  Future<bool> verifyPhoneNumber(String token, String userId) async {
    try {
      print('🔍 PHONE VERIFICATION: Starting verification with token: $token');
      print('👤 PHONE VERIFICATION: User ID: $userId');

      // Get verification data from Firestore
      print('📖 PHONE VERIFICATION: Fetching verification data from Firestore...');
      final doc = await _firestore.collection('phoneVerifications').doc(userId).get();

      if (!doc.exists) {
        print('❌ PHONE VERIFICATION: Verification record not found for user: $userId');
        return false;
      }

      final data = doc.data()!;
      print('📋 PHONE VERIFICATION: Retrieved verification data: $data');

      // Validate token and expiration
      if (data['verificationToken'] != token) {
        print('❌ PHONE VERIFICATION: Invalid verification token. Expected: ${data['verificationToken']}, Got: $token');
        return false;
      }

      if (data['verified'] == true) {
        print('⚠️ PHONE VERIFICATION: Phone number already verified');
        return true;
      }

      final expiresAt = (data['expiresAt'] as Timestamp).toDate();
      if (DateTime.now().isAfter(expiresAt)) {
        print('❌ PHONE VERIFICATION: Verification token expired at: $expiresAt');
        return false;
      }

      // Directly update the phone number in user's profile (simplified)
      final newPhoneNumber = data['newPhoneNumber'] as String;
      print('📱 PHONE VERIFICATION: Updating phone number to: $newPhoneNumber');

      await _firestore.collection('users').doc(userId).update({
        'phoneNumber': newPhoneNumber,
        'phoneUpdatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ PHONE VERIFICATION: Phone number updated in Firestore successfully');

      // Clean up verification record (no pending states)
      print('🧹 PHONE VERIFICATION: Cleaning up verification record...');
      await _firestore.collection('phoneVerifications').doc(userId).delete();
      print('✅ PHONE VERIFICATION: Verification record cleaned up');

      print('🎉 PHONE VERIFICATION: Complete! Phone number updated to: $newPhoneNumber');

      return true;
    } catch (e) {
      print('❌ PHONE VERIFICATION ERROR: Failed to verify phone number: $e');
      print('❌ PHONE VERIFICATION ERROR: Stack trace: ${StackTrace.current}');
      return false;
    }
  }



  // Show verification link dialog (for demo purposes)
  void showVerificationDialog(BuildContext context, String verificationUrl) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          'Phone Verification',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'In a real app, you would receive an email with a verification link. For demo purposes, the verification will happen automatically in 5 seconds.',
              style: GoogleFonts.poppins(),
            ),
            const SizedBox(height: 16),
            Text(
              'Verification URL:',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                verificationUrl,
                style: GoogleFonts.poppins(fontSize: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style: GoogleFonts.poppins(color: AppColors.primaryPink),
            ),
          ),
        ],
      ),
    );
  }

  // Clean up expired verifications
  Future<void> cleanupExpiredVerifications() async {
    try {
      final now = Timestamp.now();
      final query = await _firestore
          .collection('phoneVerifications')
          .where('expiresAt', isLessThan: now)
          .where('verified', isEqualTo: false)
          .get();

      for (final doc in query.docs) {
        await doc.reference.delete();
      }
      
      print('🧹 Cleaned up ${query.docs.length} expired phone verifications');
    } catch (e) {
      print('❌ Error cleaning up expired verifications: $e');
    }
  }
}
