import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../services/admin_data_service.dart';
import '../services/simple_auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/hidden_admin_panel.dart';
import 'auth/login_screen.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _authService = SimpleAuthService();
  User? _currentUser;
  bool _isLoading = false;
  bool _showOldPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  @override
  void initState() {
    super.initState();
    _currentUser = _authService.currentUser;
  }

  Future<void> _handleLogout() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.signOut();

      if (mounted) {
        // Navigate to login screen
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to sign out: ${e.toString()}',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'User Profile',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  GestureDetector(
                    onTap: () {
                      // Secret admin access - 7 taps on profile picture
                      if (AdminDataService.checkAdminUnlock()) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const HiddenAdminPanel(),
                          ),
                        );
                      } else {
                        // Show subtle feedback for remaining taps
                        final remaining = AdminDataService.remainingTaps;
                        if (remaining <= 3) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '$remaining more taps...',
                                style: GoogleFonts.poppins(fontSize: 12),
                              ),
                              duration: const Duration(milliseconds: 500),
                              backgroundColor:
                                  AppColors.primaryPink.withOpacity(0.8),
                            ),
                          );
                        }
                      }
                    },
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.primaryPink.withOpacity(0.1),
                      backgroundImage: _currentUser?.photoURL != null
                          ? NetworkImage(_currentUser!.photoURL!)
                          : null,
                      child: _currentUser?.photoURL == null
                          ? Text(
                              (_currentUser?.displayName?.isNotEmpty == true)
                                  ? _currentUser!.displayName![0].toUpperCase()
                                  : (_currentUser?.email?.isNotEmpty == true)
                                      ? _currentUser!.email![0].toUpperCase()
                                      : 'U',
                              style: GoogleFonts.poppins(
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryPink,
                              ),
                            )
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () {
                        // TODO: Implement photo edit logic
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Edit photo clicked',
                                style: GoogleFonts.poppins()),
                            backgroundColor: AppColors.primaryPink,
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(4),
                        child: Icon(Icons.edit,
                            color: AppColors.primaryPink, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _buildInfoRow('Display Name', _currentUser?.displayName ?? 'Not set', Icons.person),
            const SizedBox(height: 16),
            _buildInfoRow('Email', _currentUser?.email ?? 'Not set', Icons.email),
            const SizedBox(height: 16),
            _buildInfoRow('Auth Provider', _getAuthProviderText(), Icons.security),
            const SizedBox(height: 16),
            if (_currentUser?.phoneNumber != null) ...[
              _buildInfoRow('Phone Number', _currentUser!.phoneNumber!, Icons.phone),
              const SizedBox(height: 16),
            ],
            const Spacer(),
            Center(
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _handleLogout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.errorRed,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.logout, color: Colors.white),
                label: Text(
                  _isLoading ? 'Signing out...' : 'Logout',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getAuthProviderText() {
    if (_currentUser == null) return 'Unknown';

    // For Firebase Auth, we can check the provider data
    if (_currentUser!.providerData.isNotEmpty) {
      final providerId = _currentUser!.providerData.first.providerId;
      switch (providerId) {
        case 'password':
          return 'Email/Password';
        case 'google.com':
          return 'Google';
        case 'facebook.com':
          return 'Facebook';
        default:
          return 'Email/Password';
      }
    }

    return 'Email/Password';
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryPink, size: 20),
        const SizedBox(width: 12),
        Text(
          label + ':',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
