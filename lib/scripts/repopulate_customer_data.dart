import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';
import '../data/firebase_data_populator.dart';

/// Script to re-populate customer data with correct service history
/// Run this to fix the visit count issue by ensuring customers have their service history populated
Future<void> main() async {
  try {
    debugPrint('🚀 Starting customer data re-population script...');

    // Initialize Firebase
    debugPrint('🔧 Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Re-populate customer data with correct service history
    await FirebaseDataPopulator.repopulateCustomerData(customerCount: 30);

    debugPrint('✅ Customer data re-population completed successfully!');
    debugPrint(
        '🎯 Customers should now show correct visit counts based on their service history.');
  } catch (e, stackTrace) {
    debugPrint('❌ Error during customer data re-population: $e');
    debugPrint('📋 Stack trace: $stackTrace');
  }
}
