import 'package:flutter/foundation.dart';
import '../services/inventory_usage_data_populator.dart';

/// Script to fix inventory usage data to match inventory items
/// This script clears existing usage data and repopulates it with correct data
/// that matches the actual inventory items in the database.
class FixInventoryUsageDataScript {
  
  /// Run the fix script
  static Future<void> run() async {
    try {
      debugPrint('🚀 Starting inventory usage data fix script...');
      debugPrint('');
      
      // Force repopulate with correct data
      await InventoryUsageDataPopulator.forceRepopulateWithCorrectData(
        usageRecordCount: 25,
      );
      
      debugPrint('');
      debugPrint('🎉 Inventory usage data fix completed successfully!');
      debugPrint('✅ All usage records now match the actual inventory items');
      debugPrint('✅ Item names, categories, and prices are now consistent');
      debugPrint('');
      debugPrint('You can now check the Usage Management screen to see the corrected data.');
      
    } catch (e) {
      debugPrint('❌ Error running fix script: $e');
      rethrow;
    }
  }
}
