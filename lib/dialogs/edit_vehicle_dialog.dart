import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../widgets/custom_dialog.dart';
import '../models/vehicle.dart';
import '../models/customer.dart';
import '../screens/vin_scanner_screen.dart';
import '../services/vin_decoder_service.dart';
import '../services/customer_service.dart';
import '../utils/validation_utils.dart';
import '../widgets/customer_selection_widget.dart';
import '../widgets/customer_creation_widget.dart';

enum EditVehicleStep {
  customerSelection,
  vehicleInformation,
  confirmation,
}

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
  late TextEditingController _notesController;

  final CustomerService _customerService = CustomerService();
  
  bool _isLoading = false;
  EditVehicleStep _currentStep = EditVehicleStep.customerSelection;
  Customer? _selectedCustomer;
  bool _isCreatingCustomer = false;
  bool _allowCustomerChange = false;

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
    'Brown',
    'Orange',
    'Yellow',
    'Purple',
    'Pink',
    'Gold',
    'Beige',
    'Maroon'
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

    // Initialize customer information if available
    if (widget.vehicle.customerName != null) {
      _selectedCustomer = Customer(
        id: widget.vehicle.customerId,
        firstName: widget.vehicle.customerName?.split(' ').first ?? '',
        lastName: widget.vehicle.customerName?.split(' ').skip(1).join(' ') ?? '',
        email: widget.vehicle.customerEmail ?? '',
        phone: widget.vehicle.customerPhone ?? '',
        createdAt: DateTime.now(),
        preferences: CustomerPreferences(
          preferredContactMethod: 'phone',
          receivePromotions: true,
          receiveReminders: true,
        ),
      );
    }

    // Start with vehicle information step since customer is already selected
    _currentStep = EditVehicleStep.vehicleInformation;
    _notesController = TextEditingController(text: widget.vehicle.notes ?? '');

    // Add VIN change listener for auto-decoding
    _vinController.addListener(_onVinChanged);
  }

  void _onVinChanged() {
    final vin = _vinController.text.trim();
    if (vin.length == 17) {
      _decodeVin(vin);
    }
  }

  void _decodeVin(String vin) {
    final result = VinDecoderService.decodeVin(vin);
    if (result.isValid && result.make != null && result.year != null) {
      setState(() {
        if (result.make != null && _makes.contains(result.make)) {
          _makeController.text = result.make!;
        }
        if (result.year != null) {
          _yearController.text = result.year.toString();
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('VIN decoded successfully!'),
          backgroundColor: AppColors.successGreen,
        ),
      );
    }
  }

  @override
  void dispose() {
    _vinController.removeListener(_onVinChanged);
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _colorController.dispose();
    _licensePlateController.dispose();
    _vinController.dispose();
    _mileageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _nextStep() {
    switch (_currentStep) {
      case EditVehicleStep.customerSelection:
        if (_selectedCustomer != null) {
          setState(() {
            _currentStep = EditVehicleStep.vehicleInformation;
          });
        }
        break;
      case EditVehicleStep.vehicleInformation:
        if (_formKey.currentState!.validate()) {
          setState(() {
            _currentStep = EditVehicleStep.confirmation;
          });
        }
        break;
      case EditVehicleStep.confirmation:
        _updateVehicle();
        break;
    }
  }

  void _previousStep() {
    switch (_currentStep) {
      case EditVehicleStep.vehicleInformation:
        setState(() {
          _currentStep = EditVehicleStep.customerSelection;
        });
        break;
      case EditVehicleStep.confirmation:
        setState(() {
          _currentStep = EditVehicleStep.vehicleInformation;
        });
        break;
      case EditVehicleStep.customerSelection:
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
        _currentStep = EditVehicleStep.vehicleInformation;
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

  void _enableCustomerChange() {
    setState(() {
      _allowCustomerChange = true;
      _currentStep = EditVehicleStep.customerSelection;
    });
  }

  void _updateVehicle() async {
    if (_selectedCustomer == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedVehicle = widget.vehicle.copyWith(
        make: _makeController.text,
        model: _modelController.text,
        year: int.parse(_yearController.text),
        color: _colorController.text,
        licensePlate: _licensePlateController.text,
        vin: _vinController.text,
        mileage: int.parse(_mileageController.text),
        customerId: _selectedCustomer!.id,
        customerName: _selectedCustomer!.fullName,
        customerPhone: _selectedCustomer!.phone,
        customerEmail: _selectedCustomer!.email,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      // Call the callback function - the parent will handle Firebase update
      await widget.onVehicleUpdated(updatedVehicle);

      // Only pop if the widget is still mounted
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating vehicle: ${e.toString()}'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
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
      case EditVehicleStep.customerSelection:
        return _isCreatingCustomer ? 'Create New Customer' : 'Edit Vehicle - Change Customer';
      case EditVehicleStep.vehicleInformation:
        return 'Edit Vehicle - Vehicle Information';
      case EditVehicleStep.confirmation:
        return 'Edit Vehicle - Confirmation';
    }
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case EditVehicleStep.customerSelection:
        return _buildCustomerSelectionStep();
      case EditVehicleStep.vehicleInformation:
        return _buildVehicleInformationStep();
      case EditVehicleStep.confirmation:
        return _buildConfirmationStep();
    }
  }

  List<Widget> _buildStepActions() {
    switch (_currentStep) {
      case EditVehicleStep.customerSelection:
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
      case EditVehicleStep.vehicleInformation:
        return [
          SecondaryButton(
            text: _allowCustomerChange ? 'Back' : 'Change',
            onPressed: _allowCustomerChange ? _previousStep : _enableCustomerChange,
          ),
          PrimaryButton(
            text: 'Next',
            onPressed: _nextStep,
          ),
        ];
      case EditVehicleStep.confirmation:
        return [
          SecondaryButton(
            text: 'Back',
            onPressed: _previousStep,
          ),
          PrimaryButton(
            text: 'Update Vehicle',
            onPressed: _nextStep,
            isLoading: _isLoading,
          ),
        ];
    }
  }

  Widget _buildCustomerSelectionStep() {
    if (_isCreatingCustomer) {
      return CustomerCreationWidget(
        onCustomerCreated: _onCustomerCreated,
        onCancel: _onCancelCustomerCreation,
        isLoading: _isLoading,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
     
        CustomerSelectionWidget(
          selectedCustomer: _selectedCustomer,
          onCustomerSelected: _onCustomerSelected,
          onCreateNewCustomer: _onCreateNewCustomer,
        ),
      ],
    );
  }

  Widget _buildVehicleInformationStep() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current Customer Info (Read-only)
          if (_selectedCustomer != null) ...[
            _buildSectionHeader(
              'Current Customer',
              Icons.person,
              'Associated customer for this vehicle',
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderColor),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primaryPink.withOpacity(0.2),
                    child: Text(
                      _selectedCustomer!.firstName.isNotEmpty
                          ? _selectedCustomer!.firstName[0].toUpperCase()
                          : '?',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryPink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedCustomer!.fullName,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _selectedCustomer!.phone,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (_selectedCustomer!.email.isNotEmpty)
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
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],

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
                child: _buildMakeField(),
              ),
              const SizedBox(width: 16),
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
              const SizedBox(width: 16),
              Expanded(
                child: CustomTextField(
                  label: 'License Plate',
                  hint: 'e.g., ABC-1234',
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
              const SizedBox(width: 16),
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

          // VIN Section with Scanner - IMPROVED LAYOUT
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
            label: 'Notes',
            hint: 'Any additional notes about the vehicle...',
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
          'Associated customer details',
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
          'Updated Vehicle Info',
          Icons.directions_car,
          'Vehicle details to be updated',
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
            width: 85,
            child: Text(
              '$label:',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 3,
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  Widget _buildSectionHeader(String title, IconData icon, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: AppColors.primaryPink,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildModelField() {
    final suggestedModels = _makeController.text.isNotEmpty
        ? VinDecoderService.getSuggestedModels(_makeController.text)
        : <String>[];
    
    bool _modelSelected = _modelController.text.isNotEmpty;

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
                    if (mounted) {
                      setState(() {
                        _modelController.text = value;
                      });
                    }
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
        if (suggestedModels.isNotEmpty && !_modelSelected) ...[
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: suggestedModels.take(4).map((model) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      if (mounted) {
                        setState(() {
                          _modelController.text = model;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryPink.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
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
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }

  // IMPROVED VIN SECTION LAYOUT (matching add vehicle form)
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
                    _decodeVin(value);
                  }
                },
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => _decodeVin(_vinController.text),
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

  void _scanVIN() async {
    // Navigate to VIN scanner screen (following add vehicle pattern)
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => VINScannerScreen(
          onVINScanned: (vin) {
            setState(() {
              _vinController.text = vin;
            });
            _decodeVin(vin);
          },
        ),
      ),
    );
  }

  List<String> _getModelsForMake(String make) {
    final makeModels = {
      'Toyota': ['Camry', 'Corolla', 'RAV4', 'Highlander', 'Prius', 'Tacoma', 'Tundra', 'Sienna', '4Runner', 'Sequoia', 'Venza', 'C-HR', 'Avalon', 'Yaris'],
      'Honda': ['Civic', 'Accord', 'CR-V', 'Pilot', 'Fit', 'Ridgeline', 'Passport', 'HR-V', 'Insight', 'Clarity', 'Odyssey', 'Element', 'Prelude', 'S2000'],
      'Ford': ['F-150', 'Escape', 'Explorer', 'Mustang', 'Focus', 'Fusion', 'Edge', 'Expedition', 'Bronco', 'Ranger', 'Transit', 'EcoSport', 'Fiesta', 'Taurus'],
      'Chevrolet': ['Silverado', 'Equinox', 'Malibu', 'Traverse', 'Camaro', 'Cruze', 'Tahoe', 'Suburban', 'Colorado', 'Blazer', 'Trax', 'Spark', 'Impala', 'Corvette'],
      'Nissan': ['Altima', 'Sentra', 'Rogue', 'Pathfinder', 'Frontier', 'Titan', 'Murano', 'Maxima', 'Versa', 'Leaf', 'Armada', 'Juke', '370Z', 'GT-R'],
      'BMW': ['3 Series', '5 Series', 'X3', 'X5', 'X1', '7 Series', 'Z4', 'X7', 'X6', '4 Series', '6 Series', '8 Series', 'i3', 'i8'],
      'Mercedes-Benz': ['C-Class', 'E-Class', 'S-Class', 'GLC', 'GLE', 'A-Class', 'CLA', 'GLA', 'GLB', 'GLS', 'G-Class', 'AMG GT', 'SL', 'CLS'],
      'Audi': ['A4', 'A6', 'Q5', 'Q7', 'A3', 'Q3', 'A8', 'Q8', 'TT', 'RS', 'S4', 'S6', 'SQ5', 'e-tron'],
      'Volkswagen': ['Jetta', 'Passat', 'Tiguan', 'Atlas', 'Golf', 'Beetle', 'Arteon', 'ID.4', 'Taos', 'Touareg', 'Polo', 'Scirocco', 'Eos', 'CC'],
      'Hyundai': ['Elantra', 'Sonata', 'Tucson', 'Santa Fe', 'Accent', 'Genesis', 'Palisade', 'Venue', 'Kona', 'Veloster', 'Azera', 'Equus', 'i30', 'i40'],
      'Kia': ['Forte', 'K5', 'Sportage', 'Telluride', 'Sorento', 'Rio', 'Stinger', 'Soul', 'Niro', 'Cadenza', 'K900', 'Borrego', 'Spectra', 'Optima'],
      'Mazda': ['CX-5', 'CX-30', 'Mazda3', 'Mazda6', 'CX-9', 'MX-5 Miata', 'CX-3', 'RX-8', 'RX-7', 'Protege', '626', '323', '929', 'MPV'],
      'Subaru': ['Outback', 'Forester', 'Impreza', 'Legacy', 'Crosstrek', 'Ascent', 'WRX', 'BRZ', 'Tribeca', 'Baja', 'SVX', 'Justy', 'Loyale', 'XT'],
      'Lexus': ['ES', 'RX', 'NX', 'LS', 'GS', 'IS', 'LC', 'RC', 'GX', 'LX', 'LFA', 'HS', 'CT', 'SC'],
      'Acura': ['TLX', 'RDX', 'MDX', 'ILX', 'RLX', 'NSX', 'CL', 'TSX', 'RSX', 'Integra', 'Legend', 'Vigor', 'Vigor', 'CL'],
      'Proton': ['Saga', 'Persona', 'Iriz', 'Preve', 'Suprima S', 'Exora', 'X70', 'X50', 'Satria', 'Wira', 'Waja', 'Perdana', 'Inspira', 'Gen-2'],
    };

    return makeModels[make] ?? [];
  }

  Widget _buildMakeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextField(
          label: 'Make',
          hint: 'e.g., Honda, Toyota, or enter custom',
          controller: _makeController,
          validator: (value) => ValidationUtils.validateRequired(value, 'make'),
          onChanged: (value) {
            if (mounted) {
              setState(() {
                // Clear model when make changes
                if (_modelController.text.isNotEmpty) {
                  _modelController.clear();
                }
              });
            }
          },
          suffixIcon: PopupMenuButton<String>(
            icon: Icon(
              Icons.arrow_drop_down,
              color: AppColors.primaryPink,
            ),
            tooltip: 'Select from common makes',
            onSelected: (value) {
              if (mounted) {
                setState(() {
                  _makeController.text = value;
                  // Clear model when make changes
                  _modelController.clear();
                });
              }
            },
            itemBuilder: (context) => _makes
                .map((make) => PopupMenuItem(
                      value: make,
                      child: Text(make),
                    ))
                .toList(),
          ),
        ),
        // Show custom make indicator when user enters a non-standard make
        if (_makeController.text.isNotEmpty && !_makes.contains(_makeController.text)) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryPink.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: AppColors.primaryPink,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Custom make: "${_makeController.text}"',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.primaryPink,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        // Show popular makes as horizontal chips only when field is empty  
        if (_makeController.text.isEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _makes.take(4).map((make) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: GestureDetector(
                          onTap: () {
                            if (mounted) {
                              setState(() {
                                _makeController.text = make;
                                _modelController.clear();
                              });
                            }
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
                              make,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: AppColors.primaryPink,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}