import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/numeric_spinner.dart';
import '../models/inventory_item.dart';
import '../models/order_request.dart' as order_request_model;
import '../services/inventory_service.dart';

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
  final InventoryService _inventoryService = InventoryService();
  late Stream<InventoryItem?> _statusStream;

  @override
  void initState() {
    super.initState();
    _currentItem = widget.item;
    _statusStream = _inventoryService.listenToItemStatusChanges(_currentItem.id);

    // Listen for status changes from external systems
    _statusStream.listen((updatedItem) {
      if (updatedItem != null && mounted) {
        final previousStatus = _currentItem.orderRequestStatus;
        final newStatus = updatedItem.orderRequestStatus;

        setState(() {
          _currentItem = updatedItem;
        });

        // Handle status change notifications
        if (previousStatus != newStatus) {
          _handleStatusChange(previousStatus, newStatus);
        }
      }
    });
  }





  void _showEditItemDialog() async {
    // Load categories first
    List<String> categories = [];
    try {
      final loadedCategories = await _inventoryService.getCategories();
      categories = loadedCategories.where((category) => category != 'All').toList();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading categories: $e', style: GoogleFonts.poppins()),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
      return;
    }

    final nameController = TextEditingController(text: _currentItem.name);
    String selectedCategory = _currentItem.category;
    final minStockController = TextEditingController(text: _currentItem.minStock.toString());
    final maxStockController = TextEditingController(text: _currentItem.maxStock.toString());
    final unitPriceController = TextEditingController(text: _currentItem.unitPrice.toString());
    final supplierController = TextEditingController(text: _currentItem.supplier);
    final locationController = TextEditingController(text: _currentItem.location);
    final descriptionController = TextEditingController(text: _currentItem.description);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
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
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: InputDecoration(labelText: 'Category'),
                      items: categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedCategory = value!;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select category';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    NumericSpinner(
                      label: 'Min Stock',
                      controller: minStockController,
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
                    const SizedBox(height: 16),
                    NumericSpinner(
                      label: 'Max Stock',
                      controller: maxStockController,
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
                        final minStock = int.tryParse(minStockController.text) ?? 0;
                        if (maxStock <= minStock) {
                          return 'Must be > min';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    NumericSpinner(
                      label: 'Unit Price (\$)',
                      controller: unitPriceController,
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
                    const SizedBox(height: 16),
                    TextField(
                      controller: supplierController,
                      decoration: InputDecoration(labelText: 'Supplier'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: locationController,
                      decoration: InputDecoration(labelText: 'Location'),
                    ),
                    const SizedBox(height: 16),
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
                      category: selectedCategory,
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
      },
    );
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.warning,
                color: AppColors.errorRed,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Delete Item',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.errorRed,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to permanently delete this item?',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.errorRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.errorRed.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Item to be deleted:',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currentItem.name,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Category: ${_currentItem.category}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '⚠️ This action cannot be undone. All related usage records will remain but will reference a deleted item.',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.errorRed,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteItem();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.errorRed,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Delete',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteItem() async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Deleting item...',
                style: GoogleFonts.poppins(),
              ),
            ],
          ),
        );
      },
    );

    try {
      // Delete the item from the database
      await _inventoryService.deleteInventoryItem(_currentItem.id);

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show success message and navigate back
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Item "${_currentItem.name}" deleted successfully',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppColors.successGreen,
          ),
        );

        // Navigate back to inventory screen
        Navigator.of(context).pop();
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to delete item: ${e.toString()}',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
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

  void _handleStatusChange(OrderRequestStatus? previousStatus, OrderRequestStatus? newStatus) {
    if (!mounted) return;

    switch (newStatus) {
      case OrderRequestStatus.approved:
        if (previousStatus == OrderRequestStatus.pending) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Order request for ${_currentItem.name} has been approved by the company!',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.blue,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        break;
      case OrderRequestStatus.rejected:
        if (previousStatus == OrderRequestStatus.pending) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Order request for ${_currentItem.name} has been rejected by the company.',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        break;
      case OrderRequestStatus.completed:
        if (previousStatus == OrderRequestStatus.approved) {
          _showCompletionDialog();
        }
        break;
      default:
        break;
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              'Restocking Complete!',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: Text(
          'The order for ${_currentItem.name} has been completed. Stock levels have been updated.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _completeOrderRequest();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPink,
            ),
            child: Text(
              'OK',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _completeOrderRequest() async {
    try {
      // Calculate new stock level (assume restocked to max)
      final newStockLevel = _currentItem.maxStock;

      await _inventoryService.completeOrderRequest(_currentItem.id, newStockLevel);

      // Update local state
      final updatedItem = _currentItem.copyWith(
        currentStock: newStockLevel,
        lastRestocked: DateTime.now(),
        pendingOrderRequest: false,
        orderRequestDate: null,
        orderRequestId: null,
        clearOrderRequestStatus: true,
      );

      setState(() {
        _currentItem = updatedItem;
      });

      widget.onItemUpdated(updatedItem);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_currentItem.name} has been restocked successfully!',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: AppColors.successGreen,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error completing order: $e',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
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
      final orderRequest = order_request_model.OrderRequest(
        id: orderRequestId,
        itemId: _currentItem.id,
        itemName: _currentItem.name,
        supplier: _currentItem.supplier,
        quantity: _currentItem.stockToReorder,
        unitPrice: _currentItem.unitPrice,
        totalAmount: _currentItem.stockToReorder * _currentItem.unitPrice,
        status: order_request_model.OrderRequestStatus.pending,
        requestDate: DateTime.now(),
        requestedBy: 'Current User', // In real app, get from auth service
      );

      // Update item with pending order request
      final updatedItem = _currentItem.copyWith(
        pendingOrderRequest: true,
        orderRequestDate: DateTime.now(),
        orderRequestId: orderRequestId,
        orderRequestStatus: OrderRequestStatus.pending,
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
            _buildDetailRow('Status', _currentItem.orderRequestStatusText),
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

  void _clearRejectedStatus() async {
    try {
      // Clear rejected status and reset to null
      await _inventoryService.cancelOrderRequest(_currentItem.id);

      // Update local state
      final updatedItem = _currentItem.copyWith(
        pendingOrderRequest: false,
        orderRequestDate: null,
        orderRequestId: null,
        clearOrderRequestStatus: true, // Set to null
      );

      setState(() {
        _currentItem = updatedItem;
      });

      widget.onItemUpdated(updatedItem);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Order request status cleared. You can now request a new order.',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: AppColors.successGreen,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error clearing status: $e',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
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
        clearOrderRequestStatus: true, // Set to null for no active request
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
            tooltip: 'Edit Item',
          ),
          IconButton(
            icon: Icon(Icons.delete, color: AppColors.errorRed),
            onPressed: () {
              _showDeleteConfirmationDialog();
            },
            tooltip: 'Delete Item',
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
                          color: _currentItem.isOutOfStock
                              ? Colors.grey.shade600
                              : _currentItem.isCriticalStock
                                  ? AppColors.errorRed
                                  : _currentItem.isLowStock
                                      ? AppColors.warningOrange
                                      : AppColors.successGreen,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _currentItem.isOutOfStock
                              ? 'OUT OF STOCK'
                              : _currentItem.isCriticalStock
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

                  // Status-dependent alerts and warnings
                  if (_currentItem.hasOrderRequestApproved) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info, color: Colors.blue, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Order approved! Company is processing your request. Stock will be updated automatically when completed.',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ] else if (_currentItem.hasOrderRequestRejected) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning, color: Colors.red, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Previous order request was rejected. You can clear this status and request again if stock is still low.',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ] else if (_currentItem.hasOrderRequestCompleted) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Order completed! Click "Acknowledge Completion" to update stock levels and reset status.',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ] else if (_currentItem.canRequestOrderNew && _currentItem.hasNoActiveOrderRequest) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.inventory_2, color: Colors.orange, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Stock is running low! Consider requesting more inventory from the supplier.',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

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
                    _currentItem.orderRequestStatus != null
                        ? 'Order Request Status'
                        : 'Need More Stock?',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_currentItem.orderRequestStatus != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Color(int.parse(_currentItem.orderRequestStatusColor.substring(1), radix: 16) + 0xFF000000).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Color(int.parse(_currentItem.orderRequestStatusColor.substring(1), radix: 16) + 0xFF000000)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _currentItem.hasOrderRequestPending
                                ? Icons.pending
                                : _currentItem.hasOrderRequestApproved
                                    ? Icons.check_circle
                                    : _currentItem.hasOrderRequestRejected
                                        ? Icons.cancel
                                        : Icons.done_all,
                            size: 16,
                            color: Color(int.parse(_currentItem.orderRequestStatusColor.substring(1), radix: 16) + 0xFF000000),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _currentItem.orderRequestStatusText,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(int.parse(_currentItem.orderRequestStatusColor.substring(1), radix: 16) + 0xFF000000),
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
                      _currentItem.hasOrderRequestPending
                          ? 'Waiting for company to review and approve your order request.'
                          : _currentItem.hasOrderRequestApproved
                              ? 'Company has approved your request and is processing the order.'
                              : _currentItem.hasOrderRequestRejected
                                  ? 'Your order request was rejected by the company.'
                                  : 'Order has been completed and stock updated.',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    // Status-dependent action buttons
                    if (_currentItem.hasOrderRequestPending) ...[
                      // Pending status: Show View Details and Cancel buttons
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
                    ] else if (_currentItem.hasOrderRequestApproved) ...[
                      // Approved status: Show View Details only (company is processing)
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _viewOrderRequestDetails,
                          icon: Icon(
                            Icons.visibility,
                            size: 20,
                            color: Colors.white,
                          ),
                          label: Text(
                            'View Order Details',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ] else if (_currentItem.hasOrderRequestRejected) ...[
                      // Rejected status: Show View Details and Request New Order
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
                                onPressed: _currentItem.canRequestOrderNew ? () {
                                  // First clear the rejected status, then allow new request
                                  _clearRejectedStatus();
                                } : null,
                                icon: Icon(
                                  Icons.refresh,
                                  size: 20,
                                  color: _currentItem.canRequestOrderNew ? Colors.white : Colors.grey,
                                ),
                                label: Text(
                                  'Request Again',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: _currentItem.canRequestOrderNew ? Colors.white : Colors.grey,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _currentItem.canRequestOrderNew ? Colors.green : Colors.grey.shade300,
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
                    ] else if (_currentItem.hasOrderRequestCompleted) ...[
                      // Completed status: Show acknowledgment button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () => _completeOrderRequest(),
                          icon: Icon(
                            Icons.check_circle,
                            size: 20,
                            color: Colors.white,
                          ),
                          label: Text(
                            'Acknowledge Completion',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ] else ...[
                    Text(
                      _currentItem.canRequestOrderNew
                          ? 'Stock is running low. Request more from supplier.'
                          : _currentItem.hasOrderRequestPending
                              ? 'Order request pending company approval.'
                              : _currentItem.hasOrderRequestApproved
                                  ? 'Order approved - company is processing.'
                                  : _currentItem.hasOrderRequestRejected
                                      ? 'Previous order request was rejected.'
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
                        onPressed: _currentItem.canRequestOrderNew
                            ? _requestMoreOrder
                            : null,
                        icon: Icon(
                          Icons.shopping_cart,
                          size: 20,
                          color: _currentItem.canRequestOrderNew
                              ? Colors.white
                              : Colors.grey,
                        ),
                        label: Text(
                          'Request More Order',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _currentItem.canRequestOrderNew
                                ? Colors.white
                                : Colors.grey,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _currentItem.canRequestOrderNew
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
