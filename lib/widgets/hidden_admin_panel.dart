import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../services/admin_data_service.dart';
import '../services/app_initialization_service.dart';
import '../utils/inventory_migration.dart';

/// Hidden admin panel for data management operations
/// Accessible only through secret gesture sequence
class HiddenAdminPanel extends StatefulWidget {
  const HiddenAdminPanel({super.key});

  @override
  State<HiddenAdminPanel> createState() => _HiddenAdminPanelState();
}

class _HiddenAdminPanelState extends State<HiddenAdminPanel> {
  final AdminDataService _adminService = AdminDataService();
  bool _isLoading = false;
  String _statusMessage = '';
  Map<String, dynamic>? _dataStats;
  bool _showConfirmClear = false;

  @override
  void initState() {
    super.initState();
    _loadDataStatistics();
  }

  Future<void> _loadDataStatistics() async {
    try {
      final stats = await _adminService.getDataStatistics();
      setState(() {
        _dataStats = stats;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error loading statistics: $e';
      });
    }
  }

  Future<void> _populateData() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Populating Malaysian sample data...';
    });

    try {
      final result = await _adminService.populateMalaysianSampleData();

      setState(() {
        _statusMessage =
            result.success ? '✅ ${result.message}' : '❌ ${result.message}';
      });

      if (result.success) {
        await _loadDataStatistics();
      }
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Error: $e';
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
      _statusMessage = 'Clearing all data...';
      _showConfirmClear = false;
    });

    try {
      final result = await _adminService.clearAllData();

      setState(() {
        _statusMessage =
            result.success ? '✅ ${result.message}' : '❌ ${result.message}';
      });

      if (result.success) {
        await _loadDataStatistics();
      }
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _validateConnection() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Validating Firebase connection...';
    });

    try {
      final result = await _adminService.validateFirebaseConnection();

      setState(() {
        _statusMessage =
            result.success ? '✅ ${result.message}' : '❌ ${result.message}';
      });
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _checkInitializationStatus() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Checking app initialization status...';
    });

    try {
      // Print detailed status to console/debug logs
      await AppInitializationService.printCurrentStatus();

      // Get status for UI display
      final status = await AppInitializationService.getInitializationStatus();

      final statusText = '''📋 Initialization Status:
🏁 First Run: ${status.isFirstRun}
📊 Data Populated Flag: ${status.dataPopulated}
💾 Has Firestore Data: ${status.hasData}
📈 Total Documents: ${status.totalDocuments}
🔢 App Version: ${status.currentVersion}''';

      setState(() {
        _statusMessage =
            '✅ $statusText\n\n💡 Check console/debug logs for detailed breakdown';
      });
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Error checking status: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _forceDataPopulation() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Forcing data population for testing...';
    });

    try {
      await AppInitializationService.forceDataPopulationForTesting();
      await _loadDataStatistics(); // Refresh stats

      setState(() {
        _statusMessage =
            '✅ Force data population completed! Check console logs for details.';
      });
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Error during force population: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _migrateInventoryRecords() async {
    setState(() {
      _isLoading = true;
      _statusMessage = '🔄 Migrating inventory records...';
    });

    try {
      // Check if migration is needed first
      final migrationStatus = await InventoryMigration.getMigrationStatus();

      if (migrationStatus.containsKey('error')) {
        setState(() {
          _statusMessage = '❌ Error checking migration status: ${migrationStatus['error']}';
        });
        return;
      }

      final totalItems = migrationStatus['totalItems'] ?? 0;
      final migrationNeeded = migrationStatus['migrationNeeded'] ?? false;

      if (!migrationNeeded) {
        setState(() {
          _statusMessage = '✅ No migration needed. All $totalItems inventory items already have correct orderRequestStatus values.';
        });
        return;
      }

      // Run the migration
      await InventoryMigration.runMigration();

      // Get updated status
      final updatedStatus = await InventoryMigration.getMigrationStatus();
      final itemsWithPendingStatus = updatedStatus['itemsWithPendingStatus'] ?? 0;
      final itemsWithNullStatus = updatedStatus['itemsWithNullStatus'] ?? 0;

      setState(() {
        _statusMessage = '''✅ Inventory migration completed successfully!

📊 Results:
• Total items: $totalItems
• Items with pending status: $itemsWithPendingStatus
• Items with null status: $itemsWithNullStatus

💡 All inventory items now have proper orderRequestStatus values.''';
      });
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Error migrating inventory records: $e';
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
        title: Text(
          '🔧 Admin Data Management',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.primaryPink,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Warning Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                border: Border.all(color: Colors.orange),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Admin Panel - Use with caution!\nThis panel can modify Firebase data.',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Data Statistics Card
            if (_dataStats != null) ...[
              _buildStatsCard(),
              const SizedBox(height: 24),
            ],

            // Action Buttons
            _buildActionButton(
              icon: Icons.add_circle,
              title: 'Populate Malaysian Sample Data',
              subtitle:
                  'Add 30 customers, 60+ vehicles, 200+ service records, etc.',
              color: Colors.green,
              onPressed: _isLoading ? null : _populateData,
            ),

            const SizedBox(height: 16),

            _buildActionButton(
              icon: Icons.refresh,
              title: 'Refresh Statistics',
              subtitle: 'Reload current data statistics',
              color: Colors.blue,
              onPressed: _isLoading ? null : _loadDataStatistics,
            ),

            const SizedBox(height: 16),

            _buildActionButton(
              icon: Icons.wifi,
              title: 'Validate Firebase Connection',
              subtitle: 'Test connection and permissions',
              color: Colors.purple,
              onPressed: _isLoading ? null : _validateConnection,
            ),

            const SizedBox(height: 16),

            _buildActionButton(
              icon: Icons.info_outline,
              title: 'Check App Initialization Status',
              subtitle: 'Debug data population and app initialization flags',
              color: Colors.orange,
              onPressed: _isLoading ? null : _checkInitializationStatus,
            ),

            const SizedBox(height: 16),

            _buildActionButton(
              icon: Icons.bug_report,
              title: 'Force Data Population (Testing)',
              subtitle: 'Reset flags and force data population for testing',
              color: Colors.teal,
              onPressed: _isLoading ? null : _forceDataPopulation,
            ),

            const SizedBox(height: 16),

            _buildActionButton(
              icon: Icons.upgrade,
              title: 'Migrate Inventory Records',
              subtitle: 'Add orderRequestStatus field to existing inventory items',
              color: Colors.indigo,
              onPressed: _isLoading ? null : _migrateInventoryRecords,
            ),

            const SizedBox(height: 16),

            // Clear Data Button (with confirmation)
            if (!_showConfirmClear)
              _buildActionButton(
                icon: Icons.delete_forever,
                title: 'Clear All Data',
                subtitle: 'Remove all data from Firebase (DANGEROUS)',
                color: Colors.red,
                onPressed: _isLoading
                    ? null
                    : () {
                        setState(() {
                          _showConfirmClear = true;
                        });
                      },
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      '⚠️ CONFIRM DATA DELETION',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This will permanently delete ALL data from Firebase.\nThis action cannot be undone!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.red.shade600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _showConfirmClear = false;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                              foregroundColor: Colors.white,
                            ),
                            child: Text('Cancel', style: GoogleFonts.poppins()),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _clearData,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            child: Text('DELETE ALL',
                                style: GoogleFonts.poppins()),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // Status Message
            if (_statusMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _statusMessage.startsWith('✅')
                      ? Colors.green.shade50
                      : Colors.red.shade50,
                  border: Border.all(
                    color: _statusMessage.startsWith('✅')
                        ? Colors.green
                        : Colors.red,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _statusMessage,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: _statusMessage.startsWith('✅')
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                  ),
                ),
              ),

            // Loading Indicator
            if (_isLoading) ...[
              const SizedBox(height: 24),
              const Center(
                child: CircularProgressIndicator(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📊 Current Data Statistics',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 16),
          if (_dataStats!.containsKey('totalDocuments'))
            _buildStatRow(
                'Total Documents', _dataStats!['totalDocuments'].toString()),
          if (_dataStats!.containsKey('customers'))
            _buildStatRow(
                'Customers', _dataStats!['customers']['count'].toString()),
          if (_dataStats!.containsKey('vehicles'))
            _buildStatRow(
                'Vehicles', _dataStats!['vehicles']['count'].toString()),
          if (_dataStats!.containsKey('service_records'))
            _buildStatRow('Service Records',
                _dataStats!['service_records']['count'].toString()),
          if (_dataStats!.containsKey('appointments'))
            _buildStatRow('Appointments',
                _dataStats!['appointments']['count'].toString()),
          if (_dataStats!.containsKey('invoices'))
            _buildStatRow(
                'Invoices', _dataStats!['invoices']['count'].toString()),
          if (_dataStats!.containsKey('inventory'))
            _buildStatRow('Inventory Items',
                _dataStats!['inventory']['count'].toString()),
          if (_dataStats!.containsKey('order_requests'))
            _buildStatRow('Order Requests',
                _dataStats!['order_requests']['count'].toString()),
          if (_dataStats!.containsKey('timestamp'))
            _buildStatRow('Last Updated',
                _dataStats!['timestamp'].toString().split('T')[0]),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onPressed == null)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(
                    Icons.arrow_forward_ios,
                    color: AppColors.textSecondary,
                    size: 16,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
