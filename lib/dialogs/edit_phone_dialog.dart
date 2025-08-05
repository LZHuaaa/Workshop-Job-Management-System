import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../services/user_profile_service.dart';
import '../models/country_code.dart';
import '../widgets/country_code_picker.dart';
import '../screens/auth/password_reset_request_screen.dart';

class EditPhoneDialog extends StatefulWidget {
  final String? currentPhone;

  const EditPhoneDialog({
    super.key,
    this.currentPhone,
  });

  @override
  State<EditPhoneDialog> createState() => _EditPhoneDialogState();
}

class _EditPhoneDialogState extends State<EditPhoneDialog> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _profileService = UserProfileService();
  bool _isLoading = false;
  bool _showPassword = false;
  CountryCode _selectedCountry = CountryCodeService.defaultCountry;

  @override
  void initState() {
    super.initState();
    _parseCurrentPhone();
  }

  void _parseCurrentPhone() {
    final currentPhone = widget.currentPhone ?? '';
    if (currentPhone.isNotEmpty) {
      // Try to extract country code from existing phone number
      for (final country in CountryCodeService.countries) {
        if (currentPhone.startsWith(country.dialCode)) {
          _selectedCountry = country;
          _phoneController.text = currentPhone.substring(country.dialCode.length).trim();
          return;
        }
      }
      // If no country code found, use the full number
      _phoneController.text = currentPhone;
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _updatePhone() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Combine country code with phone number
      final fullPhoneNumber = '${_selectedCountry.dialCode} ${_phoneController.text.trim()}';

      final result = await _profileService.updatePhoneNumber(
        fullPhoneNumber,
        _passwordController.text,
      );

      if (mounted) {
        if (result.isSuccess) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result.message,
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: AppColors.successGreen,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result.message,
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: AppColors.errorRed,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleForgotPassword() {
    // Navigate to password reset request screen from profile context
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PasswordResetRequestScreen(fromProfile: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.currentPhone == null ? 'Add Phone Number' : 'Edit Phone Number',
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'For security, changing your phone number requires email verification. You\'ll receive a verification email at your current email address. The change will take effect immediately after you click the verification link.',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CountryCodePicker(
                  selectedCountry: _selectedCountry,
                  onCountryChanged: (country) {
                    setState(() {
                      _selectedCountry = country;
                    });
                  },
                  enabled: !_isLoading,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      labelStyle: GoogleFonts.poppins(),
                      hintText: 'Enter phone number',
                      hintStyle: GoogleFonts.poppins(color: AppColors.textSecondary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppColors.primaryPink),
                      ),
                    ),
                    style: GoogleFonts.poppins(),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Phone number cannot be empty';
                      }

                      // Remove all non-digit characters for validation
                      final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');

                      // Check minimum length based on country
                      if (digitsOnly.length < 7) {
                        return 'Phone number is too short';
                      }

                      if (digitsOnly.length > 15) {
                        return 'Phone number is too long';
                      }

                      return null;
                    },
                    enabled: !_isLoading,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Select your country code and enter your phone number without the country code',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Current Password',
                labelStyle: GoogleFonts.poppins(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.primaryPink),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _showPassword ? Icons.visibility_off : Icons.visibility,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () {
                    setState(() {
                      _showPassword = !_showPassword;
                    });
                  },
                ),
              ),
              style: GoogleFonts.poppins(),
              obscureText: !_showPassword,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Current password is required for verification';
                }
                return null;
              },
              enabled: !_isLoading,
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _handleForgotPassword,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryPink,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Forgot Password?',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: GoogleFonts.poppins(color: AppColors.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _updatePhone,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryPink,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  widget.currentPhone == null ? 'Add' : 'Update',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
        ),
      ],
    );
  }
}
