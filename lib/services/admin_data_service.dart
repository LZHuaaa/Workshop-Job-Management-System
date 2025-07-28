import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/firebase_data_populator.dart';
import 'inventory_usage_data_populator.dart';

/// Admin service for managing sample data population and database operations
/// This service provides hidden admin functionality for data management
class AdminDataService {
  static final AdminDataService _instance = AdminDataService._internal();
  factory AdminDataService() => _instance;
  AdminDataService._internal();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Admin access tracking
  static int _tapCount = 0;
  static DateTime? _lastTapTime;
  static const int _requiredTaps = 7; // Number of taps to unlock admin features
  static const Duration _tapTimeout = Duration(seconds: 3); // Reset if too much time between taps

  /// Check if admin mode should be unlocked based on tap sequence
  /// Returns true if the secret tap sequence is completed
  static bool checkAdminUnlock() {
    final now = DateTime.now();
    
    // Reset tap count if too much time has passed
    if (_lastTapTime != null && now.difference(_lastTapTime!) > _tapTimeout) {
      _tapCount = 0;
    }
    
    _tapCount++;
    _lastTapTime = now;
    
    if (_tapCount >= _requiredTaps) {
      _tapCount = 0; // Reset for next time
      return true;
    }
    
    return false;
  }

  /// Get current tap count for UI feedback
  static int get currentTapCount => _tapCount;
  
  /// Get remaining taps needed for admin unlock
  static int get remainingTaps => _requiredTaps - _tapCount;

  /// Populate Firebase with comprehensive Malaysian sample data
  /// This is the main method for populating the database
  Future<AdminOperationResult> populateMalaysianSampleData({
    int customerCount = 30,
    int maxVehiclesPerCustomer = 3,
    int maxServiceRecordsPerVehicle = 5,
    int appointmentCount = 25,
    int invoiceCount = 20,
    int inventoryItemCount = 50,
    int orderRequestCount = 15,
  }) async {
    try {
      debugPrint('🔧 Admin: Starting Malaysian sample data population...');
      
      // Check if collections already have data
      final hasExistingData = await _checkExistingData();
      if (hasExistingData) {
        debugPrint('⚠️ Admin: Existing data detected in collections');
      }

      // Populate data using the FirebaseDataPopulator
      await FirebaseDataPopulator.populateAllData(
        customerCount: customerCount,
        maxVehiclesPerCustomer: maxVehiclesPerCustomer,
        maxServiceRecordsPerVehicle: maxServiceRecordsPerVehicle,
        appointmentCount: appointmentCount,
        invoiceCount: invoiceCount,
        inventoryItemCount: inventoryItemCount,
        orderRequestCount: orderRequestCount,
      );

      // Verify data was inserted correctly
      final dataStats = await _getDataStatistics();
      
      debugPrint('✅ Admin: Malaysian sample data population completed successfully');
      debugPrint('📊 Admin: Data statistics: $dataStats');

      return AdminOperationResult(
        success: true,
        message: 'Successfully populated Firebase with Malaysian sample data',
        details: dataStats,
      );
      
    } catch (e, stackTrace) {
      debugPrint('❌ Admin: Error populating Malaysian sample data: $e');
      debugPrint('📍 Admin: Stack trace: $stackTrace');
      
      return AdminOperationResult(
        success: false,
        message: 'Failed to populate sample data: ${e.toString()}',
        error: e.toString(),
      );
    }
  }

  /// Clear all data from Firebase collections (use with extreme caution!)
  Future<AdminOperationResult> clearAllData() async {
    try {
      debugPrint('🗑️ Admin: Starting data clearing operation...');
      
      // Get data statistics before clearing
      final beforeStats = await _getDataStatistics();
      debugPrint('📊 Admin: Data before clearing: $beforeStats');

      // Clear data using the FirebaseDataPopulator
      await FirebaseDataPopulator.clearAllData();

      // Verify data was cleared
      final afterStats = await _getDataStatistics();
      debugPrint('📊 Admin: Data after clearing: $afterStats');

      debugPrint('✅ Admin: Data clearing completed successfully');

      return AdminOperationResult(
        success: true,
        message: 'Successfully cleared all data from Firebase',
        details: {
          'before': beforeStats,
          'after': afterStats,
        },
      );
      
    } catch (e, stackTrace) {
      debugPrint('❌ Admin: Error clearing data: $e');
      debugPrint('📍 Admin: Stack trace: $stackTrace');
      
      return AdminOperationResult(
        success: false,
        message: 'Failed to clear data: ${e.toString()}',
        error: e.toString(),
      );
    }
  }

  /// Get comprehensive statistics about current data in Firebase
  Future<Map<String, dynamic>> getDataStatistics() async {
    return await _getDataStatistics();
  }

  /// Check if any collections have existing data
  Future<bool> _checkExistingData() async {
    try {
      final collections = [
        'customers',
        'vehicles',
        'service_records',
        'appointments',
        'invoices',
        'inventory',
        'order_requests',
        'inventory_usage',
      ];

      for (final collection in collections) {
        final snapshot = await _firestore.collection(collection).limit(1).get();
        if (snapshot.docs.isNotEmpty) {
          return true;
        }
      }
      
      return false;
    } catch (e) {
      debugPrint('⚠️ Admin: Error checking existing data: $e');
      return false;
    }
  }

  /// Get detailed statistics about data in all collections
  Future<Map<String, dynamic>> _getDataStatistics() async {
    try {
      final stats = <String, dynamic>{};
      
      final collections = [
        'customers',
        'vehicles',
        'service_records', 
        'appointments',
        'invoices',
        'Inventory',
        'order_requests',
      ];

      for (final collection in collections) {
        try {
          final snapshot = await _firestore.collection(collection).get();
          stats[collection] = {
            'count': snapshot.docs.length,
            'lastUpdated': snapshot.docs.isNotEmpty 
              ? snapshot.docs.first.data()['createdAt']?.toString() ?? 'Unknown'
              : 'No data',
          };
        } catch (e) {
          stats[collection] = {
            'count': 0,
            'error': e.toString(),
          };
        }
      }

      stats['totalDocuments'] = stats.values
          .where((v) => v is Map && v.containsKey('count'))
          .fold<int>(0, (sum, v) => sum + (v['count'] as int));
      
      stats['timestamp'] = DateTime.now().toIso8601String();
      
      return stats;
    } catch (e) {
      debugPrint('⚠️ Admin: Error getting data statistics: $e');
      return {
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Validate Firebase connection and permissions
  Future<AdminOperationResult> validateFirebaseConnection() async {
    try {
      debugPrint('🔍 Admin: Validating Firebase connection...');
      
      // Try to read from a collection
      await _firestore.collection('customers').limit(1).get();
      
      // Try to write a test document
      final testDoc = _firestore.collection('_admin_test').doc('test');
      await testDoc.set({
        'test': true,
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      // Clean up test document
      await testDoc.delete();
      
      debugPrint('✅ Admin: Firebase connection validated successfully');
      
      return AdminOperationResult(
        success: true,
        message: 'Firebase connection and permissions validated successfully',
      );
      
    } catch (e, stackTrace) {
      debugPrint('❌ Admin: Firebase validation failed: $e');
      debugPrint('📍 Admin: Stack trace: $stackTrace');
      
      return AdminOperationResult(
        success: false,
        message: 'Firebase validation failed: ${e.toString()}',
        error: e.toString(),
      );
    }
  }

  /// Fix inventory usage data to match inventory items exactly
  Future<AdminOperationResult> fixInventoryUsageData() async {
    try {
      debugPrint('🔧 Starting inventory usage data fix...');

      await InventoryUsageDataPopulator.forceRepopulateWithCorrectData(usageRecordCount: 25);

      return AdminOperationResult(
        success: true,
        message: 'Inventory usage data fixed successfully',
        details: {
          'description': 'All usage records now match the actual inventory items with correct names, categories, and prices.',
          'records_updated': 25,
          'operation': 'force_repopulate',
        },
      );
    } catch (e) {
      debugPrint('❌ Error fixing inventory usage data: $e');
      return AdminOperationResult(
        success: false,
        message: 'Failed to fix inventory usage data',
        error: e.toString(),
      );
    }
  }
}

/// Result class for admin operations
class AdminOperationResult {
  final bool success;
  final String message;
  final Map<String, dynamic>? details;
  final String? error;

  AdminOperationResult({
    required this.success,
    required this.message,
    this.details,
    this.error,
  });

  @override
  String toString() {
    return 'AdminOperationResult(success: $success, message: $message, details: $details, error: $error)';
  }
}
