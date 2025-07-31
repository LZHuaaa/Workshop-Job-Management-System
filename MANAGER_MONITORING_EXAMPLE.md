# Manager Monitoring Interface Example

This example demonstrates how managers can monitor order request status changes in real-time without having approval/rejection capabilities.

## Key Features

### 1. Real-Time Status Monitoring
```dart
// Listen to status changes for a specific item
Stream<InventoryItem?> statusStream = inventoryService.listenToItemStatusChanges(itemId);

statusStream.listen((updatedItem) {
  if (updatedItem != null) {
    // Handle status changes
    switch (updatedItem.orderRequestStatus) {
      case OrderRequestStatus.pending:
        showNotification('Order request submitted for ${updatedItem.name}');
        break;
      case OrderRequestStatus.approved:
        showNotification('Order approved for ${updatedItem.name}');
        break;
      case OrderRequestStatus.rejected:
        showNotification('Order rejected for ${updatedItem.name}');
        break;
      case OrderRequestStatus.completed:
        showCompletionDialog(updatedItem);
        break;
      case null:
        // No active request
        break;
    }
  }
});
```

### 2. Status Display Widget
```dart
Widget buildStatusDisplay(InventoryItem item) {
  if (item.orderRequestStatus == null) {
    return Text('No Active Request');
  }

  return Container(
    padding: EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: Color(int.parse(item.orderRequestStatusColor.substring(1), radix: 16) + 0xFF000000),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      item.orderRequestStatusText,
      style: TextStyle(color: Colors.white),
    ),
  );
}
```

### 3. Completion Flow Handler
```dart
void handleCompletionFlow(InventoryItem item) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: Text('Restocking Complete!'),
      content: Text('${item.name} has been restocked by the company.'),
      actions: [
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            completeOrderRequest(item);
          },
          child: Text('OK'),
        ),
      ],
    ),
  );
}

Future<void> completeOrderRequest(InventoryItem item) async {
  // Automatically update stock to max level
  final newStockLevel = item.maxStock;
  
  await inventoryService.completeOrderRequest(item.id, newStockLevel);
  
  // Show success message
  showSnackBar('${item.name} restocked successfully!');
}
```

## Status Field Rules Implementation

### 1. Null Status for Non-Requesting Items
```dart
// Items in good stock (currentStock > minStock)
final goodStockItem = InventoryItem(
  currentStock: 20,
  minStock: 10,
  orderRequestStatus: null, // No request needed
);

// Items with cancelled requests
final cancelledItem = item.copyWith(
  clearOrderRequestStatus: true, // Sets to null
  pendingOrderRequest: false,
);
```

### 2. Pending Status for Active Requests
```dart
// Only when actively requesting
await inventoryService.createOrderRequest(itemId, requestId);
// This sets orderRequestStatus to "pending"
```

### 3. External Status Updates
```dart
// Company systems update status to "approved" or "completed"
// Manager app only monitors these changes, doesn't set them

// Listen for external updates
inventoryService.listenToItemStatusChanges(itemId).listen((item) {
  if (item?.orderRequestStatus == OrderRequestStatus.approved) {
    // Company approved the request
    showApprovalNotification(item);
  }
});
```

## UI Components

### 1. Status Indicator
```dart
Widget buildStatusIndicator(InventoryItem item) {
  if (item.hasNoActiveOrderRequest) {
    return Icon(Icons.check_circle, color: Colors.green);
  }
  
  switch (item.orderRequestStatus) {
    case OrderRequestStatus.pending:
      return Icon(Icons.pending_actions, color: Colors.orange);
    case OrderRequestStatus.approved:
      return Icon(Icons.check_circle, color: Colors.blue);
    case OrderRequestStatus.rejected:
      return Icon(Icons.cancel, color: Colors.red);
    case OrderRequestStatus.completed:
      return Icon(Icons.done_all, color: Colors.green);
    default:
      return Icon(Icons.help, color: Colors.grey);
  }
}
```

### 2. Request Button Logic
```dart
Widget buildRequestButton(InventoryItem item) {
  return ElevatedButton(
    onPressed: item.canRequestOrderNew ? () => requestOrder(item) : null,
    child: Text('Request Order'),
  );
}

// canRequestOrderNew returns true only when:
// - Item is low stock (currentStock <= minStock)
// - No active order request (orderRequestStatus == null)
```

### 3. Status Timeline
```dart
Widget buildStatusTimeline(InventoryItem item) {
  return Column(
    children: [
      TimelineStep(
        title: 'Request Submitted',
        isCompleted: item.orderRequestDate != null,
        date: item.orderRequestDate,
      ),
      TimelineStep(
        title: 'Company Review',
        isCompleted: item.hasOrderRequestApproved || item.hasOrderRequestRejected,
        isActive: item.hasOrderRequestPending,
      ),
      TimelineStep(
        title: 'Processing',
        isCompleted: item.hasOrderRequestCompleted,
        isActive: item.hasOrderRequestApproved,
      ),
      TimelineStep(
        title: 'Restocked',
        isCompleted: item.hasOrderRequestCompleted,
      ),
    ],
  );
}
```

## Manager Dashboard Integration

### 1. Status Summary Cards
```dart
Widget buildStatusSummary() {
  return Row(
    children: [
      StatusCard(
        title: 'Pending Requests',
        count: pendingCount,
        color: Colors.orange,
        stream: inventoryService.getPendingOrderRequestItems(),
      ),
      StatusCard(
        title: 'Approved Orders',
        count: approvedCount,
        color: Colors.blue,
        stream: inventoryService.getApprovedOrderRequestItems(),
      ),
      StatusCard(
        title: 'Completed Today',
        count: completedTodayCount,
        color: Colors.green,
        stream: inventoryService.getCompletedOrderRequestItems(),
      ),
    ],
  );
}
```

### 2. Real-Time Notifications
```dart
void setupNotificationListener() {
  inventoryService.getInventoryItems().listen((items) {
    for (final item in items) {
      if (item.orderRequestStatus == OrderRequestStatus.completed) {
        showCompletionNotification(item);
      }
    }
  });
}
```

## Key Differences from Previous Implementation

1. **No Manager Approval**: Managers can only view status changes, not approve/reject
2. **Null Status**: Items without active requests have `orderRequestStatus = null`
3. **External Updates**: Status changes from "pending" to "approved"/"completed" come from external company systems
4. **Automatic Completion**: When status becomes "completed", the app automatically handles stock updates
5. **Real-Time Monitoring**: Managers see live updates as company systems change order statuses

This implementation provides managers with full visibility into the order request process while maintaining clear separation between manager monitoring and company approval workflows.
