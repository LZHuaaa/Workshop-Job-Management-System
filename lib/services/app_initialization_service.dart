import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../firebase_options.dart';
import 'firebase_data_populator_service.dart';
import 'inventory_usage_data_populator.dart';

class InitializationStatus {
  final bool isFirstRun;
  final bool dataPopulated;
  final bool hasData;
  final int totalDocuments;
  final String currentVersion;

  InitializationStatus({
    required this.isFirstRun,
    required this.dataPopulated,
    required this.hasData,
    required this.totalDocuments,
    required this.currentVersion,
  });
}

class AppInitializationService {
  static final AppInitializationService _instance =
      AppInitializationService._internal();
  factory AppInitializationService() => _instance;
  AppInitializationService._internal();

  static bool _isInitialized = false;
  static String? _initializationError;

  static bool get isInitialized => _isInitialized;
  static String? get initializationError => _initializationError;

  /// Initialize the app with Firebase and populate sample data
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize Firebase
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Initialize Firebase data population service
      final dataPopulator = FirebaseDataPopulatorService();

      // Check if database is empty and populate if needed
      await dataPopulator.initializeIfEmpty();

      _isInitialized = true;
      _initializationError = null;

      print('App initialization completed successfully');
    } catch (e) {
      _initializationError = e.toString();
      print('App initialization failed: $e');
      rethrow;
    }
  }

  /// Reset initialization state (for testing)
  static void reset() {
    _isInitialized = false;
    _initializationError = null;
  }

  /// Manually populate Firebase with sample data
  static Future<void> populateSampleData() async {
    try {
      final dataPopulator = FirebaseDataPopulatorService();
      await dataPopulator.populateFirebaseWithSampleData();
      print('Sample data populated successfully');
    } catch (e) {
      print('Failed to populate sample data: $e');
      rethrow;
    }
  }

  /// Clear all Firebase data
  static Future<void> clearAllData() async {
    try {
      final dataPopulator = FirebaseDataPopulatorService();
      await dataPopulator.clearAllData();
      print('All data cleared successfully');
    } catch (e) {
      print('Failed to clear data: $e');
      rethrow;
    }
  }

  /// Check if database has data
  static Future<bool> isDatabaseEmpty() async {
    try {
      final dataPopulator = FirebaseDataPopulatorService();
      return await dataPopulator.isDatabaseEmpty();
    } catch (e) {
      print('Failed to check database status: $e');
      return true;
    }
  }

  /// Print detailed current status to console/debug logs
  static Future<void> printCurrentStatus() async {
    try {
      final status = await getInitializationStatus();

      print('=== APP INITIALIZATION STATUS ===');
      print('🏁 First Run: ${status.isFirstRun}');
      print('📊 Data Populated Flag: ${status.dataPopulated}');
      print('💾 Has Firestore Data: ${status.hasData}');
      print('📈 Total Documents: ${status.totalDocuments}');
      print('🔢 App Version: ${status.currentVersion}');
      print('🔧 Initialization State: $_isInitialized');
      print('❌ Initialization Error: ${_initializationError ?? 'None'}');

      // Print collection-specific counts
      final firestore = FirebaseFirestore.instance;
      final collections = [
        'customers',
        'vehicles',
        'service_records',
        'appointments',
        'invoices',
        'inventory',
        'order_requests',
        'inventory_usage'
      ];

      print('\n📋 COLLECTION DETAILS:');
      for (final collection in collections) {
        try {
          final snapshot = await firestore.collection(collection).get();
          print('  $collection: ${snapshot.docs.length} documents');
        } catch (e) {
          print('  $collection: Error getting count - $e');
        }
      }
      print('================================');
    } catch (e) {
      print('Error printing status: $e');
    }
  }

  /// Get initialization status for UI display
  static Future<InitializationStatus> getInitializationStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isFirstRun = prefs.getBool('is_first_run') ?? true;
      final dataPopulated = prefs.getBool('data_populated') ?? false;

      // Check if database has data
      final hasData = !(await isDatabaseEmpty());

      // Count total documents across all collections
      int totalDocuments = 0;
      final firestore = FirebaseFirestore.instance;
      final collections = [
        'customers',
        'vehicles',
        'service_records',
        'appointments',
        'invoices',
        'inventory',
        'order_requests'
      ];

      for (final collection in collections) {
        try {
          final snapshot = await firestore.collection(collection).get();
          totalDocuments += snapshot.docs.length;
        } catch (e) {
          print('Error counting documents in $collection: $e');
        }
      }

      return InitializationStatus(
        isFirstRun: isFirstRun,
        dataPopulated: dataPopulated,
        hasData: hasData,
        totalDocuments: totalDocuments,
        currentVersion: '1.0.0', // You can make this dynamic if needed
      );
    } catch (e) {
      print('Error getting initialization status: $e');
      return InitializationStatus(
        isFirstRun: true,
        dataPopulated: false,
        hasData: false,
        totalDocuments: 0,
        currentVersion: '1.0.0',
      );
    }
  }

  /// Force data population for testing purposes
  static Future<void> forceDataPopulationForTesting() async {
    try {
      print('🔧 FORCE DATA POPULATION FOR TESTING STARTED');

      // Clear existing data first
      print('🗑️ Clearing existing data...');
      await clearAllData();

      // Populate with fresh sample data
      print('📊 Populating with fresh sample data...');
      await populateSampleData();

      // Mark as populated
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('data_populated', true);
      await prefs.setBool('is_first_run', false);

      print('✅ FORCE DATA POPULATION COMPLETED');

      // Print final status
      await printCurrentStatus();
    } catch (e) {
      print('❌ Error during force data population: $e');
      rethrow;
    }
  }

  /// Mark data as populated (used by admin services)
  static Future<void> markDataAsPopulated() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('data_populated', true);
      await prefs.setBool('is_first_run', false);
      print('✅ Data marked as populated');
    } catch (e) {
      print('❌ Error marking data as populated: $e');
    }
  }

  /// Fix inventory usage data to match inventory items
  static Future<void> fixInventoryUsageData() async {
    try {
      print('🔧 Fixing inventory usage data to match inventory items...');

      await InventoryUsageDataPopulator.forceRepopulateWithCorrectData(
        usageRecordCount: 25,
      );

      print('✅ Inventory usage data fixed successfully!');
    } catch (e) {
      print('❌ Error fixing inventory usage data: $e');
      rethrow;
    }
  }
}
