import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../services/admin_data_service.dart';
import '../widgets/hidden_admin_panel.dart';

class UserProfileScreen extends StatefulWidget {
  final String userName;
  final String email;
  final String contactNumber;
  final String password;
  final VoidCallback onLogout;

  const UserProfileScreen({
    super.key,
    required this.userName,
    required this.email,
    required this.contactNumber,
    required this.password,
    required this.onLogout,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  late TextEditingController _passwordController;
  bool _obscurePassword = true;
  bool _showPassword = false;
  bool _showOldPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  @override
  void initState() {
    super.initState();
    _passwordController = TextEditingController(text: widget.password);
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _savePassword() {
    // TODO: Implement password update logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Password Updated', style: GoogleFonts.poppins()),
        backgroundColor: AppColors.successGreen,
      ),
    );
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
                      child: Text(
                        widget.userName.isNotEmpty ? widget.userName[0] : '',
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryPink,
                        ),
                      ),
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
            _buildInfoRow('Username', widget.userName, Icons.person),
            const SizedBox(height: 16),
            _buildInfoRow('Email', widget.email, Icons.email),
            const SizedBox(height: 16),
            _buildInfoRow('Contact Number', widget.contactNumber, Icons.phone),
            const SizedBox(height: 16),
            _buildPasswordRow(),
            const Spacer(),
            Center(
              child: ElevatedButton.icon(
                onPressed: widget.onLogout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.errorRed,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.logout, color: Colors.white),
                label: Text('Logout',
                    style: GoogleFonts.poppins(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
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

  Widget _buildPasswordRow() {
    return Row(
      children: [
        Icon(Icons.lock, color: AppColors.primaryPink, size: 20),
        const SizedBox(width: 12),
        Text(
          'Password:',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _showPassword ? widget.password : '*' * widget.password.length,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          icon: Icon(_showPassword ? Icons.visibility : Icons.visibility_off,
              color: AppColors.primaryPink, size: 20),
          onPressed: () {
            setState(() {
              _showPassword = !_showPassword;
            });
          },
        ),
        GestureDetector(
          onTap: () {
            _showEditPasswordDialog();
          },
          child: Icon(Icons.edit, color: AppColors.primaryPink, size: 20),
        ),
      ],
    );
  }

  void _showEditPasswordDialog() {
    TextEditingController oldPasswordController = TextEditingController();
    TextEditingController newPasswordController = TextEditingController();
    TextEditingController confirmPasswordController = TextEditingController();
    bool showOld = false;
    bool showNew = false;
    bool showConfirm = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Edit Password', style: GoogleFonts.poppins()),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: oldPasswordController,
                    obscureText: !showOld,
                    decoration: InputDecoration(
                      labelText: 'Old Password',
                      suffixIcon: IconButton(
                        icon: Icon(
                            showOld ? Icons.visibility : Icons.visibility_off),
                        onPressed: () {
                          setState(() {
                            showOld = !showOld;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: newPasswordController,
                    obscureText: !showNew,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      suffixIcon: IconButton(
                        icon: Icon(
                            showNew ? Icons.visibility : Icons.visibility_off),
                        onPressed: () {
                          setState(() {
                            showNew = !showNew;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmPasswordController,
                    obscureText: !showConfirm,
                    decoration: InputDecoration(
                      labelText: 'Confirm New Password',
                      suffixIcon: IconButton(
                        icon: Icon(showConfirm
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: () {
                          setState(() {
                            showConfirm = !showConfirm;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancel', style: GoogleFonts.poppins()),
                ),
                ElevatedButton(
                  onPressed: () {
                    // TODO: Add validation and update logic
                    _passwordController.text = newPasswordController.text;
                    _savePassword();
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPink,
                  ),
                  child: Text('Save',
                      style: GoogleFonts.poppins(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
