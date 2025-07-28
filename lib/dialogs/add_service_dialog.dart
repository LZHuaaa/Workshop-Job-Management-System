import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../widgets/custom_dialog.dart';
import '../models/customer.dart';
import '../models/service_record.dart';
import '../models/inventory_usage.dart';
import '../models/inventory_item.dart';
import '../services/inventory_usage_service.dart';

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
  final InventoryUsageService _usageService = InventoryUsageService();

  String? _selectedVehicleId;
  String? _selectedMechanic;
  DateTime _serviceDate = DateTime.now();
  DateTime? _nextServiceDue;
  ServiceStatus _status = ServiceStatus.completed;
  List<String> _selectedServices = [];
  List<String> _selectedParts = [];
  Map<String, int> _partQuantities = {}; // Track quantities for each part
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

  // Map parts to inventory items for usage tracking
  final Map<String, InventoryItem> _partToInventoryMap = {
    'Oil Filter': InventoryItem(
      id: '1',
      name: 'Engine Oil Filter',
      category: 'Filters',
      currentStock: 45,
      minStock: 20,
      maxStock: 100,
      unitPrice: 12.99,
      supplier: 'AutoParts Plus',
      location: 'A-1-3',
      description: 'High-quality oil filter for most vehicles',
    ),
    'Air Filter': InventoryItem(
      id: '4',
      name: 'Air Filter',
      category: 'Filters',
      currentStock: 2,
      minStock: 10,
      maxStock: 40,
      unitPrice: 18.99,
      supplier: 'FilterMax',
      location: 'A-1-4',
      description: 'High-flow air filter for improved performance',
    ),
    'Front Brake Pads': InventoryItem(
      id: '2',
      name: 'Brake Pads - Front',
      category: 'Brakes',
      currentStock: 8,
      minStock: 15,
      maxStock: 50,
      unitPrice: 89.99,
      supplier: 'BrakeTech Solutions',
      location: 'B-2-1',
      description: 'Premium ceramic brake pads',
    ),
    'Engine Oil': InventoryItem(
      id: '3',
      name: 'Synthetic Motor Oil 5W-30',
      category: 'Fluids',
      currentStock: 120,
      minStock: 50,
      maxStock: 200,
      unitPrice: 24.99,
      supplier: 'Oil Express',
      location: 'C-1-2',
      description: 'Full synthetic motor oil, 5 quart bottle',
    ),
    'Spark Plugs': InventoryItem(
      id: '5',
      name: 'Spark Plugs (Set of 4)',
      category: 'Engine',
      currentStock: 25,
      minStock: 12,
      maxStock: 60,
      unitPrice: 32.99,
      supplier: 'Ignition Pro',
      location: 'D-3-1',
      description: 'Iridium spark plugs for extended life',
    ),
  };

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

    final serviceId = DateTime.now().millisecondsSinceEpoch.toString();
    final newService = ServiceRecord(
      id: serviceId,
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

    // Record inventory usage for each part used
    for (final partName in _selectedParts) {
      final inventoryItem = _partToInventoryMap[partName];
      if (inventoryItem != null) {
        final quantity = _partQuantities[partName] ?? 1;
        final usage = InventoryUsage(
          id: '${serviceId}_${partName.replaceAll(' ', '_').toLowerCase()}',
          itemId: inventoryItem.id,
          itemName: inventoryItem.name,
          itemCategory: inventoryItem.category,
          quantityUsed: quantity,
          unitPrice: inventoryItem.unitPrice,
          totalCost: quantity * inventoryItem.unitPrice,
          usageType: UsageType.service,
          status: UsageStatus.recorded,
          usageDate: _serviceDate,
          usedBy: _selectedMechanic ?? '',
          customerId: widget.customer.id,
          customerName: widget.customer.fullName,
          vehicleId: _selectedVehicleId,
          serviceRecordId: serviceId,
          purpose: 'Used in ${_serviceTypeController.text} service',
          notes: 'Auto-recorded from service: ${_descriptionController.text}',
          createdAt: DateTime.now(),
        );

        try {
          final usageId = await _usageService.recordUsage(usage);
          debugPrint('Recorded usage for $partName with ID: $usageId');
        } catch (e) {
          // Log error but don't fail the service creation
          debugPrint('Failed to record usage for $partName: $e');
        }
      }
    }

    widget.onServiceAdded(newService);

    setState(() {
      _isLoading = false;
    });

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

  void _showQuantityDialog(String partName) {
    final TextEditingController quantityController = TextEditingController(
      text: (_partQuantities[partName] ?? 1).toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Set Quantity for $partName',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: TextField(
          controller: quantityController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Quantity',
            hintText: 'Enter quantity used',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final quantity = int.tryParse(quantityController.text);
              if (quantity != null && quantity > 0) {
                setState(() {
                  _partQuantities[partName] = quantity;
                });
                Navigator.of(context).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPink,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Set',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
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

                // Parts Used
                Text(
                  'Parts Used',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.textLight),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableParts.map((part) {
                      final isSelected = _selectedParts.contains(part);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedParts.remove(part);
                              _partQuantities.remove(part);
                            } else {
                              _selectedParts.add(part);
                              _partQuantities[part] = 1;
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primaryPink : Colors.grey[100],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? AppColors.primaryPink : Colors.grey[300]!,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                part,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: isSelected ? Colors.white : AppColors.textDark,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (isSelected) ...[
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => _showQuantityDialog(part),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${_partQuantities[part] ?? 1}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
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
