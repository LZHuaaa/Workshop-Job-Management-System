import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/inventory_item.dart';

class InventoryService {
  static final InventoryService _instance = InventoryService._internal();
  factory InventoryService() => _instance;
  InventoryService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'inventory';

  // Get inventory collection reference
  CollectionReference get _inventoryRef => _firestore.collection(_collection);

  // Get all inventory items
  Stream<List<InventoryItem>> getInventoryItems() {
    return _inventoryRef.snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return <InventoryItem>[];
      }

      final items = <InventoryItem>[];
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final item = _mapToInventoryItem(data);
          items.add(item);
        } catch (e) {
          // Continue with other documents
          print('Error mapping document ${doc.id}: $e');
        }
      }

      return items;
    }).handleError((error) {
      print('Stream error: $error');
      return <InventoryItem>[];
    });
  }

  // Get inventory items with filtering
  Stream<List<InventoryItem>> getFilteredInventoryItems({
    String? category,
    String? searchQuery,
    String? sortBy,
    bool? showUnavailable,
  }) {
    Query query = _inventoryRef;

    // Apply category filter
    if (category != null && category != 'All') {
      query = query.where('category', isEqualTo: category);
    }

    return query.snapshots().map((snapshot) {
      List<InventoryItem> items = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return _mapToInventoryItem(data);
      }).toList();

      // Apply search filter
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final searchTerm = searchQuery.toLowerCase();
        items = items.where((item) =>
            item.name.toLowerCase().contains(searchTerm) ||
            item.category.toLowerCase().contains(searchTerm) ||
            item.supplier.toLowerCase().contains(searchTerm) ||
            item.description.toLowerCase().contains(searchTerm)).toList();
      }

      // Apply availability filter
      if (showUnavailable != null && !showUnavailable) {
        items = items.where((item) => item.isAvailable).toList();
      }

      // Apply sorting
      if (sortBy != null) {
        switch (sortBy) {
          case 'Name':
            items.sort((a, b) => a.name.compareTo(b.name));
            break;
          case 'Stock Level':
            items.sort((a, b) => a.currentStock.compareTo(b.currentStock));
            break;
          case 'Price':
            items.sort((a, b) => a.unitPrice.compareTo(b.unitPrice));
            break;
          case 'Category':
            items.sort((a, b) => a.category.compareTo(b.category));
            break;
        }
      }

      return items;
    });
  }

  // Get single inventory item by ID
  Future<InventoryItem?> getInventoryItem(String id) async {
    try {
      final doc = await _inventoryRef.doc(id).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return _mapToInventoryItem(data);
      }
      return null;
    } catch (e) {
      throw InventoryServiceException('Failed to get inventory item: ${e.toString()}');
    }
  }

  // Add new inventory item
  Future<String> addInventoryItem(InventoryItem item) async {
    try {
      final itemData = _inventoryItemToMap(item);
      // Ensure orderRequestStatus field is always present
      if (!itemData.containsKey('orderRequestStatus')) {
        itemData['orderRequestStatus'] = null;
      }

      final docRef = await _inventoryRef.add(itemData);

      // Update the item with the generated ID
      await docRef.update({'id': docRef.id});

      return docRef.id;
    } catch (e) {
      throw InventoryServiceException('Failed to add inventory item: ${e.toString()}');
    }
  }

  // Update inventory item
  Future<void> updateInventoryItem(InventoryItem item) async {
    try {
      final itemData = _inventoryItemToMap(item);
      // Ensure orderRequestStatus field is always present
      if (!itemData.containsKey('orderRequestStatus')) {
        itemData['orderRequestStatus'] = null;
      }
      await _inventoryRef.doc(item.id).update(itemData);
    } catch (e) {
      throw InventoryServiceException('Failed to update inventory item: ${e.toString()}');
    }
  }

  // Delete inventory item
  Future<void> deleteInventoryItem(String id) async {
    try {
      await _inventoryRef.doc(id).delete();
    } catch (e) {
      throw InventoryServiceException('Failed to delete inventory item: ${e.toString()}');
    }
  }

  // Update stock level
  Future<void> updateStock(String id, int newStock) async {
    try {
      await _inventoryRef.doc(id).update({'currentStock': newStock});
    } catch (e) {
      throw InventoryServiceException('Failed to update stock: ${e.toString()}');
    }
  }

  // Get low stock items
  Stream<List<InventoryItem>> getLowStockItems() {
    return _inventoryRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return _mapToInventoryItem(data);
      }).where((item) => item.isLowStock).toList();
    });
  }

  // Get critical stock items
  Stream<List<InventoryItem>> getCriticalStockItems() {
    return _inventoryRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return _mapToInventoryItem(data);
      }).where((item) => item.isCriticalStock).toList();
    });
  }

  // Get out of stock items
  Stream<List<InventoryItem>> getOutOfStockItems() {
    return _inventoryRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return _mapToInventoryItem(data);
      }).where((item) => item.isOutOfStock).toList();
    });
  }

  // Get available items (stock > 0)
  Stream<List<InventoryItem>> getAvailableItems() {
    return _inventoryRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return _mapToInventoryItem(data);
      }).where((item) => item.isAvailable).toList();
    });
  }

  // Get categories
  Future<List<String>> getCategories() async {
    try {
      final snapshot = await _inventoryRef.get();
      final categories = snapshot.docs
          .map((doc) => (doc.data() as Map<String, dynamic>)['category'] as String)
          .toSet()
          .toList();
      categories.sort();
      return ['All', ...categories];
    } catch (e) {
      throw InventoryServiceException('Failed to get categories: ${e.toString()}');
    }
  }

  // Get items by order request status
  Stream<List<InventoryItem>> getItemsByOrderRequestStatus(OrderRequestStatus? status) {
    return _inventoryRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return _mapToInventoryItem(data);
      }).where((item) => item.orderRequestStatus == status).toList();
    });
  }

  // Get items with no active order request
  Stream<List<InventoryItem>> getItemsWithNoActiveRequest() {
    return getItemsByOrderRequestStatus(null);
  }

  // Get items with pending order requests
  Stream<List<InventoryItem>> getPendingOrderRequestItems() {
    return getItemsByOrderRequestStatus(OrderRequestStatus.pending);
  }

  // Get items with approved order requests (waiting for restock)
  Stream<List<InventoryItem>> getApprovedOrderRequestItems() {
    return getItemsByOrderRequestStatus(OrderRequestStatus.approved);
  }

  // Get items with rejected order requests
  Stream<List<InventoryItem>> getRejectedOrderRequestItems() {
    return getItemsByOrderRequestStatus(OrderRequestStatus.rejected);
  }

  // Get items with completed order requests
  Stream<List<InventoryItem>> getCompletedOrderRequestItems() {
    return getItemsByOrderRequestStatus(OrderRequestStatus.completed);
  }

  // Update order request status
  Future<void> updateOrderRequestStatus(String itemId, OrderRequestStatus? status) async {
    try {
      await _inventoryRef.doc(itemId).update({
        'orderRequestStatus': status?.value,
      });
    } catch (e) {
      throw InventoryServiceException('Failed to update order request status: ${e.toString()}');
    }
  }

  // Create order request with status
  Future<void> createOrderRequest(String itemId, String orderRequestId) async {
    try {
      await _inventoryRef.doc(itemId).update({
        'pendingOrderRequest': true,
        'orderRequestDate': Timestamp.now(),
        'orderRequestId': orderRequestId,
        'orderRequestStatus': OrderRequestStatus.pending.value,
      });
    } catch (e) {
      throw InventoryServiceException('Failed to create order request: ${e.toString()}');
    }
  }

  // Cancel order request - sets status back to null
  Future<void> cancelOrderRequest(String itemId) async {
    try {
      await _inventoryRef.doc(itemId).update({
        'pendingOrderRequest': false,
        'orderRequestDate': null,
        'orderRequestId': null,
        'orderRequestStatus': null, // Set to null for no active request
      });
    } catch (e) {
      throw InventoryServiceException('Failed to cancel order request: ${e.toString()}');
    }
  }

  // Complete order request - increase stock and reset status
  Future<void> completeOrderRequest(String itemId, int newStockLevel) async {
    try {
      await _inventoryRef.doc(itemId).update({
        'currentStock': newStockLevel,
        'lastRestocked': Timestamp.now(),
        'pendingOrderRequest': false,
        'orderRequestDate': null,
        'orderRequestId': null,
        'orderRequestStatus': null, // Reset to null after completion
      });
    } catch (e) {
      throw InventoryServiceException('Failed to complete order request: ${e.toString()}');
    }
  }

  // Listen for status changes from external systems
  Stream<InventoryItem?> listenToItemStatusChanges(String itemId) {
    return _inventoryRef.doc(itemId).snapshots().map((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        return _mapToInventoryItem(data);
      }
      return null;
    });
  }

  // Data migration method to fix existing inventory records
  Future<void> migrateExistingInventoryRecords() async {
    try {
      print('🔄 Starting inventory records migration...');

      final snapshot = await _inventoryRef.get();
      int updatedCount = 0;
      int totalCount = snapshot.docs.length;

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // Always ensure orderRequestStatus field exists
        bool needsUpdate = false;
        String? orderRequestStatus;

        if (!data.containsKey('orderRequestStatus')) {
          needsUpdate = true;
          final pendingOrderRequest = data['pendingOrderRequest'] == true;

          // Determine correct status based on business logic
          if (pendingOrderRequest) {
            // If there's a pending request, set to pending
            orderRequestStatus = 'pending';
          } else {
            // If no pending request, set to null (no active request)
            orderRequestStatus = null;
          }
        } else {
          // Field exists, but verify it's consistent with pendingOrderRequest
          final pendingOrderRequest = data['pendingOrderRequest'] == true;
          final currentStatus = data['orderRequestStatus'];

          if (pendingOrderRequest && currentStatus == null) {
            // Fix inconsistency: has pending request but null status
            needsUpdate = true;
            orderRequestStatus = 'pending';
          } else if (!pendingOrderRequest && currentStatus == 'pending') {
            // Fix inconsistency: no pending request but pending status
            needsUpdate = true;
            orderRequestStatus = null;
          }
        }

        if (needsUpdate) {
          // Update the document
          await doc.reference.update({
            'orderRequestStatus': orderRequestStatus,
          });

          updatedCount++;
          print('✅ Updated ${doc.id}: orderRequestStatus = $orderRequestStatus');
        }
      }

      print('🎉 Migration completed: $updatedCount/$totalCount records updated');
    } catch (e) {
      print('❌ Migration failed: $e');
      throw InventoryServiceException('Failed to migrate inventory records: ${e.toString()}');
    }
  }

  // Helper method to parse integer values safely
  int _parseIntValue(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.round();
    return int.tryParse(value.toString()) ?? 0;
  }

  // Convert Firestore data to InventoryItem
  InventoryItem _mapToInventoryItem(Map<String, dynamic> data) {
    try {
      // Handle different number types for stock values
      int currentStock = 0;
      int minStock = 0;
      int maxStock = 0;
      double unitPrice = 0.0;

      // Parse currentStock
      if (data['currentStock'] != null) {
        if (data['currentStock'] is int) {
          currentStock = data['currentStock'];
        } else if (data['currentStock'] is double) {
          currentStock = (data['currentStock'] as double).round();
        } else {
          currentStock = int.tryParse(data['currentStock'].toString()) ?? 0;
        }
      }

      // Parse minStock
      if (data['minStock'] != null) {
        if (data['minStock'] is int) {
          minStock = data['minStock'];
        } else if (data['minStock'] is double) {
          minStock = (data['minStock'] as double).round();
        } else {
          minStock = int.tryParse(data['minStock'].toString()) ?? 0;
        }
      }

      // Parse maxStock
      if (data['maxStock'] != null) {
        if (data['maxStock'] is int) {
          maxStock = data['maxStock'];
        } else if (data['maxStock'] is double) {
          maxStock = (data['maxStock'] as double).round();
        } else {
          maxStock = int.tryParse(data['maxStock'].toString()) ?? 0;
        }
      }

      // Parse unitPrice
      if (data['unitPrice'] != null) {
        if (data['unitPrice'] is double) {
          unitPrice = data['unitPrice'];
        } else if (data['unitPrice'] is int) {
          unitPrice = (data['unitPrice'] as int).toDouble();
        } else {
          unitPrice = double.tryParse(data['unitPrice'].toString()) ?? 0.0;
        }
      }

      // Determine the correct orderRequestStatus based on business logic
      final pendingOrderRequest = data['pendingOrderRequest'] == true;
      final rawOrderRequestStatus = data['orderRequestStatus']?.toString();

      OrderRequestStatus? orderRequestStatus;
      if (rawOrderRequestStatus != null) {
        // Use existing status if present
        orderRequestStatus = OrderRequestStatusExtension.fromString(rawOrderRequestStatus);
      } else {
        // For existing records without the field, determine status based on business logic
        if (pendingOrderRequest) {
          // If pendingOrderRequest is true, it should be pending
          orderRequestStatus = OrderRequestStatus.pending;
        } else {
          // If no pending request, status should be null (no active request)
          orderRequestStatus = null;
        }
      }

      return InventoryItem(
        id: data['id']?.toString() ?? '',
        name: data['name']?.toString() ?? '',
        category: data['category']?.toString() ?? '',
        currentStock: currentStock,
        minStock: minStock,
        maxStock: maxStock,
        unitPrice: unitPrice,
        supplier: data['supplier']?.toString() ?? '',
        location: data['location']?.toString() ?? '',
        description: data['description']?.toString() ?? '',
        lastRestocked: data['lastRestocked'] != null
            ? (data['lastRestocked'] as Timestamp).toDate()
            : null,
        imageUrl: data['imageUrl']?.toString(),
        pendingOrderRequest: pendingOrderRequest,
        orderRequestDate: data['orderRequestDate'] != null
            ? (data['orderRequestDate'] as Timestamp).toDate()
            : null,
        orderRequestId: data['orderRequestId']?.toString(),
        orderRequestStatus: orderRequestStatus,
      );
    } catch (e) {
      print('Error mapping item data: $e');
      print('Raw data: $data');
      rethrow;
    }
  }

  // Convert InventoryItem to Firestore map
  Map<String, dynamic> _inventoryItemToMap(InventoryItem item) {
    return {
      'id': item.id,
      'name': item.name,
      'category': item.category,
      'currentStock': item.currentStock,
      'minStock': item.minStock,
      'maxStock': item.maxStock,
      'unitPrice': item.unitPrice,
      'supplier': item.supplier,
      'location': item.location,
      'description': item.description,
      'lastRestocked': item.lastRestocked != null
          ? Timestamp.fromDate(item.lastRestocked!)
          : null,
      'imageUrl': item.imageUrl,
      'pendingOrderRequest': item.pendingOrderRequest,
      'orderRequestDate': item.orderRequestDate != null
          ? Timestamp.fromDate(item.orderRequestDate!)
          : null,
      'orderRequestId': item.orderRequestId,
      'orderRequestStatus': item.orderRequestStatus?.value,
    };
  }
}

// Custom exception for inventory service errors
class InventoryServiceException implements Exception {
  final String message;
  InventoryServiceException(this.message);
  
  @override
  String toString() => 'InventoryServiceException: $message';
}
