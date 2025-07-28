import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../models/inventory_usage.dart';
import '../services/inventory_usage_service.dart';
import '../widgets/dashboard_card.dart';

class InventoryAnalyticsScreen extends StatefulWidget {
  const InventoryAnalyticsScreen({super.key});

  @override
  State<InventoryAnalyticsScreen> createState() => _InventoryAnalyticsScreenState();
}

class _InventoryAnalyticsScreenState extends State<InventoryAnalyticsScreen> {
  final InventoryUsageService _usageService = InventoryUsageService();
  
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  UsageSummary? _summary;
  List<UsageAnalytics> _itemAnalytics = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  void _loadAnalytics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get usage summary for the period
      final summary = await _usageService.getUsageSummary(
        startDate: _startDate,
        endDate: _endDate,
      );

      setState(() {
        _summary = summary;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading analytics: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryPink,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadAnalytics();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGray,
      appBar: AppBar(
        title: Text(
          'Inventory Analytics',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primaryPink,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDateRangeCard(),
                  const SizedBox(height: 16),
                  _buildSummaryCards(),
                  const SizedBox(height: 24),
                  _buildCategoryBreakdown(),
                  const SizedBox(height: 24),
                  _buildUsageTypeBreakdown(),
                  const SizedBox(height: 24),
                  _buildTopUsedItems(),
                  const SizedBox(height: 24),
                  _buildTopEmployees(),
                ],
              ),
            ),
    );
  }

  Widget _buildDateRangeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today, color: AppColors.primaryPink),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analysis Period',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${DateFormat('MMM d, y').format(_startDate)} - ${DateFormat('MMM d, y').format(_endDate)}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _selectDateRange,
            child: Text(
              'Change',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryPink,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    if (_summary == null) return const SizedBox.shrink();

    return Column(
      children: [
        // First row
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Total Records',
                _summary!.totalUsageRecords.toString(),
                Icons.receipt_long,
                AppColors.primaryPink,
                '',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSummaryCard(
                'Total Cost',
                'RM${_summary!.totalCost.toStringAsFixed(2)}',
                Icons.attach_money,
                AppColors.successGreen,
                '',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Second row
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Items Used',
                _summary!.totalQuantityUsed.toString(),
                Icons.inventory,
                AppColors.warningOrange,
                '',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSummaryCard(
                'Avg/Record',
                'RM${_summary!.averageCostPerRecord.toStringAsFixed(2)}',
                Icons.trending_up,
                AppColors.errorRed,
                '',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color, String subtitle) {
    return Container(
      height: 100,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Header with icon and title
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          // Value
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown() {
    if (_summary == null || _summary!.usageByCategory.isEmpty) {
      return const SizedBox.shrink();
    }

    return DashboardCard(
      title: 'Usage by Category',
      child: Column(
        children: _summary!.usageByCategory.entries.map((entry) {
          final percentage = (_summary!.totalQuantityUsed > 0)
              ? (entry.value / _summary!.totalQuantityUsed * 100)
              : 0.0;
          
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    entry.key,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: AppColors.lightGray,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryPink),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${entry.value} (${percentage.toStringAsFixed(1)}%)',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildUsageTypeBreakdown() {
    if (_summary == null || _summary!.usageByType.isEmpty) {
      return const SizedBox.shrink();
    }

    return DashboardCard(
      title: 'Usage by Type',
      child: Column(
        children: _summary!.usageByType.entries.map((entry) {
          final percentage = (_summary!.totalUsageRecords > 0)
              ? (entry.value / _summary!.totalUsageRecords * 100)
              : 0.0;
          
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    entry.key.name.toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: AppColors.lightGray,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.successGreen),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${entry.value} (${percentage.toStringAsFixed(1)}%)',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTopUsedItems() {
    if (_itemAnalytics.isEmpty) return const SizedBox.shrink();

    final topItems = _itemAnalytics.take(5).toList();

    return DashboardCard(
      title: 'Top Used Items',
      child: Column(
        children: topItems.asMap().entries.map((entry) {
          final index = entry.key;
          final analytics = entry.value;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.lightGray,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.primaryPink,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        analytics.itemName,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${analytics.category} • ${analytics.usageCount} uses',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${analytics.totalQuantityUsed}',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryPink,
                      ),
                    ),
                    Text(
                      'RM${analytics.totalCost.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTopEmployees() {
    if (_summary == null || _summary!.mostActiveEmployees.isEmpty) {
      return const SizedBox.shrink();
    }

    return DashboardCard(
      title: 'Most Active Employees',
      child: Column(
        children: _summary!.mostActiveEmployees.asMap().entries.map((entry) {
          final index = entry.key;
          final employeeName = entry.value;
          final usageCount = _summary!.usageByEmployee[employeeName] ?? 0;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.lightGray,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.successGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    employeeName,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  '$usageCount items',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.successGreen,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
