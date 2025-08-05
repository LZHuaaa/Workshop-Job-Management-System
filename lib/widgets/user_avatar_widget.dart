import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_colors.dart';
import '../services/simple_auth_service.dart';

class UserAvatarWidget extends StatelessWidget {
  final double radius;
  final double? fontSize;
  final VoidCallback? onTap;
  final bool showBorder;
  final Color? borderColor;
  final double borderWidth;

  const UserAvatarWidget({
    super.key,
    this.radius = 20,
    this.fontSize,
    this.onTap,
    this.showBorder = false,
    this.borderColor,
    this.borderWidth = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    final authService = SimpleAuthService();
    final User? currentUser = authService.currentUser;

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        final user = snapshot.data ?? currentUser;
        
        return GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: showBorder
                ? BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: borderColor ?? AppColors.primaryPink,
                      width: borderWidth,
                    ),
                  )
                : null,
            child: CircleAvatar(
              radius: radius,
              backgroundColor: AppColors.primaryPink.withOpacity(0.1),
              backgroundImage: user?.photoURL != null
                  ? NetworkImage(user!.photoURL!)
                  : null,
              child: user?.photoURL == null
                  ? Text(
                      _getUserInitials(user),
                      style: GoogleFonts.poppins(
                        fontSize: fontSize ?? (radius * 0.6),
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryPink,
                      ),
                    )
                  : null,
            ),
          ),
        );
      },
    );
  }

  /// Generate user initials from display name or email
  String _getUserInitials(User? user) {
    if (user == null) return 'U';

    // Try to get initials from display name first
    if (user.displayName?.isNotEmpty == true) {
      final nameParts = user.displayName!.trim().split(' ');
      if (nameParts.length >= 2) {
        // First letter of first name + first letter of last name
        return '${nameParts.first[0].toUpperCase()}${nameParts.last[0].toUpperCase()}';
      } else if (nameParts.isNotEmpty) {
        // Just first letter of single name
        return nameParts.first[0].toUpperCase();
      }
    }

    // Fallback to first letter of email
    if (user.email?.isNotEmpty == true) {
      return user.email![0].toUpperCase();
    }

    // Ultimate fallback
    return 'U';
  }
}
