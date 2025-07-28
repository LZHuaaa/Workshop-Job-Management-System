import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../widgets/custom_dialog.dart';
import '../models/vehicle.dart';

class EditVehicleDialog extends StatefulWidget {
  final Vehicle vehicle;
  final Function(Vehicle) onVehicleUpdated;

  const EditVehicleDialog({
    super.key,
    required this.vehicle,
    required this.onVehicleUpdated,
  });

  @override
  State<EditVehicleDialog> createState() => _EditVehicleDialogState();
}

class _EditVehicleDialogState extends State<EditVehicleDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _makeController;
  late TextEditingController _modelController;
  late TextEditingController _yearController;
  late TextEditingController _colorController;
  late TextEditingController _licensePlateController;
  late TextEditingController _vinController;
  late TextEditingController _mileageController;
  late TextEditingController _customerNameController;
  late TextEditingController _customerPhoneController;
  late TextEditingController _customerEmailController;
  late TextEditingController _notesController;
  bool _isLoading = false;

  final List<String> _makes = [
    'Toyota',
    'Honda',
    'Ford',
    'Chevrolet',
    'Nissan',
    'BMW',
    'Mercedes-Benz',
    'Audi',
    'Volkswagen',
    'Hyundai',
    'Kia',
    'Mazda',
    'Subaru',
    'Lexus',
    'Acura',
    'Proton'
  ];

  final List<String> _colors = [
    'White',
    'Black',
    'Silver',
    'Gray',
    'Red',
    'Blue',
    'Green',
    'Yellow',
    'Orange',
    'Purple',
    'Brown',
    'Gold',
    'Beige',
    'Maroon',
    'Navy'
  ];

  @override
  void initState() {
    super.initState();

    // Add vehicle's make to list if it's not already there
    if (!_makes.contains(widget.vehicle.make)) {
      _makes.add(widget.vehicle.make);
    }

    // Add vehicle's color to list if it's not already there
    if (!_colors.contains(widget.vehicle.color)) {
      _colors.add(widget.vehicle.color);
    }

    _makeController = TextEditingController(text: widget.vehicle.make);
    _modelController = TextEditingController(text: widget.vehicle.model);
    _yearController =
        TextEditingController(text: widget.vehicle.year.toString());
    _colorController = TextEditingController(text: widget.vehicle.color);
    _licensePlateController =
        TextEditingController(text: widget.vehicle.licensePlate);
    _vinController = TextEditingController(text: widget.vehicle.vin);
    _mileageController =
        TextEditingController(text: widget.vehicle.mileage.toString());
    _customerNameController =
        TextEditingController(text: widget.vehicle.customerName);
    _customerPhoneController =
        TextEditingController(text: widget.vehicle.customerPhone);
    _customerEmailController =
        TextEditingController(text: widget.vehicle.customerEmail);
    _notesController = TextEditingController(text: widget.vehicle.notes ?? '');
  }

  @override
  void dispose() {
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _colorController.dispose();
    _licensePlateController.dispose();
    _vinController.dispose();
    _mileageController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _customerEmailController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _updateVehicle() {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        final updatedVehicle = widget.vehicle.copyWith(
          make: _makeController.text,
          model: _modelController.text,
          year: int.parse(_yearController.text),
          color: _colorController.text,
          licensePlate: _licensePlateController.text,
          vin: _vinController.text,
          mileage: int.parse(_mileageController.text),
          customerName: _customerNameController.text,
          customerPhone: _customerPhoneController.text,
          customerEmail: _customerEmailController.text,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
        );

        widget.onVehicleUpdated(updatedVehicle);

        setState(() {
          _isLoading = false;
        });

        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Vehicle updated successfully',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    });
  }

  void _scanVIN() {
    // TODO: Implement VIN scanning functionality
    // For now, show a placeholder dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Row(
          children: [
            Icon(Icons.qr_code_scanner, color: AppColors.primaryPink),
            const SizedBox(width: 8),
            Text(
              'Scan VIN',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: Text(
          'VIN scanning functionality will be implemented here.\n\nThis would typically open the camera to scan a VIN barcode or QR code.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.poppins(color: AppColors.primaryPink),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white, // Explicit white background
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white, // Explicit white background
          borderRadius: BorderRadius.circular(16),
        ),
        width: MediaQuery.of(context).size.width * 0.92,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
          maxWidth: MediaQuery.of(context).size.width * 0.95,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primaryPink,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Edit Vehicle',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: Container(
                color: Colors.white, // Explicit white background
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Vehicle Information Section
                        _buildSectionHeader(
                          'Vehicle Information',
                          Icons.directions_car,
                          'Update vehicle details',
                        ),
                        const SizedBox(height: 20),

                        // Make and Model Row
                        Row(
                          children: [
                            Expanded(
                              child: CustomDropdown<String>(
                                label: 'Make',
                                value: _makeController.text.isEmpty
                                    ? null
                                    : _makeController.text,
                                items: _makes.map((make) {
                                  return DropdownMenuItem(
                                    value: make,
                                    child: Text(make),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _makeController.text = value ?? '';
                                  });
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please select make';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: CustomTextField(
                                label: 'Model',
                                hint: 'e.g., Civic, Camry',
                                controller: _modelController,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter model';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Year and License Plate Row
                        Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                label: 'Year',
                                hint: 'e.g., 2020',
                                controller: _yearController,
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter year';
                                  }
                                  final year = int.tryParse(value);
                                  if (year == null ||
                                      year < 1900 ||
                                      year > DateTime.now().year + 1) {
                                    return 'Invalid year';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: CustomTextField(
                                label: 'License Plate',
                                hint: 'e.g., ABC 1234',
                                controller: _licensePlateController,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter license plate';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Color and Mileage Row
                        Row(
                          children: [
                            Expanded(
                              child: CustomDropdown<String>(
                                label: 'Color',
                                value: _colorController.text.isEmpty
                                    ? null
                                    : _colorController.text,
                                items: _colors.map((color) {
                                  return DropdownMenuItem(
                                    value: color,
                                    child: Text(color),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _colorController.text = value ?? '';
                                  });
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please select color';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: CustomTextField(
                                label: 'Current Mileage',
                                hint: 'e.g., 50000',
                                controller: _mileageController,
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter mileage';
                                  }
                                  if (int.tryParse(value) == null) {
                                    return 'Invalid mileage';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // VIN Section with Scanner
                        _buildVINSection(),

                        const SizedBox(height: 32),

                        // Customer Information Section
                        _buildSectionHeader(
                          'Customer Information',
                          Icons.person,
                          'Update customer details',
                        ),
                        const SizedBox(height: 24),

                        // Customer Name (Full Width)
                        CustomTextField(
                          label: 'Customer Name',
                          hint: 'Enter customer\'s full name',
                          controller: _customerNameController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter customer name';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 24),

                        // Phone and Email Row
                        Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                label: 'Phone Number',
                                hint: 'e.g., (555) 123-4567',
                                controller: _customerPhoneController,
                                keyboardType: TextInputType.phone,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter phone number';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: CustomTextField(
                                label: 'Email Address',
                                hint: 'e.g., customer@email.com',
                                controller: _customerEmailController,
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
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Notes Section
                        CustomTextField(
                          label: 'Additional Notes (Optional)',
                          hint:
                              'Any special instructions, vehicle condition notes, or customer preferences...',
                          controller: _notesController,
                          maxLines: 3,
                        ),

                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SecondaryButton(
                    text: 'Cancel',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  PrimaryButton(
                    text: 'Update Vehicle',
                    onPressed: _updateVehicle,
                    isLoading: _isLoading,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryPink.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: AppColors.primaryPink,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 1,
          width: double.infinity,
          color: AppColors.backgroundLight,
        ),
      ],
    );
  }

  Widget _buildVINSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                label: 'Vehicle Identification Number (VIN)',
                hint: 'Enter 17-character VIN code',
                controller: _vinController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter VIN';
                  }
                  if (value.length != 17) {
                    return 'VIN must be 17 characters';
                  }
                  return null;
                },
                suffixIcon: IconButton(
                  onPressed: _scanVIN,
                  icon: Icon(
                    Icons.qr_code_scanner,
                    color: AppColors.primaryPink,
                    size: 20,
                  ),
                  tooltip: 'Scan VIN with camera',
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primaryPink.withOpacity(0.1),
                    padding: const EdgeInsets.all(8),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.backgroundLight.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'VIN is usually found on the dashboard, driver\'s door, or vehicle documents. Tap the scan icon to use your camera.',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
