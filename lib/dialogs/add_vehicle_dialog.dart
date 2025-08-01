import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../widgets/custom_dialog.dart';
import '../models/vehicle.dart';
import '../models/customer.dart';
import '../screens/vin_scanner_screen.dart';
import '../utils/validation_utils.dart';
import '../services/vin_decoder_service.dart';
import '../services/customer_service.dart';
import '../widgets/customer_selection_widget.dart';
import '../widgets/customer_creation_widget.dart';

class AddVehicleDialog extends StatefulWidget {
  final Function(Vehicle) onVehicleAdded;

  const AddVehicleDialog({
    super.key,
    required this.onVehicleAdded,
  });

  @override
  State<AddVehicleDialog> createState() => _AddVehicleDialogState();
}

enum AddVehicleStep {
  customerSelection,
  vehicleInformation,
  confirmation,
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
  final _notesController = TextEditingController();

  final CustomerService _customerService = CustomerService();

  bool _isLoading = false;
  AddVehicleStep _currentStep = AddVehicleStep.customerSelection;
  Customer? _selectedCustomer;
  bool _isCreatingCustomer = false;

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
    _notesController.dispose();
    super.dispose();
  }

  void _nextStep() {
    switch (_currentStep) {
      case AddVehicleStep.customerSelection:
        if (_selectedCustomer != null) {
          setState(() {
            _currentStep = AddVehicleStep.vehicleInformation;
          });
        }
        break;
      case AddVehicleStep.vehicleInformation:
        if (_formKey.currentState!.validate()) {
          setState(() {
            _currentStep = AddVehicleStep.confirmation;
          });
        }
        break;
      case AddVehicleStep.confirmation:
        _addVehicle();
        break;
    }
  }

  void _previousStep() {
    switch (_currentStep) {
      case AddVehicleStep.vehicleInformation:
        setState(() {
          _currentStep = AddVehicleStep.customerSelection;
        });
        break;
      case AddVehicleStep.confirmation:
        setState(() {
          _currentStep = AddVehicleStep.vehicleInformation;
        });
        break;
      case AddVehicleStep.customerSelection:
        // Can't go back from first step
        break;
    }
  }

  void _onCustomerSelected(Customer? customer) {
    setState(() {
      _selectedCustomer = customer;
    });
  }

  void _onCreateNewCustomer() {
    setState(() {
      _isCreatingCustomer = true;
    });
  }

  void _onCustomerCreated(Customer customer) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final customerId = await _customerService.createCustomer(customer);
      final createdCustomer = customer.copyWith(id: customerId);

      setState(() {
        _selectedCustomer = createdCustomer;
        _isCreatingCustomer = false;
        _isLoading = false;
        _currentStep = AddVehicleStep.vehicleInformation;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create customer: ${e.toString()}'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  void _onCancelCustomerCreation() {
    setState(() {
      _isCreatingCustomer = false;
    });
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
    if (_selectedCustomer == null) return;

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
        customerId: _selectedCustomer!.id,
        customerName: _selectedCustomer!.fullName,
        customerPhone: _selectedCustomer!.phone,
        customerEmail: _selectedCustomer!.email,
        createdAt: DateTime.now(),
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      widget.onVehicleAdded(newVehicle);
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppColors.errorRed,
        ),
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
      title: _getStepTitle(),
      width: MediaQuery.of(context).size.width * 0.92,
      content: _buildStepContent(),
      actions: _buildStepActions(),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case AddVehicleStep.customerSelection:
        return _isCreatingCustomer ? 'Create New Customer' : 'Add New Vehicle - Select Customer';
      case AddVehicleStep.vehicleInformation:
        return 'Add New Vehicle - Vehicle Information';
      case AddVehicleStep.confirmation:
        return 'Add New Vehicle - Confirmation';
    }
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case AddVehicleStep.customerSelection:
        return _isCreatingCustomer
            ? CustomerCreationWidget(
                onCustomerCreated: _onCustomerCreated,
                onCancel: _onCancelCustomerCreation,
                isLoading: _isLoading,
              )
            : CustomerSelectionWidget(
                selectedCustomer: _selectedCustomer,
                onCustomerSelected: _onCustomerSelected,
                onCreateNewCustomer: _onCreateNewCustomer,
              );
      case AddVehicleStep.vehicleInformation:
        return _buildVehicleInformationStep();
      case AddVehicleStep.confirmation:
        return _buildConfirmationStep();
    }
  }

  List<Widget> _buildStepActions() {
    switch (_currentStep) {
      case AddVehicleStep.customerSelection:
        if (_isCreatingCustomer) {
          return []; // Customer creation widget handles its own buttons
        }
        return [
          SecondaryButton(
            text: 'Cancel',
            onPressed: () => Navigator.of(context).pop(),
          ),
          PrimaryButton(
            text: 'Next',
            onPressed: _selectedCustomer != null ? _nextStep : null,
          ),
        ];
      case AddVehicleStep.vehicleInformation:
        return [
          SecondaryButton(
            text: 'Back',
            onPressed: _previousStep,
          ),
          PrimaryButton(
            text: 'Next',
            onPressed: _nextStep,
          ),
        ];
      case AddVehicleStep.confirmation:
        return [
          SecondaryButton(
            text: 'Back',
            onPressed: _previousStep,
          ),
          PrimaryButton(
            text: 'Add Vehicle',
            onPressed: _nextStep,
            isLoading: _isLoading,
          ),
        ];
    }
  }

  Widget _buildVehicleInformationStep() {
    return Form(
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

              // Notes Section
              _buildSectionHeader(
                'Additional Notes',
                Icons.note,
                'Optional notes about the vehicle',
              ),
              const SizedBox(height: 24),

              CustomTextField(
                label: 'Additional Notes (Optional)',
                hint: 'Any special instructions, vehicle condition notes, or customer preferences...',
                controller: _notesController,
                maxLines: 3,
              ),

              const SizedBox(height: 8),
            ],
          ),
        );
  }

  Widget _buildConfirmationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Customer Information Summary
        _buildSectionHeader(
          'Customer Information',
          Icons.person,
          'Selected customer details',
        ),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _selectedCustomer?.fullName ?? 'Unknown Customer',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _selectedCustomer?.phone ?? '',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              if (_selectedCustomer?.email.isNotEmpty == true)
                Text(
                  _selectedCustomer!.email,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Vehicle Information Summary
        _buildSectionHeader(
          'Vehicle Information',
          Icons.directions_car,
          'Vehicle details to be added',
        ),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildConfirmationRow('Make', _makeController.text),
              _buildConfirmationRow('Model', _modelController.text),
              _buildConfirmationRow('Year', _yearController.text),
              _buildConfirmationRow('License Plate', _licensePlateController.text),
              _buildConfirmationRow('VIN', _vinController.text),
              _buildConfirmationRow('Color', _colorController.text),
              _buildConfirmationRow('Mileage', '${_mileageController.text} miles'),
              if (_notesController.text.isNotEmpty)
                _buildConfirmationRow('Notes', _notesController.text),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmationRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
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
