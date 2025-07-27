import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../widgets/custom_dialog.dart';
import '../models/customer.dart';

class EditCustomerDialog extends StatefulWidget {
  final Customer customer;
  final Function(Customer) onCustomerUpdated;

  const EditCustomerDialog({
    super.key,
    required this.customer,
    required this.onCustomerUpdated,
  });

  @override
  State<EditCustomerDialog> createState() => _EditCustomerDialogState();
}

class _EditCustomerDialogState extends State<EditCustomerDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _cityController;
  late final TextEditingController _stateController;
  late final TextEditingController _zipCodeController;
  late final TextEditingController _notesController;

  String _selectedContactMethod = 'phone';
  bool _receivePromotions = true;
  bool _receiveReminders = true;
  String? _preferredMechanic;
  bool _isLoading = false;

  final List<String> _contactMethods = ['phone', 'email', 'text'];
  final List<String> _mechanics = [
    'Ahmad bin Hassan',
    'Siti Nurhaliza',
    'Lim Wei Ming',
    'Raj Kumar',
    'Muhammad Faiz bin Omar',
    'Tan Mei Ling',
    'Priya d/o Raman',
  ];

  @override
  void initState() {
    super.initState();

    // Initialize controllers with existing customer data
    _firstNameController =
        TextEditingController(text: widget.customer.firstName);
    _lastNameController = TextEditingController(text: widget.customer.lastName);
    _emailController = TextEditingController(text: widget.customer.email);
    _phoneController = TextEditingController(text: widget.customer.phone);
    _addressController = TextEditingController(text: widget.customer.address);
    _cityController = TextEditingController(text: widget.customer.city);
    _stateController = TextEditingController(text: widget.customer.state);
    _zipCodeController = TextEditingController(text: widget.customer.zipCode);
    _notesController = TextEditingController(text: widget.customer.notes ?? '');

    // Initialize preferences
    if (widget.customer.preferences != null) {
      _selectedContactMethod =
          widget.customer.preferences!.preferredContactMethod;
      _receivePromotions = widget.customer.preferences!.receivePromotions;
      _receiveReminders = widget.customer.preferences!.receiveReminders;
      _preferredMechanic = widget.customer.preferences!.preferredMechanic;
    }
  }

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

  Future<void> _updateCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    final updatedCustomer = widget.customer.copyWith(
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      email: _emailController.text,
      phone: _phoneController.text,
      address: _addressController.text,
      city: _cityController.text,
      state: _stateController.text,
      zipCode: _zipCodeController.text,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      preferences: CustomerPreferences(
        preferredContactMethod: _selectedContactMethod,
        receivePromotions: _receivePromotions,
        receiveReminders: _receiveReminders,
        preferredMechanic: _preferredMechanic,
      ),
    );

    widget.onCustomerUpdated(updatedCustomer);

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Customer updated successfully!',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: AppColors.successGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomDialog(
      title: 'Edit Customer',
      width: MediaQuery.of(context).size.width * 0.95,
      content: LayoutBuilder(
        builder: (context, constraints) {
          return Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name fields
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        label: 'First Name',
                        hint: 'Enter first name',
                        controller: _firstNameController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter first name';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomTextField(
                        label: 'Last Name',
                        hint: 'Enter last name',
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

                // Contact fields
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        label: 'Email',
                        hint: 'Enter email address',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter email';
                          }
                          if (!value.contains('@')) {
                            return 'Please enter valid email';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomTextField(
                        label: 'Phone',
                        hint: 'Enter phone number',
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter phone number';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Address
                CustomTextField(
                  label: 'Address',
                  hint: 'Enter address',
                  controller: _addressController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter address';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // City, State, Zip
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: CustomTextField(
                        label: 'City',
                        hint: 'Enter city',
                        controller: _cityController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter city';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: CustomTextField(
                        label: 'State',
                        hint: 'Enter state',
                        controller: _stateController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter state';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomTextField(
                        label: 'Zip Code',
                        hint: 'Enter zip',
                        controller: _zipCodeController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter zip code';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Preferences Section
                Text(
                  'Customer Preferences',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 12),

                // Contact Method Preference
                CustomDropdown<String>(
                  label: 'Preferred Contact Method',
                  value: _selectedContactMethod,
                  items: _contactMethods.map((method) {
                    return DropdownMenuItem(
                      value: method,
                      child: Row(
                        children: [
                          Icon(
                            method == 'phone'
                                ? Icons.phone
                                : method == 'email'
                                    ? Icons.email
                                    : Icons.sms,
                            size: 18,
                            color: AppColors.primaryPink,
                          ),
                          const SizedBox(width: 8),
                          Text(method.toUpperCase()),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedContactMethod = value!;
                    });
                  },
                ),

                const SizedBox(height: 16),

                // Preferred Mechanic
                CustomDropdown<String>(
                  label: 'Preferred Mechanic (Optional)',
                  value: _preferredMechanic,
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('No preference'),
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

                const SizedBox(height: 16),

                // Communication Preferences
                Row(
                  children: [
                    Expanded(
                      child: CheckboxListTile(
                        title: Text(
                          'Receive Promotions',
                          style: GoogleFonts.poppins(fontSize: 14),
                        ),
                        value: _receivePromotions,
                        onChanged: (value) {
                          setState(() {
                            _receivePromotions = value ?? false;
                          });
                        },
                        activeColor: AppColors.primaryPink,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    Expanded(
                      child: CheckboxListTile(
                        title: Text(
                          'Receive Reminders',
                          style: GoogleFonts.poppins(fontSize: 14),
                        ),
                        value: _receiveReminders,
                        onChanged: (value) {
                          setState(() {
                            _receiveReminders = value ?? false;
                          });
                        },
                        activeColor: AppColors.primaryPink,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Notes
                CustomTextField(
                  label: 'Notes (Optional)',
                  hint: 'Any additional notes about this customer...',
                  controller: _notesController,
                  maxLines: 3,
                ),
              ],
            ),
          );
        },
      ),
      actions: [
        SecondaryButton(
          text: 'Cancel',
          onPressed: () => Navigator.of(context).pop(),
        ),
        PrimaryButton(
          text: 'Update Customer',
          onPressed: _updateCustomer,
          isLoading: _isLoading,
        ),
      ],
    );
  }
}
