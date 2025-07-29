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
      final docRef = await _inventoryRef.add(_inventoryItemToMap(item));
      
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
      await _inventoryRef.doc(item.id).update(_inventoryItemToMap(item));
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
        pendingOrderRequest: data['pendingOrderRequest'] == true,
        orderRequestDate: data['orderRequestDate'] != null
            ? (data['orderRequestDate'] as Timestamp).toDate()
            : null,
        orderRequestId: data['orderRequestId']?.toString(),
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
