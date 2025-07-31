# Order Request Status Implementation Guide

## Overview

This guide explains the new `orderRequestStatus` field that has been added to the inventory collection structure to track the approval workflow for order requests.

## New Field Structure

### OrderRequestStatus Enum

```dart
enum OrderRequestStatus {
  pending,    // Initial state when order request is created
  approved,   // When management approves the order request
  rejected,   // When management rejects the order request
  completed,  // When the approved order has been restocked
}
```

### Database Field

- **Field Name**: `orderRequestStatus`
- **Type**: `String` (nullable)
- **Possible Values**: `null`, `"pending"`, `"approved"`, `"rejected"`, `"completed"`
- **Default Value**: `null` (no active order request)

### Status Field Rules

1. **Set to `null` for**:
   - Items in good stock (currentStock > minStock)
   - Items that are low stock but have NOT requested an order
   - Items where the order request has been cancelled

2. **Set to `"pending"`** only for active pending requests

3. **Set to `"approved"` and `"completed"`** by external company systems (not this manager app)

## Updated InventoryItem Model

### New Properties

```dart
final OrderRequestStatus orderRequestStatus;
```

### New Helper Methods

```dart
// Status check methods
bool get hasOrderRequestPending => orderRequestStatus == OrderRequestStatus.pending;
bool get hasOrderRequestApproved => orderRequestStatus == OrderRequestStatus.approved;
bool get hasOrderRequestRejected => orderRequestStatus == OrderRequestStatus.rejected;
bool get hasOrderRequestCompleted => orderRequestStatus == OrderRequestStatus.completed;

// Business logic helpers
bool get isWaitingForRestock => hasOrderRequestApproved;
String get orderRequestStatusText; // Human-readable status text
```

## Updated InventoryService Methods

### New Query Methods

```dart
// Get items by specific status
Stream<List<InventoryItem>> getItemsByOrderRequestStatus(OrderRequestStatus status);

// Convenience methods for each status
Stream<List<InventoryItem>> getPendingOrderRequestItems();
Stream<List<InventoryItem>> getApprovedOrderRequestItems();
Stream<List<InventoryItem>> getRejectedOrderRequestItems();
Stream<List<InventoryItem>> getCompletedOrderRequestItems();
```

### New Update Methods

```dart
// Update order request status
Future<void> updateOrderRequestStatus(String itemId, OrderRequestStatus status);

// Create order request with status
Future<void> createOrderRequest(String itemId, String orderRequestId);

// Cancel order request
Future<void> cancelOrderRequest(String itemId);
```

## Business Logic Workflow

### 1. Creating Order Requests

When a user creates an order request:

```dart
// The item is updated with:
final updatedItem = item.copyWith(
  pendingOrderRequest: true,
  orderRequestDate: DateTime.now(),
  orderRequestId: orderRequestId,
  orderRequestStatus: OrderRequestStatus.pending, // NEW FIELD
);
```

### 2. Management Approval Process

Managers can approve or reject pending requests:

```dart
// Approve request
await inventoryService.updateOrderRequestStatus(itemId, OrderRequestStatus.approved);

// Reject request
await inventoryService.updateOrderRequestStatus(itemId, OrderRequestStatus.rejected);
```

### 3. Completion Process

When approved items are restocked:

```dart
// Mark as completed
await inventoryService.updateOrderRequestStatus(itemId, OrderRequestStatus.completed);
```

## Backward Compatibility

### Existing Data Handling

- Items without the `orderRequestStatus` field will default to `OrderRequestStatus.pending`
- The `pendingOrderRequest` boolean field continues to work alongside the new status field
- Existing order request workflow remains functional

### Migration Strategy

No manual migration is required. The system handles missing fields gracefully:

```dart
// In _mapToInventoryItem method
orderRequestStatus: OrderRequestStatusExtension.fromString(data['orderRequestStatus']?.toString()),

// Extension handles null/missing values
static OrderRequestStatus fromString(String? value) {
  switch (value?.toLowerCase()) {
    case 'pending': return OrderRequestStatus.pending;
    case 'approved': return OrderRequestStatus.approved;
    case 'rejected': return OrderRequestStatus.rejected;
    case 'completed': return OrderRequestStatus.completed;
    default: return OrderRequestStatus.pending; // Default for backward compatibility
  }
}
```

## Usage Examples

### 1. Display Items by Status

```dart
// Show pending requests for management review
StreamBuilder<List<InventoryItem>>(
  stream: inventoryService.getPendingOrderRequestItems(),
  builder: (context, snapshot) {
    final pendingItems = snapshot.data ?? [];
    return ListView.builder(
      itemCount: pendingItems.length,
      itemBuilder: (context, index) {
        final item = pendingItems[index];
        return ListTile(
          title: Text(item.name),
          subtitle: Text(item.orderRequestStatusText),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.check),
                onPressed: () => _approveRequest(item.id),
              ),
              IconButton(
                icon: Icon(Icons.close),
                onPressed: () => _rejectRequest(item.id),
              ),
            ],
          ),
        );
      },
    );
  },
);
```

### 2. Filter Items by Status

```dart
// Get items waiting for restock (approved status)
final waitingForRestock = await inventoryService
    .getApprovedOrderRequestItems()
    .first;

// Display status-specific information
for (final item in waitingForRestock) {
  print('${item.name}: ${item.orderRequestStatusText}');
  print('Waiting for restock: ${item.isWaitingForRestock}');
}
```

### 3. Management Dashboard

```dart
// Count items by status for dashboard
final pendingCount = await inventoryService.getPendingOrderRequestItems().first.then((items) => items.length);
final approvedCount = await inventoryService.getApprovedOrderRequestItems().first.then((items) => items.length);
final rejectedCount = await inventoryService.getRejectedOrderRequestItems().first.then((items) => items.length);
```

## Testing

Comprehensive tests are included in `test/inventory_order_request_status_test.dart`:

- Default status assignment
- Status transitions
- Serialization/deserialization
- Backward compatibility
- Helper method functionality

Run tests with:
```bash
flutter test test/inventory_order_request_status_test.dart
```

## Integration Points

### UI Components

1. **Item Details Screen**: Updated to set status when creating/canceling requests
2. **Management Interface**: New screens can use status-based filtering
3. **Dashboard Cards**: Can show counts by status
4. **Approval Workflows**: Status transitions for management actions

### Database Operations

1. **Create**: New items default to `pending` status
2. **Read**: Status-based queries and filtering
3. **Update**: Status transitions through management actions
4. **Delete**: Cleanup includes status field

## Best Practices

1. **Always use the enum**: Don't hardcode string values
2. **Check status before actions**: Verify current status before transitions
3. **Provide user feedback**: Show status changes in UI
4. **Handle errors gracefully**: Wrap status updates in try-catch blocks
5. **Maintain consistency**: Update both `pendingOrderRequest` and `orderRequestStatus` together

## Future Enhancements

Potential improvements that could be added:

1. **Status History**: Track status change timestamps
2. **Approval Notes**: Add reason/comments for rejections
3. **Batch Operations**: Approve/reject multiple requests at once
4. **Notifications**: Alert users of status changes
5. **Reporting**: Analytics on approval rates and timelines
