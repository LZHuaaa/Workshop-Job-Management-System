import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../services/admin_data_service.dart';
import '../services/simple_auth_service.dart';
import '../services/user_profile_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/hidden_admin_panel.dart';
import '../widgets/user_avatar_widget.dart';
import '../dialogs/edit_display_name_dialog.dart';
import '../dialogs/edit_phone_dialog.dart';
import '../dialogs/change_password_dialog.dart';
import 'auth/login_screen.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _authService = SimpleAuthService();
  final _profileService = UserProfileService();
  User? _currentUser;
  Map<String, dynamic>? _userProfile;
  bool _isLoading = false;
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _currentUser = _authService.currentUser;
    _loadUserProfile();
  }



  Future<void> _loadUserProfile() async {
    if (_currentUser != null) {
      final profile = await _profileService.getUserProfile(_currentUser!.uid);
      if (mounted) {
        setState(() {
          _userProfile = profile;
          _isLoadingProfile = false;
        });
      }
    }
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
    if (_isLoadingProfile) {
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
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar Section
            Center(
              child: UserAvatarWidget(
                radius: 50,
                fontSize: 36,
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
              ),
            ),
            const SizedBox(height: 32),

            // Profile Information Section
            _buildSectionTitle('Profile Information'),
            const SizedBox(height: 16),
            _buildEditableInfoCard(
              'Username',
              _currentUser?.displayName ?? 'Not set',
              Icons.person,
              () => _editDisplayName(),
            ),
            const SizedBox(height: 12),
            _buildEditableInfoCard(
              'Email Address',
              _currentUser?.email ?? 'Not set',
              Icons.email,
              () {}, // Empty callback - not used since showEditButton is false
              showEditButton: false, // Hide the edit button for email field
            ),
            const SizedBox(height: 12),
            _buildEditableInfoCard(
              'Phone Number',
              _getPhoneNumber(),
              Icons.phone,
              () => _editPhone(),
              isSetNow: _getPhoneNumber() == 'Not set',
            ),
            const SizedBox(height: 24),

            // Security Section
            _buildSectionTitle('Security'),
            const SizedBox(height: 16),
            _buildEditableInfoCard(
              'Password',
              '••••••••',
              Icons.lock,
              () => _changePassword(),
              actionText: 'Change',
            ),

            const SizedBox(height: 32),

            // Logout Button
            Center(
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _handleLogout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.errorRed,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
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
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }



  // Edit display name
  Future<void> _editDisplayName() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => EditDisplayNameDialog(
        currentDisplayName: _currentUser?.displayName ?? '',
      ),
    );

    if (result == true) {
      await _currentUser?.reload();
      setState(() {
        _currentUser = _authService.currentUser;
      });
      await _loadUserProfile();
    }
  }



  // Edit phone
  Future<void> _editPhone() async {
    final originalPhone = _getPhoneNumber() != 'Not set' ? _getPhoneNumber() : null;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => EditPhoneDialog(
        currentPhone: originalPhone,
      ),
    );

    if (result == true) {
      // Phone number is updated immediately, just refresh the UI
      await _loadUserProfile();
    }
  }

  // Change password
  Future<void> _changePassword() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const ChangePasswordDialog(),
    );

    if (result == true) {
      // Password change successful, no need to reload user data
    }
  }

  // Helper methods
  String _getPhoneNumber() {
    return _userProfile?['phoneNumber'] ?? 'Not set';
  }







  // UI Building methods
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
      ),
    );
  }

  Widget _buildEditableInfoCard(
    String label,
    String value,
    IconData icon,
    VoidCallback onEdit, {
    String? subtitle,
    bool isSetNow = false,
    String actionText = 'Edit',
    bool showEditButton = true,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryPink.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primaryPink, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: value == 'Not set' ? AppColors.textSecondary : AppColors.textDark,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.warningOrange,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (showEditButton)
            TextButton(
              onPressed: onEdit,
              style: TextButton.styleFrom(
                backgroundColor: isSetNow ? AppColors.primaryPink : AppColors.primaryPink.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
              child: Text(
                isSetNow ? 'Set Now' : actionText,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isSetNow ? Colors.white : AppColors.primaryPink,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryPink.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primaryPink, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


}
