import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../widgets/custom_dialog.dart';
import '../models/customer.dart';
import '../services/customer_service.dart';

class AddCustomerDialog extends StatefulWidget {
  final Function(Customer) onCustomerAdded;

  const AddCustomerDialog({
    super.key,
    required this.onCustomerAdded,
  });

  @override
  State<AddCustomerDialog> createState() => _AddCustomerDialogState();
}

class _AddCustomerDialogState extends State<AddCustomerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipCodeController = TextEditingController();
  final _notesController = TextEditingController();

  final CustomerService _customerService = CustomerService();

  String _preferredContactMethod = 'phone';
  String? _preferredMechanic;
  String? _preferredServiceTime;
  bool _receivePromotions = true;
  bool _receiveReminders = true;
  bool _isLoading = false;

  final List<String> _contactMethods = ['phone', 'email', 'text'];
  final List<String> _mechanics = [
    'Lim Wei Ming',
    'Ahmad bin Hassan',
    'Raj Kumar',
    'Muhammad Faiz bin Omar',
    'Siti Nurhaliza',
    'Tan Cheng Lock',
    'Priya Sharma',
  ];
  final List<String> _serviceTimes = ['morning', 'afternoon', 'evening'];

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _addCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final newCustomer = Customer(
        id: '', // Firebase will generate the ID
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim().toLowerCase(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        city: _cityController.text.trim().isEmpty
            ? null
            : _cityController.text.trim(),
        state: _stateController.text.trim().isEmpty
            ? null
            : _stateController.text.trim(),
        zipCode: _zipCodeController.text.trim().isEmpty
            ? null
            : _zipCodeController.text.trim(),
        createdAt: DateTime.now(),
        preferences: CustomerPreferences(
          preferredContactMethod: _preferredContactMethod,
          receivePromotions: _receivePromotions,
          receiveReminders: _receiveReminders,
          preferredMechanic: _preferredMechanic,
          preferredServiceTime: _preferredServiceTime,
        ),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      // Create customer in Firebase
      final customerId = await _customerService.createCustomer(newCustomer);

      // Call the callback with the created customer
      final createdCustomer = newCustomer.copyWith(id: customerId);
      widget.onCustomerAdded(createdCustomer);

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to add customer: ${e.toString()}',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomDialog(
      title: 'Add New Customer',
      width: MediaQuery.of(context).size.width * 0.9,
      content: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personal Information',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    label: 'First Name',
                    hint: 'John',
                    controller: _firstNameController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter first name';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomTextField(
                    label: 'Last Name',
                    hint: 'Doe',
                    controller: _lastNameController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter last name';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    label: 'Email Address',
                    hint: 'john.doe@email.com',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter email';
                      }
                      if (!value.contains('@')) {
                        return 'Invalid email';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomTextField(
                    label: 'Phone Number',
                    hint: '012-345-6789',
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter phone number';
                      }
                      // Validate Malaysian phone number format
                      if (!RegExp(r'^01[0-9]-\d{3,4}-\d{4}$').hasMatch(value)) {
                        return 'Please enter valid Malaysian phone (e.g., 012-345-6789)';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Text(
              'Address (Optional)',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 16),

            CustomTextField(
              label: 'Street Address',
              hint: 'No. 15, Jalan Bukit Bintang',
              controller: _addressController,
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: CustomTextField(
                    label: 'City',
                    hint: 'Kuala Lumpur',
                    controller: _cityController,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomTextField(
                    label: 'State',
                    hint: 'Selangor',
                    controller: _stateController,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomTextField(
                    label: 'Postcode',
                    hint: '50200',
                    controller: _zipCodeController,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        // Validate Malaysian postcode format (5 digits)
                        if (!RegExp(r'^\d{5}$').hasMatch(value)) {
                          return 'Please enter valid postcode (5 digits)';
                        }
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Text(
              'Preferences',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: CustomDropdown<String>(
                    label: 'Preferred Contact Method',
                    value: _preferredContactMethod,
                    items: _contactMethods.map((method) {
                      return DropdownMenuItem(
                        value: method,
                        child: Text(method.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _preferredContactMethod = value!;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomDropdown<String>(
                    label: 'Preferred Mechanic',
                    value: _preferredMechanic,
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('No Preference'),
                      ),
                      ..._mechanics.map((mechanic) {
                        return DropdownMenuItem(
                          value: mechanic,
                          child: Text(mechanic),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _preferredMechanic = value;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: CustomDropdown<String>(
                    label: 'Preferred Service Time',
                    value: _preferredServiceTime,
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('No Preference'),
                      ),
                      ..._serviceTimes.map((time) {
                        return DropdownMenuItem(
                          value: time,
                          child: Text(time.toUpperCase()),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _preferredServiceTime = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Container()), // Empty space for alignment
              ],
            ),
            const SizedBox(height: 16),

            // Checkboxes
            Row(
              children: [
                Checkbox(
                  value: _receivePromotions,
                  onChanged: (value) {
                    setState(() {
                      _receivePromotions = value ?? false;
                    });
                  },
                  activeColor: AppColors.primaryPink,
                ),
                Expanded(
                  child: Text(
                    'Receive promotional offers',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Checkbox(
                  value: _receiveReminders,
                  onChanged: (value) {
                    setState(() {
                      _receiveReminders = value ?? false;
                    });
                  },
                  activeColor: AppColors.primaryPink,
                ),
                Expanded(
                  child: Text(
                    'Receive service reminders',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            CustomTextField(
              label: 'Notes (Optional)',
              hint: 'Additional information about the customer...',
              controller: _notesController,
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        SecondaryButton(
          text: 'Cancel',
          onPressed: () => Navigator.of(context).pop(),
        ),
        PrimaryButton(
          text: 'Add Customer',
          onPressed: _addCustomer,
          isLoading: _isLoading,
        ),
      ],
    );
  }
}
