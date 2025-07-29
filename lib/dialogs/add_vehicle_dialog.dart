import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../widgets/custom_dialog.dart';
import '../models/vehicle.dart';
import '../screens/vin_scanner_screen.dart';
import '../utils/validation_utils.dart';
import '../services/vin_decoder_service.dart';

class AddVehicleDialog extends StatefulWidget {
  final Function(Vehicle) onVehicleAdded;

  const AddVehicleDialog({
    super.key,
    required this.onVehicleAdded,
  });

  @override
  State<AddVehicleDialog> createState() => _AddVehicleDialogState();
}

class _AddVehicleDialogState extends State<AddVehicleDialog> {
  final _formKey = GlobalKey<FormState>();
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _licensePlateController = TextEditingController();
  final _vinController = TextEditingController();
  final _colorController = TextEditingController();
  final _mileageController = TextEditingController();
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _customerEmailController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isLoading = false;

  final List<String> _makes = [
    'Honda',
    'Toyota',
    'Ford',
    'Chevrolet',
    'BMW',
    'Mercedes-Benz',
    'Audi',
    'Nissan',
    'Hyundai',
    'Kia',
    'Volkswagen',
    'Mazda',
    'Subaru',
    'Lexus',
    'Acura',
    'Proton',
  ];

  final List<String> _colors = [
    'White',
    'Black',
    'Silver',
    'Gray',
    'Red',
    'Blue',
    'Green',
    'Brown',
    'Gold',
    'Yellow',
    'Orange',
    'Purple',
  ];

  @override
  void dispose() {
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _licensePlateController.dispose();
    _vinController.dispose();
    _colorController.dispose();
    _mileageController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _customerEmailController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _scanVIN() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => VINScannerScreen(
          onVINScanned: (vin) {
            setState(() {
              _vinController.text = vin;
            });
            _decodeVIN(vin);
          },
        ),
      ),
    );
  }

  void _decodeVIN(String vin) {
    if (vin.length == 17) {
      final result = VinDecoderService.decodeVin(vin);

      if (result.isValid) {
        setState(() {
          // Auto-populate make if decoded successfully
          if (result.make != null && _makes.contains(result.make)) {
            _makeController.text = result.make!;
          }

          // Auto-populate year if decoded successfully
          if (result.year != null) {
            _yearController.text = result.year.toString();
          }
        });

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'VIN decoded: ${result.make ?? 'Unknown'} ${result.year ?? ''}',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: AppColors.successGreen,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  Future<void> _addVehicle() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final newVehicle = Vehicle(
        id: '', // Firebase will generate
        make: _makeController.text,
        model: _modelController.text,
        year: int.parse(_yearController.text),
        licensePlate: _licensePlateController.text,
        vin: _vinController.text,
        color: _colorController.text,
        mileage: int.parse(_mileageController.text),
        customerId: '', // TODO: Link to actual customer
        customerName: _customerNameController.text,
        customerPhone: _customerPhoneController.text,
        customerEmail: _customerEmailController.text,
        createdAt: DateTime.now(),
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      widget.onVehicleAdded(newVehicle);
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomDialog(
      title: 'Add New Vehicle',
      width: MediaQuery.of(context).size.width * 0.92,
      content: Form(
        key: _formKey,
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Vehicle Information Section
              _buildSectionHeader(
                'Vehicle Information',
                Icons.directions_car,
                'Basic vehicle details',
              ),
              const SizedBox(height: 20),

              // Make and Model Row (Better spacing)
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
                          // Clear model when make changes
                          _modelController.clear();
                        });
                      },
                      validator: (value) => ValidationUtils.validateRequired(value, 'make'),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _buildModelField(),
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
                      validator: ValidationUtils.validateYear,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: CustomTextField(
                      label: 'License Plate',
                      hint: 'e.g., ABC 1234',
                      controller: _licensePlateController,
                      validator: ValidationUtils.validateLicensePlate,
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
                      validator: (value) => ValidationUtils.validateRequired(value, 'color'),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: CustomTextField(
                      label: 'Current Mileage',
                      hint: 'e.g., 50000',
                      controller: _mileageController,
                      keyboardType: TextInputType.number,
                      validator: ValidationUtils.validateMileage,
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
                'Vehicle owner details',
              ),
              const SizedBox(height: 24),

              // Customer Name (Full Width)
              CustomTextField(
                label: 'Customer Name',
                hint: 'Enter customer\'s full name',
                controller: _customerNameController,
                validator: (value) => ValidationUtils.validateName(value, 'Customer Name'),
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
                      validator: ValidationUtils.validatePhoneNumber,
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
                        return ValidationUtils.validateEmail(value);
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Notes Section
              CustomTextField(
                label: 'Additional Notes (Optional)',
                hint: 'Any special instructions, vehicle condition notes, or customer preferences...',
                controller: _notesController,
                maxLines: 3,
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      actions: [
        SecondaryButton(
          text: 'Cancel',
          onPressed: () => Navigator.of(context).pop(),
        ),
        PrimaryButton(
          text: 'Add Vehicle',
          onPressed: _addVehicle,
          isLoading: _isLoading,
        ),
      ],
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
                validator: ValidationUtils.validateVIN,
                onChanged: (value) {
                  if (value.length == 17) {
                    _decodeVIN(value);
                  }
                },
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => _decodeVIN(_vinController.text),
                      icon: Icon(
                        Icons.auto_fix_high,
                        color: AppColors.primaryPink,
                        size: 20,
                      ),
                      tooltip: 'Decode VIN',
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.primaryPink.withOpacity(0.1),
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
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
                  ],
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

  Widget _buildModelField() {
    final suggestedModels = _makeController.text.isNotEmpty
        ? VinDecoderService.getSuggestedModels(_makeController.text)
        : <String>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextField(
          label: 'Model',
          hint: 'e.g., Civic, Camry',
          controller: _modelController,
          validator: (value) => ValidationUtils.validateName(value, 'Model'),
          suffixIcon: suggestedModels.isNotEmpty
              ? PopupMenuButton<String>(
                  icon: Icon(
                    Icons.arrow_drop_down,
                    color: AppColors.primaryPink,
                  ),
                  onSelected: (value) {
                    setState(() {
                      _modelController.text = value;
                    });
                  },
                  itemBuilder: (context) => suggestedModels
                      .map((model) => PopupMenuItem(
                            value: model,
                            child: Text(model),
                          ))
                      .toList(),
                )
              : null,
        ),
        if (suggestedModels.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: suggestedModels.take(6).map((model) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _modelController.text = model;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPink.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primaryPink.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    model,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.primaryPink,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
