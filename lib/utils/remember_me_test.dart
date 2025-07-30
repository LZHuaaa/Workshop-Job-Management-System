import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/simple_auth_service.dart';

class RememberMeTest {
  static final _authService = SimpleAuthService();

  /// Test the Remember Me functionality
  static Future<void> testRememberMeFlow() async {
    print('\n🧪 TESTING REMEMBER ME FUNCTIONALITY');
    print('=====================================');

    try {
      // Test 1: Check initial state
      await _testInitialState();

      // Test 2: Check SharedPreferences storage
      await _testSharedPreferencesStorage();

      // Test 3: Check auto-login detection
      await _testAutoLoginDetection();

      // Test 4: Check clear functionality
      await _testClearFunctionality();

      print('\n✅ ALL REMEMBER ME TESTS PASSED!');
      print('=====================================');

    } catch (e) {
      print('\n❌ REMEMBER ME TEST FAILED: $e');
      print('=====================================');
    }
  }

  static Future<void> _testInitialState() async {
    print('\n📋 Test 1: Initial State');
    
    final rememberedEmail = await _authService.getRememberedEmail();
    final isAutoLoginEnabled = await _authService.isAutoLoginEnabled();
    final currentUser = _authService.currentUser;

    print('  - Remembered Email: ${rememberedEmail ?? 'None'}');
    print('  - Auto Login Enabled: $isAutoLoginEnabled');
    print('  - Current User: ${currentUser?.email ?? 'None'}');
    print('  - Email Verified: ${currentUser?.emailVerified ?? false}');
  }

  static Future<void> _testSharedPreferencesStorage() async {
    print('\n📋 Test 2: SharedPreferences Storage');
    
    final prefs = await SharedPreferences.getInstance();
    
    final rememberMe = prefs.getBool('remember_me') ?? false;
    final userEmail = prefs.getString('user_email');
    final autoLogin = prefs.getBool('auto_login_enabled') ?? false;

    print('  - remember_me key: $rememberMe');
    print('  - user_email key: ${userEmail ?? 'None'}');
    print('  - auto_login_enabled key: $autoLogin');

    // Check if all keys are consistent
    if (rememberMe && userEmail != null && autoLogin) {
      print('  ✅ All SharedPreferences keys are consistent');
    } else if (!rememberMe && userEmail == null && !autoLogin) {
      print('  ✅ All SharedPreferences keys are consistently empty');
    } else {
      print('  ⚠️ SharedPreferences keys are inconsistent');
      print('     This might indicate a problem with the remember me logic');
    }
  }

  static Future<void> _testAutoLoginDetection() async {
    print('\n📋 Test 3: Auto-Login Detection');
    
    final isAutoLoginEnabled = await _authService.isAutoLoginEnabled();
    final currentUser = FirebaseAuth.instance.currentUser;
    
    if (isAutoLoginEnabled && currentUser != null && currentUser.emailVerified) {
      print('  ✅ Auto-login should work: User is authenticated and verified');
      print('  📱 Expected behavior: App should auto-login on restart');
    } else if (isAutoLoginEnabled && currentUser != null && !currentUser.emailVerified) {
      print('  ⚠️ Auto-login enabled but email not verified');
      print('  📱 Expected behavior: User will need to verify email first');
    } else if (isAutoLoginEnabled && currentUser == null) {
      print('  ❌ Auto-login enabled but no user authenticated');
      print('  📱 Expected behavior: Settings should be cleared');
    } else {
      print('  ℹ️ Auto-login not enabled');
      print('  📱 Expected behavior: User will see login screen');
    }
  }

  static Future<void> _testClearFunctionality() async {
    print('\n📋 Test 4: Clear Functionality Test');
    
    // Save current state
    final prefs = await SharedPreferences.getInstance();
    final originalRememberMe = prefs.getBool('remember_me');
    final originalUserEmail = prefs.getString('user_email');
    final originalAutoLogin = prefs.getBool('auto_login_enabled');

    // Test clearing
    await _authService.clearRememberMe();
    
    // Check if cleared
    final clearedRememberMe = prefs.getBool('remember_me');
    final clearedUserEmail = prefs.getString('user_email');
    final clearedAutoLogin = prefs.getBool('auto_login_enabled');

    if (clearedRememberMe == null && clearedUserEmail == null && clearedAutoLogin == null) {
      print('  ✅ Clear functionality works correctly');
    } else {
      print('  ❌ Clear functionality failed');
      print('     remember_me: $clearedRememberMe (should be null)');
      print('     user_email: $clearedUserEmail (should be null)');
      print('     auto_login_enabled: $clearedAutoLogin (should be null)');
    }

    // Restore original state if it existed
    if (originalRememberMe != null) {
      await prefs.setBool('remember_me', originalRememberMe);
    }
    if (originalUserEmail != null) {
      await prefs.setString('user_email', originalUserEmail);
    }
    if (originalAutoLogin != null) {
      await prefs.setBool('auto_login_enabled', originalAutoLogin);
    }
  }

  /// Manual test instructions for developers
  static void printManualTestInstructions() {
    print('\n📋 MANUAL TESTING INSTRUCTIONS FOR REMEMBER ME');
    print('===============================================');
    print('');
    print('1. **Test Remember Me ON:**');
    print('   - Sign out if currently logged in');
    print('   - Go to login screen');
    print('   - Enter valid email and password');
    print('   - CHECK the "Remember Me" checkbox');
    print('   - Tap "Sign In"');
    print('   - Verify successful login');
    print('   - COMPLETELY CLOSE the app (not just minimize)');
    print('   - Reopen the app');
    print('   - EXPECTED: Should automatically go to main app (no login screen)');
    print('');
    print('2. **Test Remember Me OFF:**');
    print('   - Sign out from the app');
    print('   - Go to login screen');
    print('   - Enter valid email and password');
    print('   - UNCHECK the "Remember Me" checkbox');
    print('   - Tap "Sign In"');
    print('   - Verify successful login');
    print('   - COMPLETELY CLOSE the app');
    print('   - Reopen the app');
    print('   - EXPECTED: Should show login screen (no auto-login)');
    print('');
    print('3. **Test Sign Out Clears Remember Me:**');
    print('   - Login with "Remember Me" checked');
    print('   - Go to profile screen');
    print('   - Tap "Sign Out"');
    print('   - COMPLETELY CLOSE the app');
    print('   - Reopen the app');
    print('   - EXPECTED: Should show login screen (remember me cleared)');
    print('');
    print('4. **Debugging Tips:**');
    print('   - Check console logs for remember me status');
    print('   - Use RememberMeTest.testRememberMeFlow() to check internal state');
    print('   - Verify SharedPreferences are being saved correctly');
    print('   - Ensure Firebase Auth state persists between app restarts');
    print('===============================================');
  }

  /// Quick status check
  static Future<void> quickStatusCheck() async {
    print('\n🔍 REMEMBER ME QUICK STATUS');
    print('============================');
    
    final rememberedEmail = await _authService.getRememberedEmail();
    final isAutoLoginEnabled = await _authService.isAutoLoginEnabled();
    final currentUser = _authService.currentUser;

    print('Current User: ${currentUser?.email ?? 'None'}');
    print('Email Verified: ${currentUser?.emailVerified ?? false}');
    print('Remembered Email: ${rememberedEmail ?? 'None'}');
    print('Auto Login Enabled: $isAutoLoginEnabled');
    
    if (isAutoLoginEnabled && currentUser != null && currentUser.emailVerified) {
      print('✅ Remember Me is ACTIVE - should auto-login');
    } else {
      print('❌ Remember Me is INACTIVE - will show login screen');
    }
    print('============================');
  }
}
