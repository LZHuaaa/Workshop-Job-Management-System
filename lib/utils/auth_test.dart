import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class AuthTest {
  static Future<void> testFirebaseAuth() async {
    try {
      print('🔥 Testing Firebase Authentication...');
      
      // Test Firebase initialization
      if (Firebase.apps.isEmpty) {
        print('❌ Firebase not initialized');
        return;
      }
      
      print('✅ Firebase initialized successfully');
      
      // Test Firebase Auth
      final auth = FirebaseAuth.instance;
      print('🔐 Firebase Auth instance created');
      print('👤 Current user: ${auth.currentUser?.email ?? 'None'}');
      
      // Test if email/password authentication is enabled
      try {
        // Try to fetch sign-in methods for a test email
        final methods = await auth.fetchSignInMethodsForEmail('test@example.com');
        print('🔍 Available sign-in methods: $methods');
        print('✅ Email/password authentication appears to be enabled');
      } catch (e) {
        print('⚠️ Could not fetch sign-in methods: $e');
        if (e.toString().contains('operation-not-allowed')) {
          print('❌ Email/password authentication is NOT enabled in Firebase Console');
          print('📝 Please enable it: Firebase Console > Authentication > Sign-in method > Email/Password');
        }
      }
      
      print('🔥 Firebase Auth test completed');
      
    } catch (e) {
      print('❌ Firebase Auth test failed: $e');
    }
  }
  
  static Future<void> testCreateUser() async {
    try {
      print('🧪 Testing user creation...');
      
      final auth = FirebaseAuth.instance;
      final testEmail = 'test-${DateTime.now().millisecondsSinceEpoch}@example.com';
      final testPassword = 'TestPassword123!';
      
      print('📝 Attempting to create test user: $testEmail');
      
      final credential = await auth.createUserWithEmailAndPassword(
        email: testEmail,
        password: testPassword,
      );
      
      print('✅ Test user created successfully: ${credential.user?.uid}');
      
      // Clean up - delete the test user
      await credential.user?.delete();
      print('🗑️ Test user deleted');
      
    } catch (e) {
      print('❌ User creation test failed: $e');
      
      if (e.toString().contains('operation-not-allowed')) {
        print('');
        print('🚨 SOLUTION REQUIRED:');
        print('1. Go to Firebase Console: https://console.firebase.google.com/');
        print('2. Select your project: pinkdrive-21122');
        print('3. Go to Authentication > Sign-in method');
        print('4. Click on "Email/Password"');
        print('5. Toggle "Enable" to ON');
        print('6. Click "Save"');
        print('');
      }
    }
  }
}
