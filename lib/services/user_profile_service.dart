import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfileService {
  static final UserProfileService _instance = UserProfileService._internal();
  factory UserProfileService() => _instance;
  UserProfileService._internal();

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _firebaseAuth.currentUser;

  // Update display name
  Future<ProfileUpdateResult> updateDisplayName(String newDisplayName) async {
    try {
      final user = currentUser;
      if (user == null) {
        return ProfileUpdateResult.failure('No user is currently signed in');
      }

      // Update Firebase Auth profile
      await user.updateDisplayName(newDisplayName);

      // Update Firestore profile
      await _updateFirestoreProfile(user.uid, {'displayName': newDisplayName});

      return ProfileUpdateResult.success('Username updated successfully');
    } on FirebaseAuthException catch (e) {
      return ProfileUpdateResult.failure(_getErrorMessage(e, context: 'username-change'));
    } catch (e) {
      return ProfileUpdateResult.failure('Failed to update username: ${e.toString()}');
    }
  }



  // Update phone number with direct password authentication (simplified)
  Future<ProfileUpdateResult> updatePhoneNumber(String phoneNumber, String currentPassword) async {
    try {
      final user = currentUser;
      if (user == null) {
        return ProfileUpdateResult.failure('No user is currently signed in');
      }

      // Validate phone number format
      if (!_isValidPhoneNumber(phoneNumber)) {
        return ProfileUpdateResult.failure('Please enter a valid phone number');
      }

      // Re-authenticate user before sensitive operation
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Directly update the phone number in Firestore (no email verification needed)
      await _updateFirestoreProfile(user.uid, {
        'phoneNumber': phoneNumber,
        'phoneUpdatedAt': FieldValue.serverTimestamp(),
      });

      return ProfileUpdateResult.success(
        'Phone number updated successfully to $phoneNumber.',
      );
    } on FirebaseAuthException catch (e) {
      return ProfileUpdateResult.failure(_getErrorMessage(e, context: 'phone-change'));
    } catch (e) {
      return ProfileUpdateResult.failure('Failed to update phone number: ${e.toString()}');
    }
  }

  // Send verification email for phone number change
  Future<void> _sendPhoneChangeVerificationEmail(String email, String newPhoneNumber, String userId) async {
    try {
      // Store the pending phone change with a verification token
      final verificationToken = _generateVerificationToken();
      final expirationTime = DateTime.now().add(const Duration(hours: 24));

      await _firestore.collection('phoneVerifications').doc(userId).set({
        'userId': userId,
        'newPhoneNumber': newPhoneNumber,
        'verificationToken': verificationToken,
        'expiresAt': Timestamp.fromDate(expirationTime),
        'createdAt': FieldValue.serverTimestamp(),
        'verified': false,
      });

      // In a real implementation, you would send an actual email here
      // For demo purposes, we'll simulate this by showing a dialog or notification
      print('📧 Phone verification email would be sent to: $email');
      print('📱 New phone number: $newPhoneNumber');
      print('🔑 Verification token: $verificationToken');
      print('⏰ Expires at: $expirationTime');

      // For demo purposes, let's simulate immediate verification after 3 seconds
      // In production, this would happen when the user clicks the email link
      Timer(const Duration(seconds: 3), () async {
        await _simulatePhoneVerification(userId, verificationToken);
      });

    } catch (e) {
      print('❌ Error setting up phone verification: $e');
    }
  }

  // Generate a verification token
  String _generateVerificationToken() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp * 1000 + (timestamp % 1000)).toString();
    return 'phone_verify_$random';
  }

  // Simulate phone verification (in production, this would be triggered by email link)
  Future<void> _simulatePhoneVerification(String userId, String token) async {
    try {
      final doc = await _firestore.collection('phoneVerifications').doc(userId).get();
      final data = doc.data();

      if (data != null &&
          data['verificationToken'] == token &&
          !data['verified'] &&
          (data['expiresAt'] as Timestamp).toDate().isAfter(DateTime.now())) {

        // Update the phone number in the user's profile
        await _updateFirestoreProfile(userId, {
          'phoneNumber': data['newPhoneNumber'],
        });

        // Mark as verified
        await _firestore.collection('phoneVerifications').doc(userId).update({
          'verified': true,
          'verifiedAt': FieldValue.serverTimestamp(),
        });

        print('✅ Phone number verification completed successfully');
      }
    } catch (e) {
      print('❌ Error during phone verification: $e');
    }
  }

  // Change password
  Future<ProfileUpdateResult> changePassword(String currentPassword, String newPassword) async {
    try {
      final user = currentUser;
      if (user == null) {
        return ProfileUpdateResult.failure('No user is currently signed in');
      }

      // Validate new password
      if (newPassword.length < 6) {
        return ProfileUpdateResult.failure('New password must be at least 6 characters long');
      }

      // Re-authenticate user before sensitive operation
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);

      return ProfileUpdateResult.success('Password changed successfully');
    } on FirebaseAuthException catch (e) {
      return ProfileUpdateResult.failure(_getErrorMessage(e, context: 'password-change'));
    } catch (e) {
      return ProfileUpdateResult.failure('Failed to change password: ${e.toString()}');
    }
  }

  // Update profile photo URL
  Future<ProfileUpdateResult> updateProfilePhoto(String photoURL) async {
    try {
      final user = currentUser;
      if (user == null) {
        return ProfileUpdateResult.failure('No user is currently signed in');
      }

      // Update Firebase Auth profile
      await user.updatePhotoURL(photoURL);

      // Update Firestore profile
      await _updateFirestoreProfile(user.uid, {'photoURL': photoURL});

      return ProfileUpdateResult.success('Profile photo updated successfully');
    } on FirebaseAuthException catch (e) {
      return ProfileUpdateResult.failure(_getErrorMessage(e, context: 'photo-change'));
    } catch (e) {
      return ProfileUpdateResult.failure('Failed to update profile photo: ${e.toString()}');
    }
  }

  // Get user profile data from Firestore
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('user_profiles').doc(userId).get();
      return doc.data();
    } catch (e) {
      print('Failed to get user profile: $e');
      return null;
    }
  }



  // Private helper methods
  Future<void> _updateFirestoreProfile(String userId, Map<String, dynamic> data) async {
    await _firestore.collection('user_profiles').doc(userId).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Validate phone number format (international format)
  bool _isValidPhoneNumber(String phoneNumber) {
    // Remove all whitespace and formatting characters except +
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Must start with + for international format
    if (!cleanNumber.startsWith('+')) return false;

    // Remove the + and check if remaining characters are all digits
    final digitsOnly = cleanNumber.substring(1);
    if (!RegExp(r'^\d+$').hasMatch(digitsOnly)) return false;

    // Check length: international numbers are typically 7-15 digits after country code
    return digitsOnly.length >= 7 && digitsOnly.length <= 15;
  }

  String _getErrorMessage(FirebaseAuthException e, {String? context}) {
    switch (e.code) {
      case 'wrong-password':
        return 'Your current password is incorrect. Please check your password and try again.';
      case 'weak-password':
        return 'Your new password is too weak. Please choose a stronger password with at least 6 characters.';
      case 'email-already-in-use':
        return 'This email address is already registered with another account. Please use a different email address.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'requires-recent-login':
        return 'For security reasons, please log out and log back in, then try again.';
      case 'user-disabled':
        return 'Your account has been temporarily disabled. Please contact support for assistance.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a few minutes before trying again.';
      case 'invalid-credential':
      case 'credential-already-in-use':
        if (context == 'phone-change') {
          return 'Unable to change phone number. Please check your current password and try again.';
        } else if (context == 'password-change') {
          return 'Your current password is incorrect. Please try again.';
        }
        return 'Authentication failed. Please check your credentials and try again.';
      case 'operation-not-allowed':
        return 'This operation is not currently available. Please try again later.';
      case 'user-not-found':
        return 'Account not found. Please check your login information.';
      case 'network-request-failed':
        return 'Network connection failed. Please check your internet connection and try again.';
      case 'internal-error':
        return 'An internal error occurred. Please try again in a few moments.';
      default:
        // Handle the specific error message mentioned in the request
        if (e.message?.contains('auth credential is incorrect, malformed or has expired') == true) {
          if (context == 'phone-change') {
            return 'Your current password is incorrect or your session has expired. Please try again.';
          } else if (context == 'password-change') {
            return 'Your current password is incorrect. Please try again.';
          }
          return 'Your session has expired. Please log in again and try again.';
        }

        // Provide context-specific fallback messages
        if (context == 'phone-change') {
          return 'Unable to change phone number. Please check your information and try again.';
        } else if (context == 'password-change') {
          return 'Unable to change password. Please check your current password and try again.';
        } else if (context == 'username-change') {
          return 'Unable to update username. Please try again.';
        }

        return 'An unexpected error occurred. Please try again or contact support if the problem persists.';
    }
  }


}

class ProfileUpdateResult {
  final bool isSuccess;
  final String message;

  ProfileUpdateResult._({required this.isSuccess, required this.message});

  factory ProfileUpdateResult.success(String message) {
    return ProfileUpdateResult._(isSuccess: true, message: message);
  }

  factory ProfileUpdateResult.failure(String message) {
    return ProfileUpdateResult._(isSuccess: false, message: message);
  }
}
