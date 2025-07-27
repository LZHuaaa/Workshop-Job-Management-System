import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../widgets/custom_dialog.dart';
import '../models/customer.dart';
import '../models/service_record.dart';

class AddServiceDialog extends StatefulWidget {
  final Customer customer;
  final Function(ServiceRecord) onServiceAdded;

  const AddServiceDialog({
    super.key,
    required this.customer,
    required this.onServiceAdded,
  });

  @override
  State<AddServiceDialog> createState() => _AddServiceDialogState();
}

class _AddServiceDialogState extends State<AddServiceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _serviceTypeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _costController = TextEditingController();
  final _mileageController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedVehicleId;
  String? _selectedMechanic;
  DateTime _serviceDate = DateTime.now();
  DateTime? _nextServiceDue;
  ServiceStatus _status = ServiceStatus.completed;
  List<String> _selectedServices = [];
  List<String> _selectedParts = [];
  bool _isLoading = false;

  final List<String> _serviceTypes = [
    'Oil Change',
    'Brake Service',
    'Transmission Service',
    'Engine Repair',
    'Air Conditioning',
    'Tire Service',
    'Battery Service',
    'Inspection',
    'General Maintenance',
    'Other',
  ];

  final List<String> _availableServices = [
    'Oil Change',
    'Oil Filter',
    'Air Filter',
    'Brake Pad Replacement',
    'Brake Fluid Flush',
    'Brake Inspection',
    'ATF Change',
    'Transmission Filter',
    'Transmission Inspection',
    'Engine Diagnostic',
    'Spark Plugs',
    'Battery Test',
    'Tire Rotation',
    'Wheel Alignment',
    'Basic Inspection',
    'Safety Inspection',
  ];

  final List<String> _availableParts = [
    'Oil Filter',
    'Air Filter',
    'Cabin Filter',
    'Front Brake Pads',
    'Rear Brake Pads',
    'Brake Fluid',
    'ATF',
    'Engine Oil',
    'Spark Plugs',
    'Battery',
    'Wiper Blades',
    'Transmission Filter',
  ];

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
    if (widget.customer.vehicleIds.isNotEmpty) {
      _selectedVehicleId = widget.customer.vehicleIds.first;
    }
  }

  @override
  void dispose() {
    _serviceTypeController.dispose();
    _descriptionController.dispose();
    _costController.dispose();
    _mileageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _addService() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    final newService = ServiceRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      customerId: widget.customer.id,
      vehicleId: _selectedVehicleId ?? '',
      serviceDate: _serviceDate,
      serviceType: _serviceTypeController.text,
      description: _descriptionController.text,
      servicesPerformed: _selectedServices,
      cost: double.tryParse(_costController.text) ?? 0.0,
      mechanicName: _selectedMechanic ?? '',
      status: _status,
      nextServiceDue: _nextServiceDue,
      mileage: int.tryParse(_mileageController.text) ?? 0,
      partsReplaced: _selectedParts,
      notes: _notesController.text,
    );

    widget.onServiceAdded(newService);

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Service record added successfully!',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: AppColors.successGreen,
        ),
      );
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _serviceDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryPink,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _serviceDate && mounted) {
      setState(() {
        _serviceDate = picked;
      });
    }
  }

  Future<void> _selectNextServiceDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _nextServiceDue ?? DateTime.now().add(const Duration(days: 90)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryPink,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _nextServiceDue = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomDialog(
      title: 'Add Service Record',
      width: MediaQuery.of(context).size.width * 0.95,
      content: LayoutBuilder(
        builder: (context, constraints) {
          return Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Service Type and Vehicle
                Row(
                  children: [
                    Expanded(
                      child: CustomDropdown<String>(
                        label: 'Service Type',
                        value: _serviceTypeController.text.isEmpty
                            ? null
                            : _serviceTypeController.text,
                        items: _serviceTypes.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _serviceTypeController.text = value ?? '';
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomDropdown<String>(
                        label: 'Vehicle',
                        value: _selectedVehicleId,
                        items: widget.customer.vehicleIds.map((vehicleId) {
                          return DropdownMenuItem(
                            value: vehicleId,
                            child: Text('Vehicle $vehicleId'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedVehicleId = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Service Date and Cost
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Service Date',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: _selectDate,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.textLight),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 18,
                                    color: AppColors.primaryPink,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    DateFormat('MMM d, y').format(_serviceDate),
                                    style: GoogleFonts.poppins(fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomTextField(
                        label: 'Cost (RM)',
                        hint: '0.00',
                        controller: _costController,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter cost';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Please enter valid amount';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Description
                CustomTextField(
                  label: 'Description',
                  hint: 'Brief description of the service...',
                  controller: _descriptionController,
                  maxLines: 2,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter service description';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Mechanic and Mileage
                Row(
                  children: [
                    Expanded(
                      child: CustomDropdown<String>(
                        label: 'Mechanic',
                        value: _selectedMechanic,
                        items: _mechanics.map((mechanic) {
                          return DropdownMenuItem(
                            value: mechanic,
                            child: Text(mechanic),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedMechanic = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomTextField(
                        label: 'Mileage',
                        hint: 'Current mileage',
                        controller: _mileageController,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            if (int.tryParse(value) == null) {
                              return 'Please enter valid mileage';
                            }
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Notes
                CustomTextField(
                  label: 'Notes (Optional)',
                  hint: 'Additional notes about the service...',
                  controller: _notesController,
                  maxLines: 2,
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
          text: 'Add Service',
          onPressed: _addService,
          isLoading: _isLoading,
        ),
      ],
    );
  }
}
