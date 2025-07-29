import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../widgets/custom_dialog.dart';
import '../widgets/numeric_spinner.dart';
import '../models/inventory_item.dart';
import '../services/inventory_service.dart';

class AddItemDialog extends StatefulWidget {
  final Function(InventoryItem) onItemAdded;

  const AddItemDialog({
    super.key,
    required this.onItemAdded,
  });

  @override
  State<AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<AddItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _currentStockController = TextEditingController();
  final _minStockController = TextEditingController();
  final _maxStockController = TextEditingController();
  final _unitPriceController = TextEditingController();
  final _supplierController = TextEditingController();
  final _locationController = TextEditingController();
  final InventoryService _inventoryService = InventoryService();

  String? _selectedCategory;
  bool _isLoading = false;
  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _currentStockController.dispose();
    _minStockController.dispose();
    _maxStockController.dispose();
    _unitPriceController.dispose();
    _supplierController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _loadCategories() async {
    try {
      final categories = await _inventoryService.getCategories();
      setState(() {
        // Remove 'All' from categories for the dropdown since it's not a valid category for new items
        _categories = categories.where((category) => category != 'All').toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading categories: $e', style: GoogleFonts.poppins()),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _addItem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    final newItem = InventoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      category: _selectedCategory!,
      currentStock: int.parse(_currentStockController.text),
      minStock: int.parse(_minStockController.text),
      maxStock: int.parse(_maxStockController.text),
      unitPrice: double.parse(_unitPriceController.text),
      supplier: _supplierController.text,
      location: _locationController.text,
      description: _descriptionController.text,
      lastRestocked: DateTime.now(),
    );

    widget.onItemAdded(newItem);

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Item added successfully!',
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
      title: 'Add New Item',
      content: Form(
        key: _formKey,
        child: Column(
          children: [
            CustomTextField(
              label: 'Item Name',
              hint: 'e.g., Brake Pads - Front',
              controller: _nameController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter item name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CustomDropdown<String>(
                    label: 'Category',
                    value: _selectedCategory,
                    items: _categories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Please select category';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomTextField(
                    label: 'Location',
                    hint: 'e.g., A-1-3',
                    controller: _locationController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter location';
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
                  child: NumericSpinner(
                    label: 'Current Stock',
                    hint: '0',
                    controller: _currentStockController,
                    step: 1,
                    min: 0,
                    isInteger: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Invalid number';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: NumericSpinner(
                    label: 'Min Stock',
                    hint: '10',
                    controller: _minStockController,
                    step: 1,
                    min: 0,
                    isInteger: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Invalid number';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: NumericSpinner(
                    label: 'Max Stock',
                    hint: '100',
                    controller: _maxStockController,
                    step: 1,
                    min: 0,
                    isInteger: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Invalid number';
                      }
                      final maxStock = int.parse(value);
                      final minStock =
                          int.tryParse(_minStockController.text) ?? 0;
                      if (maxStock <= minStock) {
                        return 'Must be > min';
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
                  child: NumericSpinner(
                    label: 'Unit Price (\$)',
                    hint: '0.00',
                    controller: _unitPriceController,
                    step: 0.01,
                    min: 0,
                    isInteger: false,
                    decimalPlaces: 2,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter unit price';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Invalid price';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomTextField(
                    label: 'Supplier',
                    hint: 'Supplier name',
                    controller: _supplierController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter supplier';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Description',
              hint: 'Item description and specifications...',
              controller: _descriptionController,
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter description';
                }
                return null;
              },
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
          text: 'Add Item',
          onPressed: _addItem,
          isLoading: _isLoading,
        ),
      ],
    );
  }
}
