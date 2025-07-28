import 'package:flutter/material.dart';
import 'firebase_data_populator.dart';

/// Simple utility widget to populate Firebase with sample data
/// This can be called from your app's admin panel or debug menu
class PopulateSampleDataWidget extends StatefulWidget {
  const PopulateSampleDataWidget({super.key});

  @override
  State<PopulateSampleDataWidget> createState() => _PopulateSampleDataWidgetState();
}

class _PopulateSampleDataWidgetState extends State<PopulateSampleDataWidget> {
  bool _isLoading = false;
  String _status = '';

  Future<void> _populateData() async {
    setState(() {
      _isLoading = true;
      _status = 'Starting data population...';
    });

    try {
      await FirebaseDataPopulator.populateAllData(
        customerCount: 30,
        maxVehiclesPerCustomer: 3,
        maxServiceRecordsPerVehicle: 5,
        appointmentCount: 25,
        invoiceCount: 20,
        inventoryItemCount: 50,
        orderRequestCount: 15,
      );

      setState(() {
        _status = '✅ Successfully populated Firebase with Malaysian sample data!';
      });
    } catch (e) {
      setState(() {
        _status = '❌ Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _clearData() async {
    setState(() {
      _isLoading = true;
      _status = 'Clearing all data...';
    });

    try {
      await FirebaseDataPopulator.clearAllData();
      setState(() {
        _status = '✅ Successfully cleared all data from Firebase!';
      });
    } catch (e) {
      setState(() {
        _status = '❌ Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sample Data Population'),
        backgroundColor: Colors.pink,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Firebase Data Population',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'This will populate your Firebase Firestore with comprehensive Malaysian automotive workshop sample data including:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              '• 30 Malaysian customers with authentic names and addresses\n'
              '• 60+ vehicles with Malaysian license plates and makes\n'
              '• 200+ service records with realistic pricing (RM)\n'
              '• 25 job appointments with various statuses\n'
              '• 20 invoices with proper Malaysian tax (SST)\n'
              '• 50 inventory items with Malaysian suppliers\n'
              '• 15 order requests for low-stock items',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _populateData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text('Populating...'),
                      ],
                    )
                  : const Text(
                      'Populate Sample Data',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _clearData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Clear All Data',
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 24),
            if (_status.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _status.startsWith('✅') ? Colors.green.shade50 : Colors.red.shade50,
                  border: Border.all(
                    color: _status.startsWith('✅') ? Colors.green : Colors.red,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _status,
                  style: TextStyle(
                    color: _status.startsWith('✅') ? Colors.green.shade800 : Colors.red.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            const Spacer(),
            const Text(
              'Note: This operation will add data to your Firebase project. '
              'Make sure you are connected to the correct Firebase project before proceeding.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Standalone function to populate data (can be called from anywhere)
Future<void> populateMalaysianSampleData() async {
  try {
    debugPrint('🚀 Starting Malaysian sample data population...');
    
    await FirebaseDataPopulator.populateAllData(
      customerCount: 30,
      maxVehiclesPerCustomer: 3,
      maxServiceRecordsPerVehicle: 5,
      appointmentCount: 25,
      invoiceCount: 20,
      inventoryItemCount: 50,
      orderRequestCount: 15,
    );
    
    debugPrint('🎉 Malaysian sample data population completed!');
  } catch (e) {
    debugPrint('❌ Error populating Malaysian sample data: $e');
    rethrow;
  }
}

/// Standalone function to clear all data (use with caution!)
Future<void> clearAllFirebaseData() async {
  try {
    debugPrint('🗑️ Starting data clearing...');
    await FirebaseDataPopulator.clearAllData();
    debugPrint('🎉 Data clearing completed!');
  } catch (e) {
    debugPrint('❌ Error clearing data: $e');
    rethrow;
  }
}
