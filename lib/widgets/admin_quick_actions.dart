import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../services/admin_data_service.dart';
import '../services/app_initialization_service.dart';

/// Quick admin actions widget that can be embedded in other screens
/// Provides quick access to data management functions
class AdminQuickActions extends StatefulWidget {
  final bool showTitle;
  final bool compact;

  const AdminQuickActions({
    super.key,
    this.showTitle = true,
    this.compact = false,
  });

  @override
  State<AdminQuickActions> createState() => _AdminQuickActionsState();
}

class _AdminQuickActionsState extends State<AdminQuickActions> {
  final AdminDataService _adminService = AdminDataService();
  bool _isLoading = false;
  String _lastAction = '';

  Future<void> _quickPopulateData() async {
    setState(() {
      _isLoading = true;
      _lastAction = 'Populating data...';
    });

    try {
      final result = await _adminService.populateMalaysianSampleData(
        customerCount: 20,
        maxVehiclesPerCustomer: 2,
        maxServiceRecordsPerVehicle: 3,
        appointmentCount: 15,
        invoiceCount: 12,
        inventoryItemCount: 30,
        orderRequestCount: 8,
      );

      setState(() {
        _lastAction = result.success ? '✅ Data populated' : '❌ Failed';
      });

      if (result.success) {
        await AppInitializationService.markDataAsPopulated();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Malaysian sample data populated successfully!',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _lastAction = '❌ Error: ${e.toString().substring(0, 30)}...';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _quickDataCheck() async {
    setState(() {
      _isLoading = true;
      _lastAction = 'Checking data...';
    });

    try {
      final stats = await _adminService.getDataStatistics();
      final totalDocs = stats['totalDocuments'] ?? 0;
      
      setState(() {
        _lastAction = '📊 $totalDocs documents';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Total documents in database: $totalDocs',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppColors.primaryPink,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _lastAction = '❌ Check failed';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compact) {
      return _buildCompactView();
    } else {
      return _buildFullView();
    }
  }

  Widget _buildCompactView() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.admin_panel_settings,
            color: AppColors.primaryPink,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Admin Actions',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textDark,
              ),
            ),
          ),
          if (_isLoading)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else ...[
            _buildQuickButton(
              icon: Icons.add_circle_outline,
              onTap: _quickPopulateData,
              tooltip: 'Populate Data',
            ),
            const SizedBox(width: 8),
            _buildQuickButton(
              icon: Icons.info_outline,
              onTap: _quickDataCheck,
              tooltip: 'Check Data',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFullView() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showTitle) ...[
            Row(
              children: [
                Icon(
                  Icons.admin_panel_settings,
                  color: AppColors.primaryPink,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Admin Quick Actions',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  icon: Icons.add_circle,
                  title: 'Populate',
                  subtitle: 'Add sample data',
                  color: Colors.green,
                  onTap: _isLoading ? null : _quickPopulateData,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  icon: Icons.info,
                  title: 'Check',
                  subtitle: 'View statistics',
                  color: Colors.blue,
                  onTap: _isLoading ? null : _quickDataCheck,
                ),
              ),
            ],
          ),
          
          if (_lastAction.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _lastAction,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          
          if (_isLoading) ...[
            const SizedBox(height: 12),
            const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickButton({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.all(4),
          child: Icon(
            icon,
            size: 16,
            color: AppColors.primaryPink,
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: color.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: color,
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
