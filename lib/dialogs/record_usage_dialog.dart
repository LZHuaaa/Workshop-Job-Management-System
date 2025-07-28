import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../models/inventory_usage.dart';
import '../models/inventory_item.dart';
import '../widgets/custom_dialog.dart';

class RecordUsageDialog extends StatefulWidget {
  final Function(InventoryUsage) onUsageRecorded;

  const RecordUsageDialog({
    super.key,
    required this.onUsageRecorded,
  });

  @override
  State<RecordUsageDialog> createState() => _RecordUsageDialogState();
}

class _RecordUsageDialogState extends State<RecordUsageDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _purposeController = TextEditingController();
  final _notesController = TextEditingController();
  final _customerNameController = TextEditingController();
  final _vehiclePlateController = TextEditingController();
  final _locationController = TextEditingController();

  InventoryItem? _selectedItem;
  UsageType _selectedUsageType = UsageType.service;
  String _selectedEmployee = 'Lim Wei Ming';
  DateTime _usageDate = DateTime.now();
  bool _isLoading = false;

  // Sample inventory items for selection
  final List<InventoryItem> _availableItems = [
    InventoryItem(
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
    InventoryItem(
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
    InventoryItem(
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
    InventoryItem(
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
    InventoryItem(
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
  ];

  final List<String> _employees = [
    'Lim Wei Ming',
    'Siti Nurhaliza binti Hassan',
    'Ahmad Faiz bin Rahman',
    'Tan Chee Wai',
    'Fatimah binti Ismail',
  ];

  @override
  void dispose() {
    _quantityController.dispose();
    _purposeController.dispose();
    _notesController.dispose();
    _customerNameController.dispose();
    _vehiclePlateController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _recordUsage() async {
    if (!_formKey.currentState!.validate() || _selectedItem == null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    final quantity = int.parse(_quantityController.text);
    final totalCost = quantity * _selectedItem!.unitPrice;

    final usage = InventoryUsage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      itemId: _selectedItem!.id,
      itemName: _selectedItem!.name,
      itemCategory: _selectedItem!.category,
      quantityUsed: quantity,
      unitPrice: _selectedItem!.unitPrice,
      totalCost: totalCost,
      usageType: _selectedUsageType,
      status: UsageStatus.recorded,
      usageDate: _usageDate,
      usedBy: _selectedEmployee,
      customerId: _customerNameController.text.isNotEmpty ? 'c_${DateTime.now().millisecondsSinceEpoch}' : null,
      customerName: _customerNameController.text.isNotEmpty ? _customerNameController.text : null,
      vehicleId: _vehiclePlateController.text.isNotEmpty ? 'v_${DateTime.now().millisecondsSinceEpoch}' : null,
      vehiclePlate: _vehiclePlateController.text.isNotEmpty ? _vehiclePlateController.text : null,
      purpose: _purposeController.text,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      location: _locationController.text.isNotEmpty ? _locationController.text : null,
      createdAt: DateTime.now(),
    );

    setState(() {
      _isLoading = false;
    });

    widget.onUsageRecorded(usage);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return CustomDialog(
      title: 'Record Inventory Usage',
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Item Selection
              Text(
                'Select Item *',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<InventoryItem>(
                value: _selectedItem,
                decoration: InputDecoration(
                  hintText: 'Choose an item',
                  hintStyle: GoogleFonts.poppins(color: AppColors.textSecondary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.primaryPink),
                  ),
                ),
                items: _availableItems.map((item) => DropdownMenuItem(
                  value: item,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${item.category} • Stock: ${item.currentStock} • RM${item.unitPrice.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )).toList(),
                onChanged: (item) {
                  setState(() {
                    _selectedItem = item;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select an item';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Quantity and Usage Type Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quantity Used *',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _quantityController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'Enter quantity',
                            hintStyle: GoogleFonts.poppins(color: AppColors.textSecondary),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: AppColors.primaryPink),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            final quantity = int.tryParse(value);
                            if (quantity == null || quantity <= 0) {
                              return 'Invalid quantity';
                            }
                            if (_selectedItem != null && quantity > _selectedItem!.currentStock) {
                              return 'Exceeds stock';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Usage Type *',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<UsageType>(
                          value: _selectedUsageType,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: AppColors.primaryPink),
                            ),
                          ),
                          items: UsageType.values.map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(
                              type.name.toUpperCase(),
                              style: GoogleFonts.poppins(fontSize: 14),
                            ),
                          )).toList(),
                          onChanged: (type) {
                            if (type != null) {
                              setState(() {
                                _selectedUsageType = type;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Employee and Date Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Used By *',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedEmployee,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: AppColors.primaryPink),
                            ),
                          ),
                          items: _employees.map((employee) => DropdownMenuItem(
                            value: employee,
                            child: Text(
                              employee,
                              style: GoogleFonts.poppins(fontSize: 14),
                            ),
                          )).toList(),
                          onChanged: (employee) {
                            if (employee != null) {
                              setState(() {
                                _selectedEmployee = employee;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Usage Date *',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _usageDate,
                              firstDate: DateTime.now().subtract(const Duration(days: 30)),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.fromDateTime(_usageDate),
                              );
                              if (time != null) {
                                setState(() {
                                  _usageDate = DateTime(
                                    date.year,
                                    date.month,
                                    date.day,
                                    time.hour,
                                    time.minute,
                                  );
                                });
                              }
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${_usageDate.day}/${_usageDate.month}/${_usageDate.year} ${_usageDate.hour.toString().padLeft(2, '0')}:${_usageDate.minute.toString().padLeft(2, '0')}',
                                    style: GoogleFonts.poppins(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Purpose
              Text(
                'Purpose *',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _purposeController,
                decoration: InputDecoration(
                  hintText: 'Describe what the item was used for',
                  hintStyle: GoogleFonts.poppins(color: AppColors.textSecondary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.primaryPink),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please describe the purpose';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Customer and Vehicle Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Customer Name',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _customerNameController,
                          decoration: InputDecoration(
                            hintText: 'Optional',
                            hintStyle: GoogleFonts.poppins(color: AppColors.textSecondary),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: AppColors.primaryPink),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Vehicle Plate',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _vehiclePlateController,
                          decoration: InputDecoration(
                            hintText: 'Optional',
                            hintStyle: GoogleFonts.poppins(color: AppColors.textSecondary),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: AppColors.primaryPink),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Location and Notes Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Location',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _locationController,
                          decoration: InputDecoration(
                            hintText: 'e.g., Bay 1',
                            hintStyle: GoogleFonts.poppins(color: AppColors.textSecondary),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: AppColors.primaryPink),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Notes
              Text(
                'Notes',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Additional notes or comments',
                  hintStyle: GoogleFonts.poppins(color: AppColors.textSecondary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.primaryPink),
                  ),
                ),
              ),

              // Cost Preview
              if (_selectedItem != null && _quantityController.text.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.lightGray,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Cost:',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'RM${((int.tryParse(_quantityController.text) ?? 0) * _selectedItem!.unitPrice).toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryPink,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: GoogleFonts.poppins(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _recordUsage,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryPink,
            foregroundColor: Colors.white,
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
                  'Record Usage',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ],
    );
  }
}
