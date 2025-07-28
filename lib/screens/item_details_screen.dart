import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../widgets/dashboard_card.dart';
import '../models/inventory_item.dart';

class ItemDetailsScreen extends StatefulWidget {
  final InventoryItem item;
  final Function(InventoryItem) onItemUpdated;

  const ItemDetailsScreen({
    super.key,
    required this.item,
    required this.onItemUpdated,
  });

  @override
  State<ItemDetailsScreen> createState() => _ItemDetailsScreenState();
}

class _ItemDetailsScreenState extends State<ItemDetailsScreen> {
  late InventoryItem _currentItem;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _currentItem = widget.item;
  }

  Future<void> _updateStock(int newStock) async {
    setState(() {
      _isUpdating = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    final updatedItem = _currentItem.copyWith(
      currentStock: newStock,
      lastRestocked: DateTime.now(),
    );

    setState(() {
      _currentItem = updatedItem;
      _isUpdating = false;
    });

    widget.onItemUpdated(updatedItem);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Stock updated successfully',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: AppColors.successGreen,
      ),
    );
  }

  void _showStockUpdateDialog() {
    final controller =
        TextEditingController(text: _currentItem.currentStock.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Update Stock',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Current stock: ${_currentItem.currentStock}',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'New Stock Level',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newStock = int.tryParse(controller.text);
              if (newStock != null && newStock >= 0) {
                Navigator.of(context).pop();
                _updateStock(newStock);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPink,
            ),
            child: Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showEditItemDialog() {
    final nameController = TextEditingController(text: _currentItem.name);
    final categoryController = TextEditingController(text: _currentItem.category);
    final minStockController = TextEditingController(text: _currentItem.minStock.toString());
    final maxStockController = TextEditingController(text: _currentItem.maxStock.toString());
    final unitPriceController = TextEditingController(text: _currentItem.unitPrice.toString());
    final supplierController = TextEditingController(text: _currentItem.supplier);
    final locationController = TextEditingController(text: _currentItem.location);
    final descriptionController = TextEditingController(text: _currentItem.description);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Item', style: GoogleFonts.poppins()),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: categoryController,
                  decoration: InputDecoration(labelText: 'Category'),
                ),
                TextField(
                  controller: minStockController,
                  decoration: InputDecoration(labelText: 'Min Stock'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: maxStockController,
                  decoration: InputDecoration(labelText: 'Max Stock'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: unitPriceController,
                  decoration: InputDecoration(labelText: 'Unit Price'),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
                TextField(
                  controller: supplierController,
                  decoration: InputDecoration(labelText: 'Supplier'),
                ),
                TextField(
                  controller: locationController,
                  decoration: InputDecoration(labelText: 'Location'),
                ),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(labelText: 'Description'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: GoogleFonts.poppins()),
            ),
            ElevatedButton(
              onPressed: () {
                final updatedItem = _currentItem.copyWith(
                  name: nameController.text,
                  category: categoryController.text,
                  minStock: int.tryParse(minStockController.text) ?? _currentItem.minStock,
                  maxStock: int.tryParse(maxStockController.text) ?? _currentItem.maxStock,
                  unitPrice: double.tryParse(unitPriceController.text) ?? _currentItem.unitPrice,
                  supplier: supplierController.text,
                  location: locationController.text,
                  description: descriptionController.text,
                );
                setState(() {
                  _currentItem = updatedItem;
                });
                widget.onItemUpdated(updatedItem);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Item updated successfully', style: GoogleFonts.poppins()),
                    backgroundColor: AppColors.successGreen,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPink,
              ),
              child: Text('Save', style: GoogleFonts.poppins(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Item Details',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.edit, color: AppColors.primaryPink),
            onPressed: () {
              _showEditItemDialog();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Item Header Card
            DashboardCard(
              title: 'Item Information',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _currentItem.name,
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _currentItem.isCriticalStock
                              ? AppColors.errorRed
                              : _currentItem.isLowStock
                                  ? AppColors.warningOrange
                                  : AppColors.successGreen,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _currentItem.isCriticalStock
                              ? 'CRITICAL'
                              : _currentItem.isLowStock
                                  ? 'LOW STOCK'
                                  : 'IN STOCK',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                      Icons.category, 'Category', _currentItem.category),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                      Icons.location_on, 'Location', _currentItem.location),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                      Icons.business, 'Supplier', _currentItem.supplier),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.attach_money, 'Unit Price',
                      'RM${_currentItem.unitPrice.toStringAsFixed(2)}'),
                  if (_currentItem.lastRestocked != null) ...[
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      Icons.refresh,
                      'Last Restocked',
                      DateFormat('MMM d, y')
                          .format(_currentItem.lastRestocked!),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    'Description',
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
                      color: AppColors.softPink,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _currentItem.description,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Stock Information Card
            DashboardCard(
              title: 'Stock Information',
              action: ElevatedButton.icon(
                onPressed: _isUpdating ? null : _showStockUpdateDialog,
                icon: _isUpdating
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Icon(Icons.edit, size: 16),
                label: Text(
                  'Update Stock',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPink,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              child: Column(
                children: [
                  // Stock Level Indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Current Stock',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '${_currentItem.currentStock} / ${_currentItem.maxStock}',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  LinearProgressIndicator(
                    value: _currentItem.stockPercentage,
                    backgroundColor: AppColors.backgroundLight,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _currentItem.isCriticalStock
                          ? AppColors.errorRed
                          : _currentItem.isLowStock
                              ? AppColors.warningOrange
                              : AppColors.successGreen,
                    ),
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: _buildStockInfo(
                            'Minimum', _currentItem.minStock.toString()),
                      ),
                      Expanded(
                        child: _buildStockInfo(
                            'Maximum', _currentItem.maxStock.toString()),
                      ),
                      Expanded(
                        child: _buildStockInfo('To Reorder',
                            _currentItem.stockToReorder.toString()),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryPink.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.monetization_on,
                          color: AppColors.primaryPink,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Value',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              'RM${_currentItem.totalValue.toStringAsFixed(2)}',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryPink,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: AppColors.primaryPink,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStockInfo(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
