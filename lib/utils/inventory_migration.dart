import '../services/inventory_service.dart';

/// Utility class for migrating existing inventory data to support the new orderRequestStatus field
class InventoryMigration {
  static final InventoryService _inventoryService = InventoryService();

  /// Run the migration to add orderRequestStatus field to existing inventory records
  /// 
  /// This method should be called once to update existing inventory items that don't have
  /// the orderRequestStatus field. It will:
  /// 
  /// 1. Find all inventory items missing the orderRequestStatus field
  /// 2. Set orderRequestStatus = "pending" for items with pendingOrderRequest = true
  /// 3. Set orderRequestStatus = null for items with pendingOrderRequest = false
  /// 
  /// Usage:
  /// ```dart
  /// await InventoryMigration.runMigration();
  /// ```
  static Future<void> runMigration() async {
    try {
      print('🚀 Starting inventory migration...');
      await _inventoryService.migrateExistingInventoryRecords();
      print('✅ Migration completed successfully!');
    } catch (e) {
      print('❌ Migration failed: $e');
      rethrow;
    }
  }

  /// Check if migration is needed by looking for records without orderRequestStatus field
  static Future<bool> isMigrationNeeded() async {
    try {
      final items = await _inventoryService.getInventoryItems().first;
      
      // Check if any items are missing the orderRequestStatus field
      // This is a simplified check - in practice, you might want to check the raw Firestore data
      for (final item in items) {
        // If we find any item where the status logic seems inconsistent, migration might be needed
        if (item.pendingOrderRequest && item.orderRequestStatus == null) {
          return true;
        }
      }
      
      return false;
    } catch (e) {
      print('Error checking migration status: $e');
      return false;
    }
  }

  /// Get migration status information
  static Future<Map<String, dynamic>> getMigrationStatus() async {
    try {
      final items = await _inventoryService.getInventoryItems().first;
      
      int totalItems = items.length;
      int itemsWithPendingRequests = items.where((item) => item.pendingOrderRequest).length;
      int itemsWithPendingStatus = items.where((item) => item.hasOrderRequestPending).length;
      int itemsWithNullStatus = items.where((item) => item.hasNoActiveOrderRequest).length;
      
      return {
        'totalItems': totalItems,
        'itemsWithPendingRequests': itemsWithPendingRequests,
        'itemsWithPendingStatus': itemsWithPendingStatus,
        'itemsWithNullStatus': itemsWithNullStatus,
        'migrationNeeded': itemsWithPendingRequests != itemsWithPendingStatus,
      };
    } catch (e) {
      return {
        'error': e.toString(),
      };
    }
  }
}

/// Extension to add migration functionality to InventoryService
extension InventoryServiceMigration on InventoryService {
  /// Quick method to run migration from any InventoryService instance
  Future<void> runMigration() async {
    await InventoryMigration.runMigration();
  }
}
