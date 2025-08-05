import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_colors.dart';
import '../services/simple_auth_service.dart';

class DynamicGreetingWidget extends StatelessWidget {
  final String? subtitle;
  final double? titleFontSize;
  final double? subtitleFontSize;
  final FontWeight? titleFontWeight;
  final Color? titleColor;
  final Color? subtitleColor;
  final CrossAxisAlignment alignment;

  const DynamicGreetingWidget({
    super.key,
    this.subtitle,
    this.titleFontSize = 24,
    this.subtitleFontSize = 14,
    this.titleFontWeight = FontWeight.w600,
    this.titleColor,
    this.subtitleColor,
    this.alignment = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    final authService = SimpleAuthService();
    final User? currentUser = authService.currentUser;

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        final user = snapshot.data ?? currentUser;
        
        return Column(
          crossAxisAlignment: alignment,
          children: [
            Text(
              _getGreetingText(user),
              style: GoogleFonts.poppins(
                fontSize: titleFontSize,
                fontWeight: titleFontWeight,
                color: titleColor ?? AppColors.textDark,
              ),
            ),
            if (subtitle != null) ...[
              Text(
                subtitle!,
                style: GoogleFonts.poppins(
                  fontSize: subtitleFontSize,
                  color: subtitleColor ?? AppColors.textSecondary,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  /// Generate personalized greeting text
  String _getGreetingText(User? user) {
    if (user == null) return 'Hello, User';

    // Try to get name from display name first
    if (user.displayName?.isNotEmpty == true) {
      final displayName = user.displayName!.trim();
      // Get first name only for greeting
      final firstName = displayName.split(' ').first;
      return 'Hello, $firstName';
    }

    // Fallback to email username (part before @)
    if (user.email?.isNotEmpty == true) {
      final emailUsername = user.email!.split('@').first;
      // Capitalize first letter
      final capitalizedUsername = emailUsername.isNotEmpty
          ? '${emailUsername[0].toUpperCase()}${emailUsername.substring(1)}'
          : emailUsername;
      return 'Hello, $capitalizedUsername';
    }

    // Ultimate fallback
    return 'Hello, User';
  }
}
