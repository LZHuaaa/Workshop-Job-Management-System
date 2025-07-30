import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserDeletionService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Complete user account deletion
  /// This deletes the user from both Firebase Auth and Firestore
  /// After deletion, the email can be reused for new signups
  static Future<UserDeletionResult> deleteUserAccount({
    required String userId,
    bool deleteFromAuth = true,
    bool deleteFromFirestore = true,
  }) async {
    try {
      print('🗑️ Starting user deletion process for: $userId');

      // Step 1: Delete user profile from Firestore (if requested)
      if (deleteFromFirestore) {
        await _deleteUserFromFirestore(userId);
        print('✅ User profile deleted from Firestore');
      }

      // Step 2: Delete user from Firebase Auth (if requested)
      if (deleteFromAuth) {
        await _deleteUserFromAuth(userId);
        print('✅ User deleted from Firebase Auth');
      }

      print('🎉 User deletion completed successfully');
      return UserDeletionResult.success('User account deleted successfully');

    } catch (e) {
      print('❌ Error during user deletion: $e');
      return UserDeletionResult.failure('Failed to delete user account: ${e.toString()}');
    }
  }

  /// Delete current authenticated user (self-deletion)
  static Future<UserDeletionResult> deleteCurrentUser() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return UserDeletionResult.failure('No user is currently signed in');
      }

      final userId = currentUser.uid;
      print('🗑️ Current user requesting self-deletion: $userId');

      // Delete from Firestore first
      await _deleteUserFromFirestore(userId);
      print('✅ Current user profile deleted from Firestore');

      // Delete from Firebase Auth
      await currentUser.delete();
      print('✅ Current user deleted from Firebase Auth');

      return UserDeletionResult.success('Your account has been deleted successfully');

    } on FirebaseAuthException catch (e) {
      print('❌ Firebase Auth error during self-deletion: ${e.code} - ${e.message}');
      
      if (e.code == 'requires-recent-login') {
        return UserDeletionResult.failure(
          'For security reasons, please sign out and sign back in before deleting your account.'
        );
      }
      
      return UserDeletionResult.failure('Failed to delete account: ${e.message}');
    } catch (e) {
      print('❌ Unexpected error during self-deletion: $e');
      return UserDeletionResult.failure('An unexpected error occurred: ${e.toString()}');
    }
  }

  /// Delete user profile from Firestore only
  /// This keeps the Firebase Auth account but removes profile data
  static Future<void> _deleteUserFromFirestore(String userId) async {
    try {
      // Delete user profile document
      await _firestore.collection('user_profiles').doc(userId).delete();
      
      // Optional: Delete other user-related data
      // You can add more collections here if needed
      // await _deleteUserRelatedData(userId);
      
    } catch (e) {
      print('❌ Error deleting user from Firestore: $e');
      rethrow;
    }
  }

  /// Delete user from Firebase Auth only
  /// This requires admin privileges or the user to be currently authenticated
  static Future<void> _deleteUserFromAuth(String userId) async {
    try {
      final currentUser = _auth.currentUser;
      
      if (currentUser != null && currentUser.uid == userId) {
        // User is deleting their own account
        await currentUser.delete();
      } else {
        // This would require Firebase Admin SDK for deleting other users
        // For now, we'll throw an error as this requires admin privileges
        throw Exception(
          'Cannot delete other users without admin privileges. '
          'User must delete their own account or use Firebase Admin SDK.'
        );
      }
    } catch (e) {
      print('❌ Error deleting user from Firebase Auth: $e');
      rethrow;
    }
  }

  /// Delete all user-related data from various collections
  /// Add more collections as your app grows
  static Future<void> _deleteUserRelatedData(String userId) async {
    try {
      // Example: Delete user's vehicles (if they own any)
      final vehiclesQuery = await _firestore
          .collection('vehicles')
          .where('ownerId', isEqualTo: userId)
          .get();
      
      for (final doc in vehiclesQuery.docs) {
        await doc.reference.delete();
      }

      // Example: Delete user's service records
      final serviceRecordsQuery = await _firestore
          .collection('service_records')
          .where('customerId', isEqualTo: userId)
          .get();
      
      for (final doc in serviceRecordsQuery.docs) {
        await doc.reference.delete();
      }

      // Add more collections as needed
      print('✅ User-related data deleted from all collections');
      
    } catch (e) {
      print('⚠️ Error deleting user-related data: $e');
      // Don't rethrow - this is optional cleanup
    }
  }

  /// Check if email is available for reuse after deletion
  static Future<bool> isEmailAvailable(String email) async {
    try {
      // Try to fetch sign-in methods for the email
      final methods = await _auth.fetchSignInMethodsForEmail(email);
      return methods.isEmpty; // Empty means email is available
    } catch (e) {
      print('❌ Error checking email availability: $e');
      return false; // Assume not available on error
    }
  }

  /// Re-authenticate user before sensitive operations
  static Future<bool> reauthenticateUser(String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        return false;
      }

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );

      await user.reauthenticateWithCredential(credential);
      return true;
    } catch (e) {
      print('❌ Re-authentication failed: $e');
      return false;
    }
  }
}

class UserDeletionResult {
  final bool isSuccess;
  final String message;

  UserDeletionResult._({required this.isSuccess, required this.message});

  factory UserDeletionResult.success(String message) {
    return UserDeletionResult._(isSuccess: true, message: message);
  }

  factory UserDeletionResult.failure(String message) {
    return UserDeletionResult._(isSuccess: false, message: message);
  }
}

/// IMPORTANT NOTES FOR USER DELETION:
/// 
/// 1. **Complete Deletion Process:**
///    - Delete from Firestore: Removes user profile and related data
///    - Delete from Firebase Auth: Removes authentication account
///    - Both steps are required for complete deletion
/// 
/// 2. **Email Reuse:**
///    - Only deleting from Firestore: Email CANNOT be reused (Auth account still exists)
///    - Only deleting from Auth: Email CAN be reused (but profile data remains)
///    - Deleting from both: Email CAN be reused (complete clean slate)
/// 
/// 3. **Security Considerations:**
///    - Users can only delete their own accounts
///    - Recent authentication may be required for sensitive operations
///    - Admin SDK required for deleting other users' accounts
/// 
/// 4. **Best Practices:**
///    - Always delete from Firestore first (in case Auth deletion fails)
///    - Consider soft deletion (marking as deleted) instead of hard deletion
///    - Backup important data before deletion
///    - Implement confirmation dialogs for user safety
