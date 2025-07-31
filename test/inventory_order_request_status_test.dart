import 'package:flutter_test/flutter_test.dart';
import 'package:assignment/models/inventory_item.dart';

void main() {
  group('InventoryItem OrderRequestStatus Tests', () {
    test('should create InventoryItem with default null order request status', () {
      final item = InventoryItem(
        id: 'test-id',
        name: 'Test Item',
        category: 'Test Category',
        currentStock: 10,
        minStock: 5,
        maxStock: 50,
        unitPrice: 25.0,
        supplier: 'Test Supplier',
        location: 'Test Location',
        description: 'Test Description',
      );

      expect(item.orderRequestStatus, null);
      expect(item.hasOrderRequestPending, false);
      expect(item.hasOrderRequestApproved, false);
      expect(item.hasOrderRequestRejected, false);
      expect(item.hasOrderRequestCompleted, false);
      expect(item.hasNoActiveOrderRequest, true);
    });

    test('should create InventoryItem with specific order request status', () {
      final item = InventoryItem(
        id: 'test-id',
        name: 'Test Item',
        category: 'Test Category',
        currentStock: 10,
        minStock: 5,
        maxStock: 50,
        unitPrice: 25.0,
        supplier: 'Test Supplier',
        location: 'Test Location',
        description: 'Test Description',
        orderRequestStatus: OrderRequestStatus.approved,
      );

      expect(item.orderRequestStatus, OrderRequestStatus.approved);
      expect(item.hasOrderRequestPending, false);
      expect(item.hasOrderRequestApproved, true);
      expect(item.isWaitingForRestock, true);
    });

    test('should provide correct status text for each status', () {
      final pendingItem = InventoryItem(
        id: 'test-id',
        name: 'Test Item',
        category: 'Test Category',
        currentStock: 10,
        minStock: 5,
        maxStock: 50,
        unitPrice: 25.0,
        supplier: 'Test Supplier',
        location: 'Test Location',
        description: 'Test Description',
        orderRequestStatus: OrderRequestStatus.pending,
      );

      final approvedItem = pendingItem.copyWith(
        orderRequestStatus: OrderRequestStatus.approved,
      );

      final rejectedItem = pendingItem.copyWith(
        orderRequestStatus: OrderRequestStatus.rejected,
      );

      final completedItem = pendingItem.copyWith(
        orderRequestStatus: OrderRequestStatus.completed,
      );

      expect(pendingItem.orderRequestStatusText, 'Pending Company Approval');
      expect(approvedItem.orderRequestStatusText, 'Approved - Company Processing');
      expect(rejectedItem.orderRequestStatusText, 'Rejected by Company');
      expect(completedItem.orderRequestStatusText, 'Restocking Complete');
    });

    test('should copy with new order request status', () {
      final originalItem = InventoryItem(
        id: 'test-id',
        name: 'Test Item',
        category: 'Test Category',
        currentStock: 10,
        minStock: 5,
        maxStock: 50,
        unitPrice: 25.0,
        supplier: 'Test Supplier',
        location: 'Test Location',
        description: 'Test Description',
        orderRequestStatus: OrderRequestStatus.pending,
      );

      final updatedItem = originalItem.copyWith(
        orderRequestStatus: OrderRequestStatus.approved,
      );

      expect(originalItem.orderRequestStatus, OrderRequestStatus.pending);
      expect(updatedItem.orderRequestStatus, OrderRequestStatus.approved);
      expect(updatedItem.id, originalItem.id); // Other fields should remain the same
    });

    test('should serialize and deserialize with order request status', () {
      final originalItem = InventoryItem(
        id: 'test-id',
        name: 'Test Item',
        category: 'Test Category',
        currentStock: 10,
        minStock: 5,
        maxStock: 50,
        unitPrice: 25.0,
        supplier: 'Test Supplier',
        location: 'Test Location',
        description: 'Test Description',
        orderRequestStatus: OrderRequestStatus.approved,
      );

      final json = originalItem.toJson();
      expect(json['orderRequestStatus'], 'approved');

      final deserializedItem = InventoryItem.fromJson(json);
      expect(deserializedItem.orderRequestStatus, OrderRequestStatus.approved);
      expect(deserializedItem.hasOrderRequestApproved, true);
    });

    test('should handle backward compatibility for missing orderRequestStatus field', () {
      final jsonWithoutStatus = {
        'id': 'test-id',
        'name': 'Test Item',
        'category': 'Test Category',
        'currentStock': 10,
        'minStock': 5,
        'maxStock': 50,
        'unitPrice': 25.0,
        'supplier': 'Test Supplier',
        'location': 'Test Location',
        'description': 'Test Description',
        'pendingOrderRequest': false,
        // orderRequestStatus field is missing
      };

      final item = InventoryItem.fromJson(jsonWithoutStatus);
      expect(item.orderRequestStatus, null); // Should default to null
    });
  });

  group('OrderRequestStatusExtension Tests', () {
    test('should convert enum to string value correctly', () {
      expect(OrderRequestStatus.pending.value, 'pending');
      expect(OrderRequestStatus.approved.value, 'approved');
      expect(OrderRequestStatus.rejected.value, 'rejected');
      expect(OrderRequestStatus.completed.value, 'completed');
    });

    test('should parse string to enum correctly', () {
      expect(OrderRequestStatusExtension.fromString('pending'), OrderRequestStatus.pending);
      expect(OrderRequestStatusExtension.fromString('approved'), OrderRequestStatus.approved);
      expect(OrderRequestStatusExtension.fromString('rejected'), OrderRequestStatus.rejected);
      expect(OrderRequestStatusExtension.fromString('completed'), OrderRequestStatus.completed);
    });

    test('should handle case insensitive parsing', () {
      expect(OrderRequestStatusExtension.fromString('PENDING'), OrderRequestStatus.pending);
      expect(OrderRequestStatusExtension.fromString('Approved'), OrderRequestStatus.approved);
      expect(OrderRequestStatusExtension.fromString('REJECTED'), OrderRequestStatus.rejected);
    });

    test('should default to null for invalid or null values', () {
      expect(OrderRequestStatusExtension.fromString(null), null);
      expect(OrderRequestStatusExtension.fromString(''), null);
      expect(OrderRequestStatusExtension.fromString('invalid'), null);
    });
  });

  group('New Business Logic Tests', () {
    test('should handle null status correctly', () {
      final item = InventoryItem(
        id: 'test-id',
        name: 'Test Item',
        category: 'Test Category',
        currentStock: 2, // Low stock
        minStock: 5,
        maxStock: 50,
        unitPrice: 25.0,
        supplier: 'Test Supplier',
        location: 'Test Location',
        description: 'Test Description',
        orderRequestStatus: null, // No active request
      );

      expect(item.hasNoActiveOrderRequest, true);
      expect(item.canRequestOrderNew, true); // Can request because low stock and no active request
      expect(item.orderRequestStatusText, 'No Active Request');
    });

    test('should handle copyWith clearOrderRequestStatus', () {
      final item = InventoryItem(
        id: 'test-id',
        name: 'Test Item',
        category: 'Test Category',
        currentStock: 10,
        minStock: 5,
        maxStock: 50,
        unitPrice: 25.0,
        supplier: 'Test Supplier',
        location: 'Test Location',
        description: 'Test Description',
        orderRequestStatus: OrderRequestStatus.pending,
      );

      final updatedItem = item.copyWith(clearOrderRequestStatus: true);
      expect(updatedItem.orderRequestStatus, null);
      expect(updatedItem.hasNoActiveOrderRequest, true);
    });

    test('should provide correct status colors', () {
      final pendingItem = InventoryItem(
        id: 'test-id',
        name: 'Test Item',
        category: 'Test Category',
        currentStock: 10,
        minStock: 5,
        maxStock: 50,
        unitPrice: 25.0,
        supplier: 'Test Supplier',
        location: 'Test Location',
        description: 'Test Description',
        orderRequestStatus: OrderRequestStatus.pending,
      );

      final nullItem = pendingItem.copyWith(clearOrderRequestStatus: true);

      expect(pendingItem.orderRequestStatusColor, '#FFA500'); // Orange
      expect(nullItem.orderRequestStatusColor, '#9E9E9E'); // Grey
    });
  });
}
