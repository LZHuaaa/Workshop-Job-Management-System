import 'package:flutter/material.dart';
import '../screens/auth/password_reset_screen.dart';

class DeepLinkHandler {
  /// Handle Firebase Auth deep links
  static void handleAuthLink(BuildContext context, String link) {
    final uri = Uri.parse(link);
    
    // Check if it's a password reset link
    if (uri.queryParameters.containsKey('mode') && 
        uri.queryParameters['mode'] == 'resetPassword') {
      
      final oobCode = uri.queryParameters['oobCode'];
      
      if (oobCode != null) {
        // Navigate to password reset screen with the code
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PasswordResetScreen(oobCode: oobCode),
          ),
        );
      }
    }
  }
  
  /// Extract OOB code from Firebase Auth link
  static String? extractOobCode(String link) {
    try {
      final uri = Uri.parse(link);
      return uri.queryParameters['oobCode'];
    } catch (e) {
      return null;
    }
  }
  
  /// Check if link is a password reset link
  static bool isPasswordResetLink(String link) {
    try {
      final uri = Uri.parse(link);
      return uri.queryParameters['mode'] == 'resetPassword';
    } catch (e) {
      return false;
    }
  }
}
