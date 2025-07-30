import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/simple_auth_service.dart';
import '../../theme/app_colors.dart';
import '../main_navigation.dart';
import 'login_screen.dart';

class SimpleAuthWrapper extends StatefulWidget {
  const SimpleAuthWrapper({super.key});

  @override
  State<SimpleAuthWrapper> createState() => _SimpleAuthWrapperState();
}

class _SimpleAuthWrapperState extends State<SimpleAuthWrapper> {
  final _authService = SimpleAuthService();
  bool _isCheckingAutoLogin = true;

  @override
  void initState() {
    super.initState();
    _checkAutoLogin();
  }

  Future<void> _checkAutoLogin() async {
    try {
      // Check if auto-login is enabled and user is already authenticated
      final isAutoLoginEnabled = await _authService.isAutoLoginEnabled();
      final currentUser = _authService.currentUser;

      print('🔍 Checking auto-login: enabled=$isAutoLoginEnabled, user=${currentUser?.email}');

      if (isAutoLoginEnabled && currentUser != null && currentUser.emailVerified) {
        print('✅ Auto-login successful for: ${currentUser.email}');
        // User is already authenticated and auto-login is enabled
        // The StreamBuilder will handle navigation to MainNavigation
      } else if (isAutoLoginEnabled && currentUser == null) {
        print('⚠️ Auto-login was enabled but user is not authenticated - clearing settings');
        // Auto-login was enabled but user is not authenticated (shouldn't happen)
        await _authService.clearRememberMe();
      }
    } catch (e) {
      print('❌ Error checking auto-login: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingAutoLogin = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading while checking auto-login
    if (_isCheckingAutoLogin) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryPink),
              ),
              const SizedBox(height: 16),
              Text(
                'Checking authentication...',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        // Show loading while checking authentication state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryPink),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading...',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Show main app if user is authenticated and email is verified
        if (snapshot.hasData && snapshot.data != null && snapshot.data!.emailVerified) {
          print('✅ User authenticated and verified: ${snapshot.data!.email}');
          return const MainNavigation();
        }

        // Show login screen if user is not authenticated or email not verified
        print('❌ User not authenticated or email not verified');
        return const LoginScreen();
      },
    );
  }
}
