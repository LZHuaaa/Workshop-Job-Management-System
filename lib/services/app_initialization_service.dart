import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'admin_data_service.dart';

/// Service for handling app initialization and optional data population
/// This service can automatically populate sample data on first run or when requested
class AppInitializationService {
  static final AppInitializationService _instance =
      AppInitializationService._internal();
  factory AppInitializationService() => _instance;
  AppInitializationService._internal();

  static const String _keyDataPopulated = 'sample_data_populated';
  static const String _keyAppVersion = 'app_version';
  static const String _currentVersion = '1.0.0';

  /// Initialize the app and optionally populate sample data
  /// This method should be called during app startup
  static Future<void> initializeApp({
    bool autoPopulateOnFirstRun = false,
    bool forceRepopulate = false,
  }) async {
    try {
      debugPrint('🚀 App: Starting initialization...');

      final prefs = await SharedPreferences.getInstance();
      final isFirstRun = !prefs.containsKey(_keyAppVersion);
      final dataPopulated = prefs.getBool(_keyDataPopulated) ?? false;
      final storedVersion = prefs.getString(_keyAppVersion) ?? '0.0.0';

      debugPrint('📱 App: First run: $isFirstRun');
      debugPrint('📊 App: Data populated: $dataPopulated');
      debugPrint(
          '🔢 App: Stored version: $storedVersion, Current: $_currentVersion');

      // Check if we should populate data
      bool shouldPopulateData = false;

      if (forceRepopulate) {
        debugPrint('🔄 App: Force repopulate requested');
        shouldPopulateData = true;
      } else if (autoPopulateOnFirstRun && isFirstRun) {
        debugPrint('🆕 App: First run auto-populate enabled');
        shouldPopulateData = true;
      } else if (autoPopulateOnFirstRun && !dataPopulated) {
        debugPrint('📊 App: Data not populated, auto-populate enabled');
        shouldPopulateData = true;
      }

      // Populate data if needed
      if (shouldPopulateData) {
        await _populateInitialData();
        await prefs.setBool(_keyDataPopulated, true);
      }

      // Update version info
      await prefs.setString(_keyAppVersion, _currentVersion);

      debugPrint('✅ App: Initialization completed successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ App: Initialization failed: $e');
      debugPrint('📍 App: Stack trace: $stackTrace');
      // Don't rethrow - app should continue even if initialization fails
    }
  }

  /// Populate initial sample data
  static Future<void> _populateInitialData() async {
    try {
      debugPrint('📊 App: Starting initial data population...');

      final adminService = AdminDataService();

      // Check if data already exists
      final stats = await adminService.getDataStatistics();
      final totalDocs = stats['totalDocuments'] ?? 0;

      debugPrint('🔍 App: Current Firestore document count: $totalDocs');

      if (totalDocs > 0) {
        debugPrint(
            '⚠️ App: Data already exists ($totalDocs documents), skipping population');
        debugPrint('📋 App: Existing data breakdown: ${stats.toString()}');
        return;
      }

      debugPrint('🚀 App: No existing data found, starting population...');

      // Populate with a smaller dataset for automatic initialization
      final result = await adminService.populateMalaysianSampleData(
        customerCount: 15, // Smaller dataset for auto-population
        maxVehiclesPerCustomer: 2,
        maxServiceRecordsPerVehicle: 3,
        appointmentCount: 10,
        invoiceCount: 8,
        inventoryItemCount: 25,
        orderRequestCount: 5,
      );

      if (result.success) {
        debugPrint('✅ App: Initial data population completed successfully');
        debugPrint('📊 App: Population result: ${result.message}');
        debugPrint('📋 App: Final data stats: ${result.details.toString()}');
      } else {
        debugPrint('❌ App: Initial data population failed: ${result.message}');
        debugPrint('🔍 App: Error details: ${result.error}');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ App: Error during initial data population: $e');
      debugPrint('📍 App: Stack trace: $stackTrace');
    }
  }

  /// Check if sample data has been populated
  static Future<bool> isDataPopulated() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyDataPopulated) ?? false;
    } catch (e) {
      debugPrint('⚠️ App: Error checking data population status: $e');
      return false;
    }
  }

  /// Mark data as populated (useful after manual population)
  static Future<void> markDataAsPopulated() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyDataPopulated, true);
      debugPrint('✅ App: Data marked as populated');
    } catch (e) {
      debugPrint('⚠️ App: Error marking data as populated: $e');
    }
  }

  /// Reset data population flag (useful for testing)
  static Future<void> resetDataPopulationFlag() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyDataPopulated, false);
      debugPrint('🔄 App: Data population flag reset');
    } catch (e) {
      debugPrint('⚠️ App: Error resetting data population flag: $e');
    }
  }

  /// Get app initialization status
  static Future<AppInitializationStatus> getInitializationStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isFirstRun = !prefs.containsKey(_keyAppVersion);
      final dataPopulated = prefs.getBool(_keyDataPopulated) ?? false;
      final storedVersion = prefs.getString(_keyAppVersion) ?? '0.0.0';

      // Get current data statistics
      final adminService = AdminDataService();
      final stats = await adminService.getDataStatistics();

      return AppInitializationStatus(
        isFirstRun: isFirstRun,
        dataPopulated: dataPopulated,
        storedVersion: storedVersion,
        currentVersion: _currentVersion,
        dataStatistics: stats,
      );
    } catch (e) {
      debugPrint('⚠️ App: Error getting initialization status: $e');
      return AppInitializationStatus(
        isFirstRun: true,
        dataPopulated: false,
        storedVersion: '0.0.0',
        currentVersion: _currentVersion,
        dataStatistics: {'error': e.toString()},
      );
    }
  }

  /// Validate that the app is properly initialized
  static Future<bool> validateInitialization() async {
    try {
      debugPrint('🔍 App: Validating initialization...');

      // Check Firebase connection
      final adminService = AdminDataService();
      final connectionResult = await adminService.validateFirebaseConnection();

      if (!connectionResult.success) {
        debugPrint('❌ App: Firebase connection validation failed');
        return false;
      }

      // Check if basic app data is accessible
      final stats = await adminService.getDataStatistics();
      if (stats.containsKey('error')) {
        debugPrint('❌ App: Data statistics check failed');
        return false;
      }

      debugPrint('✅ App: Initialization validation passed');
      return true;
    } catch (e) {
      debugPrint('❌ App: Initialization validation failed: $e');
      return false;
    }
  }

  /// Debug method to print current initialization and data status
  /// Call this from anywhere in your app to check the current state
  static Future<void> printCurrentStatus() async {
    try {
      debugPrint('📋 ===== APP INITIALIZATION STATUS =====');

      final status = await getInitializationStatus();
      debugPrint('🏁 First Run: ${status.isFirstRun}');
      debugPrint(
          '📊 Data Populated (SharedPreferences): ${status.dataPopulated}');
      debugPrint('🔢 Stored Version: ${status.storedVersion}');
      debugPrint('🆕 Current Version: ${status.currentVersion}');
      debugPrint('📈 Total Documents in Firestore: ${status.totalDocuments}');
      debugPrint('💾 Has Data in Firestore: ${status.hasData}');

      debugPrint('📊 Detailed Collection Stats:');
      status.dataStatistics.forEach((key, value) {
        if (key != 'totalDocuments' && key != 'timestamp') {
          debugPrint('   - $key: $value');
        }
      });

      debugPrint('📋 ===== END STATUS =====');
    } catch (e) {
      debugPrint('❌ App: Error printing status: $e');
    }
  }

  /// Force data population for testing purposes
  /// This will reset the data population flag and populate data again
  static Future<void> forceDataPopulationForTesting() async {
    try {
      debugPrint('🔄 App: Forcing data population for testing...');

      // Reset the flag
      await resetDataPopulationFlag();

      // Force populate
      await initializeApp(
        autoPopulateOnFirstRun: true,
        forceRepopulate: true,
      );

      // Print status
      await printCurrentStatus();
    } catch (e) {
      debugPrint('❌ App: Error during forced population: $e');
    }
  }
}

/// Status class for app initialization
class AppInitializationStatus {
  final bool isFirstRun;
  final bool dataPopulated;
  final String storedVersion;
  final String currentVersion;
  final Map<String, dynamic> dataStatistics;

  AppInitializationStatus({
    required this.isFirstRun,
    required this.dataPopulated,
    required this.storedVersion,
    required this.currentVersion,
    required this.dataStatistics,
  });

  bool get isVersionUpgrade => storedVersion != currentVersion;
  int get totalDocuments => dataStatistics['totalDocuments'] ?? 0;
  bool get hasData => totalDocuments > 0;

  @override
  String toString() {
    return 'AppInitializationStatus('
        'isFirstRun: $isFirstRun, '
        'dataPopulated: $dataPopulated, '
        'storedVersion: $storedVersion, '
        'currentVersion: $currentVersion, '
        'totalDocuments: $totalDocuments'
        ')';
  }
}
