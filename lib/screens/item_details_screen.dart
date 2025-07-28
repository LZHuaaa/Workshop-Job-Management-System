import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../widgets/dashboard_card.dart';
import '../models/inventory_item.dart';
import '../models/order_request.dart';

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

  void _requestMoreOrder() {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Request More Order',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to request more order for:',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              _currentItem.name,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryPink,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Current stock: ${_currentItem.currentStock}',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            Text(
              'Stock to reorder: ${_currentItem.stockToReorder}',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            Text(
              'Supplier: ${_currentItem.supplier}',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _submitOrderRequest();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPink,
            ),
            child: Text('Confirm Request', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _submitOrderRequest() {
    // Simulate API call for order request
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Submitting order request...',
              style: GoogleFonts.poppins(),
            ),
          ],
        ),
        backgroundColor: AppColors.primaryPink,
        duration: const Duration(seconds: 2),
      ),
    );

    // Simulate API delay and create order request
    Future.delayed(const Duration(seconds: 2), () {
      final orderRequestId = 'OR-${DateTime.now().millisecondsSinceEpoch}';
      final orderRequest = OrderRequest(
        id: orderRequestId,
        itemId: _currentItem.id,
        itemName: _currentItem.name,
        supplier: _currentItem.supplier,
        quantity: _currentItem.stockToReorder,
        unitPrice: _currentItem.unitPrice,
        totalAmount: _currentItem.stockToReorder * _currentItem.unitPrice,
        status: OrderRequestStatus.pending,
        requestDate: DateTime.now(),
        requestedBy: 'Current User', // In real app, get from auth service
      );

      // Update item with pending order request
      final updatedItem = _currentItem.copyWith(
        pendingOrderRequest: true,
        orderRequestDate: DateTime.now(),
        orderRequestId: orderRequestId,
      );

      setState(() {
        _currentItem = updatedItem;
      });

      widget.onItemUpdated(updatedItem);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Order request submitted! Waiting for company approval.',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: AppColors.successGreen,
        ),
      );
    });
  }

  void _viewOrderRequestDetails() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Order Request Details',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Request ID', _currentItem.orderRequestId ?? 'N/A'),
            _buildDetailRow('Item Name', _currentItem.name),
            _buildDetailRow('Supplier', _currentItem.supplier),
            _buildDetailRow('Quantity', _currentItem.stockToReorder.toString()),
            _buildDetailRow('Unit Price', 'RM${_currentItem.unitPrice.toStringAsFixed(2)}'),
            _buildDetailRow('Total Amount', 'RM${(_currentItem.stockToReorder * _currentItem.unitPrice).toStringAsFixed(2)}'),
            _buildDetailRow('Request Date', DateFormat('MMM d, y HH:mm').format(_currentItem.orderRequestDate!)),
            _buildDetailRow('Status', 'Pending Company Approval'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFA500).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFA500)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: const Color(0xFFFFA500),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your request is being reviewed by the company. You will be notified once a decision is made.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFFFFA500),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  void _cancelOrderRequest() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Cancel Order Request',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to cancel the order request for:',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              _currentItem.name,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryPink,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Request ID: ${_currentItem.orderRequestId}',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            Text(
              'Quantity: ${_currentItem.stockToReorder}',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.errorRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.errorRed),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning,
                    color: AppColors.errorRed,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This action cannot be undone. The request will be permanently cancelled.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.errorRed,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Keep Request', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _confirmCancelRequest();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
            ),
            child: Text('Cancel Request', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmCancelRequest() {
    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Cancelling request...',
              style: GoogleFonts.poppins(),
            ),
          ],
        ),
        backgroundColor: AppColors.errorRed,
        duration: const Duration(seconds: 2),
      ),
    );

    // Simulate API call to cancel request
    Future.delayed(const Duration(seconds: 2), () {
      // Update item to remove pending order request
      final updatedItem = _currentItem.copyWith(
        pendingOrderRequest: false,
        orderRequestDate: null,
        orderRequestId: null,
      );

      setState(() {
        _currentItem = updatedItem;
      });

      widget.onItemUpdated(updatedItem);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Order request cancelled successfully!',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: AppColors.successGreen,
        ),
      );
    });
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
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

            const SizedBox(height: 20),

            // Request More Order Button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    _currentItem.pendingOrderRequest 
                        ? 'Order Request Status'
                        : 'Need More Stock?',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_currentItem.pendingOrderRequest) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFA500).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFFFA500)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.pending,
                            size: 16,
                            color: const Color(0xFFFFA500),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Pending Company Approval',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFFFA500),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Request submitted on ${DateFormat('MMM d, y').format(_currentItem.orderRequestDate!)}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Waiting for company to review and approve your order request.',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: _viewOrderRequestDetails,
                              icon: Icon(
                                Icons.visibility,
                                size: 20,
                                color: Colors.white,
                              ),
                              label: Text(
                                'View Details',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryPink,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: _cancelOrderRequest,
                              icon: Icon(
                                Icons.cancel,
                                size: 20,
                                color: Colors.white,
                              ),
                              label: Text(
                                'Cancel Request',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.errorRed,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Text(
                      _currentItem.canRequestOrder
                          ? 'Stock is running low. Request more from supplier.'
                          : 'Stock levels are adequate.',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _currentItem.canRequestOrder
                            ? _requestMoreOrder
                            : null,
                        icon: Icon(
                          Icons.shopping_cart,
                          size: 20,
                          color: _currentItem.canRequestOrder
                              ? Colors.white
                              : Colors.grey,
                        ),
                        label: Text(
                          'Request More Order',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _currentItem.canRequestOrder
                                ? Colors.white
                                : Colors.grey,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _currentItem.canRequestOrder
                              ? AppColors.primaryPink
                              : Colors.grey.shade300,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),
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
