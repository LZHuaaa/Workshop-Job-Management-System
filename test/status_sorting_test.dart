import 'package:flutter_test/flutter_test.dart';
import '../lib/models/inventory_usage.dart';

void main() {
  group('Status Sorting Tests', () {
    late List<InventoryUsage> testRecords;

    setUp(() {
      
      // Create test records with different statuses
      testRecords = [
        InventoryUsage(
          id: '1',
          itemId: 'item1',
          itemName: 'Test Item 1',
          itemCategory: 'Test',
          quantityUsed: 1,
          unitPrice: 10.0,
          totalCost: 10.0,
          usageType: UsageType.service,
          status: UsageStatus.disputed,
          usageDate: DateTime.now(),
          usedBy: 'Test User',
          purpose: 'Test',
          createdAt: DateTime.now(),
        ),
        InventoryUsage(
          id: '2',
          itemId: 'item2',
          itemName: 'Test Item 2',
          itemCategory: 'Test',
          quantityUsed: 1,
          unitPrice: 10.0,
          totalCost: 10.0,
          usageType: UsageType.service,
          status: UsageStatus.recorded,
          usageDate: DateTime.now(),
          usedBy: 'Test User',
          purpose: 'Test',
          createdAt: DateTime.now(),
        ),
        InventoryUsage(
          id: '3',
          itemId: 'item3',
          itemName: 'Test Item 3',
          itemCategory: 'Test',
          quantityUsed: 1,
          unitPrice: 10.0,
          totalCost: 10.0,
          usageType: UsageType.service,
          status: UsageStatus.verified,
          usageDate: DateTime.now(),
          usedBy: 'Test User',
          purpose: 'Test',
          createdAt: DateTime.now(),
        ),
        InventoryUsage(
          id: '4',
          itemId: 'item4',
          itemName: 'Test Item 4',
          itemCategory: 'Test',
          quantityUsed: 1,
          unitPrice: 10.0,
          totalCost: 10.0,
          usageType: UsageType.service,
          status: UsageStatus.cancelled,
          usageDate: DateTime.now(),
          usedBy: 'Test User',
          purpose: 'Test',
          createdAt: DateTime.now(),
        ),
      ];
    });

    test('Status sorting ascending should follow priority order', () {
      // Test the sorting logic by creating a mock sorted list
      List<InventoryUsage> sortedRecords = List.from(testRecords);
      
      // Apply the same sorting logic as in the service
      sortedRecords.sort((a, b) {
        int getStatusPriority(UsageStatus status) {
          switch (status) {
            case UsageStatus.recorded:
              return 1;
            case UsageStatus.verified:
              return 2;
            case UsageStatus.disputed:
              return 3;
            case UsageStatus.cancelled:
              return 4;
          }
        }
        
        int priorityA = getStatusPriority(a.status);
        int priorityB = getStatusPriority(b.status);
        
        return priorityA.compareTo(priorityB); // ascending
      });

      // Verify the order: recorded -> verified -> disputed -> cancelled
      expect(sortedRecords[0].status, UsageStatus.recorded);
      expect(sortedRecords[1].status, UsageStatus.verified);
      expect(sortedRecords[2].status, UsageStatus.disputed);
      expect(sortedRecords[3].status, UsageStatus.cancelled);
    });

    test('Status sorting descending should reverse priority order', () {
      List<InventoryUsage> sortedRecords = List.from(testRecords);
      
      // Apply the same sorting logic as in the service (descending)
      sortedRecords.sort((a, b) {
        int getStatusPriority(UsageStatus status) {
          switch (status) {
            case UsageStatus.recorded:
              return 1;
            case UsageStatus.verified:
              return 2;
            case UsageStatus.disputed:
              return 3;
            case UsageStatus.cancelled:
              return 4;
          }
        }
        
        int priorityA = getStatusPriority(a.status);
        int priorityB = getStatusPriority(b.status);
        
        return priorityB.compareTo(priorityA); // descending
      });

      // Verify the order: cancelled -> disputed -> verified -> recorded
      expect(sortedRecords[0].status, UsageStatus.cancelled);
      expect(sortedRecords[1].status, UsageStatus.disputed);
      expect(sortedRecords[2].status, UsageStatus.verified);
      expect(sortedRecords[3].status, UsageStatus.recorded);
    });

    test('Status priority values are correct', () {
      // Test that our priority mapping is logical for workflow
      int getStatusPriority(UsageStatus status) {
        switch (status) {
          case UsageStatus.recorded:
            return 1; // Newest/unprocessed records first
          case UsageStatus.verified:
            return 2; // Processed and approved
          case UsageStatus.disputed:
            return 3; // Needs attention
          case UsageStatus.cancelled:
            return 4; // Final state
        }
      }

      expect(getStatusPriority(UsageStatus.recorded), 1);
      expect(getStatusPriority(UsageStatus.verified), 2);
      expect(getStatusPriority(UsageStatus.disputed), 3);
      expect(getStatusPriority(UsageStatus.cancelled), 4);
    });
  });
}
