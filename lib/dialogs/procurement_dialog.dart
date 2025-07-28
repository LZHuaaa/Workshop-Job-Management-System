import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../widgets/custom_dialog.dart';
import '../models/inventory_item.dart';

class ProcurementDialog extends StatefulWidget {
  final List<InventoryItem> lowStockItems;
  final Function(List<ProcurementOrder>) onOrdersCreated;

  const ProcurementDialog({
    super.key,
    required this.lowStockItems,
    required this.onOrdersCreated,
  });

  @override
  State<ProcurementDialog> createState() => _ProcurementDialogState();
}

class _ProcurementDialogState extends State<ProcurementDialog> {
  final Map<String, int> _orderQuantities = {};
  final Map<String, bool> _selectedItems = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize with recommended quantities
    for (final item in widget.lowStockItems) {
      _orderQuantities[item.id] = item.stockToReorder;
      _selectedItems[item.id] = item.isCriticalStock;
    }
  }

  double get _totalCost {
    double total = 0;
    for (final item in widget.lowStockItems) {
      if (_selectedItems[item.id] == true) {
        final quantity = _orderQuantities[item.id] ?? 0;
        total += item.unitPrice * quantity;
      }
    }
    return total;
  }

  int get _selectedCount {
    return _selectedItems.values.where((selected) => selected).length;
  }

  Future<void> _submitOrders() async {
    if (_selectedCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select at least one item to order',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: AppColors.warningOrange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    final orders = <ProcurementOrder>[];
    for (final item in widget.lowStockItems) {
      if (_selectedItems[item.id] == true) {
        final quantity = _orderQuantities[item.id] ?? 0;
        if (quantity > 0) {
          orders.add(ProcurementOrder(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            itemId: item.id,
            itemName: item.name,
            supplier: item.supplier,
            quantity: quantity,
            unitPrice: item.unitPrice,
            totalCost: item.unitPrice * quantity,
            orderDate: DateTime.now(),
            expectedDelivery: DateTime.now().add(const Duration(days: 3)),
            status: ProcurementStatus.pending,
          ));
        }
      }
    }

    widget.onOrdersCreated(orders);

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${orders.length} procurement order${orders.length != 1 ? 's' : ''} created successfully!',
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
      title: 'Initiate Procurement',
      width: MediaQuery.of(context).size.width * 0.95,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.softPink,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Procurement Summary',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Items to order: $_selectedCount',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      'Total cost: \$${_totalCost.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryPink,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'Select items to order:',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),

          // Items List
          ...widget.lowStockItems.map((item) => _buildItemCard(item)),
        ],
      ),
      actions: [
        SecondaryButton(
          text: 'Cancel',
          onPressed: () => Navigator.of(context).pop(),
        ),
        PrimaryButton(
          text: 'Submit Orders (\$${_totalCost.toStringAsFixed(2)})',
          onPressed: _submitOrders,
          isLoading: _isLoading,
        ),
      ],
    );
  }

  Widget _buildItemCard(InventoryItem item) {
    final isSelected = _selectedItems[item.id] ?? false;
    final quantity = _orderQuantities[item.id] ?? 0;
    final itemTotal = item.unitPrice * quantity;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected
              ? AppColors.primaryPink
              : AppColors.textSecondary.withOpacity(0.3),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Checkbox(
                value: isSelected,
                onChanged: (value) {
                  setState(() {
                    _selectedItems[item.id] = value ?? false;
                  });
                },
                activeColor: AppColors.primaryPink,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                        if (item.isCriticalStock)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.errorRed,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'CRITICAL',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Current: ${item.currentStock} | Min: ${item.minStock} | Max: ${item.maxStock}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      'Supplier: ${item.supplier} | Unit Price: \$${item.unitPrice.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isSelected) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Quantity to order:',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 60,
                  height: 32,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.textSecondary.withOpacity(0.3),
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: TextFormField(
                    initialValue: quantity.toString(),
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(fontSize: 12),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 4),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _orderQuantities[item.id] = int.tryParse(value) ?? 0;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Total: \$${itemTotal.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryPink,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class ProcurementOrder {
  final String id;
  final String itemId;
  final String itemName;
  final String supplier;
  final int quantity;
  final double unitPrice;
  final double totalCost;
  final DateTime orderDate;
  final DateTime expectedDelivery;
  final ProcurementStatus status;

  ProcurementOrder({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.supplier,
    required this.quantity,
    required this.unitPrice,
    required this.totalCost,
    required this.orderDate,
    required this.expectedDelivery,
    required this.status,
  });
}

enum ProcurementStatus {
  pending,
  ordered,
  shipped,
  delivered,
  cancelled,
}
