import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SimpleAuthService {
  static final SimpleAuthService _instance = SimpleAuthService._internal();
  factory SimpleAuthService() => _instance;
  SimpleAuthService._internal();

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  static const String _rememberMeKey = 'remember_me';
  static const String _userEmailKey = 'user_email';
  static const String _autoLoginKey = 'auto_login_enabled';

  // Get current user
  User? get currentUser => _firebaseAuth.currentUser;

  // Stream of authentication state changes
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Sign up with email and password
  Future<AuthResult> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      print('🔐 Attempting to create user with email: $email');
      
      // Create user with Firebase Auth
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        return AuthResult.failure('Failed to create user account');
      }

      print('✅ User created successfully: ${credential.user!.uid}');

      // Update display name
      await credential.user!.updateDisplayName(displayName);

      // Create user profile document in Firestore
      await _createUserProfile(credential.user!, displayName);

      // Send email verification
      await credential.user!.sendEmailVerification();
      print('📧 Email verification sent');

      return AuthResult.success('Account created successfully! Please check your email to verify your account.');
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase Auth Exception: ${e.code} - ${e.message}');
      return AuthResult.failure(_getErrorMessage(e));
    } catch (e) {
      print('❌ Unexpected error during sign up: $e');
      return AuthResult.failure('An unexpected error occurred: ${e.toString()}');
    }
  }

  // Sign in with email and password
  Future<AuthResult> signInWithEmailAndPassword({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    try {
      print('🔐 Attempting to sign in with email: $email');

      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        return AuthResult.failure('Failed to sign in');
      }

      // Check if email is verified
      if (!credential.user!.emailVerified) {
        // Sign out the user since email is not verified
        await _firebaseAuth.signOut();
        return AuthResult.failure('Please verify your email address before signing in. Check your inbox for the verification email.');
      }

      print('✅ Sign in successful: ${credential.user!.uid}');

      // Handle remember me
      await _handleRememberMe(rememberMe, email);

      // Update last login time in user profile
      await _updateLastLoginTime(credential.user!.uid);

      return AuthResult.success('Signed in successfully');
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase Auth Exception: ${e.code} - ${e.message}');
      return AuthResult.failure(_getErrorMessage(e));
    } catch (e) {
      print('❌ Unexpected error during sign in: $e');
      return AuthResult.failure('An unexpected error occurred: ${e.toString()}');
    }
  }

  // Send password reset email
  Future<AuthResult> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      return AuthResult.success('Password reset email sent successfully');
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_getErrorMessage(e));
    } catch (e) {
      return AuthResult.failure('Failed to send password reset email: ${e.toString()}');
    }
  }

  // Resend email verification
  Future<AuthResult> resendEmailVerification() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        return AuthResult.failure('No user is currently signed in');
      }

      if (user.emailVerified) {
        return AuthResult.failure('Email is already verified');
      }

      await user.sendEmailVerification();
      return AuthResult.success('Verification email sent successfully');
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_getErrorMessage(e));
    } catch (e) {
      return AuthResult.failure('Failed to send verification email: ${e.toString()}');
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _firebaseAuth.signOut();

    // Clear remember me preferences
    await clearRememberMe();
  }

  // Check if user should be remembered
  Future<String?> getRememberedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool(_rememberMeKey) ?? false;
    if (rememberMe) {
      return prefs.getString(_userEmailKey);
    }
    return null;
  }

  // Private helper methods
  Future<void> _createUserProfile(User user, String displayName) async {
    try {
      await _firestore.collection('user_profiles').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'displayName': displayName,
        'emailVerified': user.emailVerified,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
      print('📄 User profile created in Firestore');
    } catch (e) {
      print('⚠️ Failed to create user profile: $e');
      // Don't fail the entire sign up process if profile creation fails
    }
  }

  Future<void> _updateLastLoginTime(String userId) async {
    try {
      await _firestore.collection('user_profiles').doc(userId).update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('⚠️ Failed to update last login time: $e');
    }
  }

  Future<void> _handleRememberMe(bool rememberMe, String email) async {
    final prefs = await SharedPreferences.getInstance();
    if (rememberMe) {
      await prefs.setBool(_rememberMeKey, true);
      await prefs.setString(_userEmailKey, email);
      await prefs.setBool(_autoLoginKey, true);
      print('✅ Remember Me enabled - user will be auto-logged in next time');
    } else {
      await prefs.remove(_rememberMeKey);
      await prefs.remove(_userEmailKey);
      await prefs.remove(_autoLoginKey);
      print('❌ Remember Me disabled - user will need to login manually');
    }
  }

  // Check if auto-login is enabled
  Future<bool> isAutoLoginEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoLoginKey) ?? false;
  }

  // Clear remember me settings (called on logout)
  Future<void> clearRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_rememberMeKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_autoLoginKey);
    print('🧹 Remember Me settings cleared');
  }

  String _getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address';
      case 'wrong-password':
        return 'Incorrect password';
      case 'email-already-in-use':
        return 'An account already exists with this email address';
      case 'weak-password':
        return 'Password is too weak';
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later';
      case 'operation-not-allowed':
        return 'Email/password authentication is not enabled. Please enable it in Firebase Console: Authentication > Sign-in method > Email/Password';
      case 'invalid-credential':
        return 'Invalid email or password';
      default:
        return e.message ?? 'An authentication error occurred';
    }
  }
}

class AuthResult {
  final bool isSuccess;
  final String message;

  AuthResult._({required this.isSuccess, required this.message});

  factory AuthResult.success(String message) {
    return AuthResult._(isSuccess: true, message: message);
  }

  factory AuthResult.failure(String message) {
    return AuthResult._(isSuccess: false, message: message);
  }
}
