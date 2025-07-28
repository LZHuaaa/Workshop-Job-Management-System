import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../models/inventory_usage.dart';
import '../services/inventory_usage_service.dart';
import '../services/inventory_service.dart';


import 'inventory_analytics_screen.dart';

class InventoryUsageScreen extends StatefulWidget {
  const InventoryUsageScreen({super.key});

  @override
  State<InventoryUsageScreen> createState() => _InventoryUsageScreenState();
}

class _InventoryUsageScreenState extends State<InventoryUsageScreen> {
  final InventoryUsageService _usageService = InventoryUsageService();
  final InventoryService _inventoryService = InventoryService();
  final TextEditingController _searchController = TextEditingController();

  String _selectedCategory = 'All';
  UsageType? _selectedUsageType;
  UsageStatus? _selectedStatus;
  String _selectedEmployee = 'All';
  DateTime? _startDate;
  DateTime? _endDate;
  String _sortBy = 'Date';
  bool _sortAscending = false;

  List<String> _categories = ['All'];

  List<String> _employees = ['All'];

  final List<String> _sortOptions = [
    'Date', 'Item Name', 'Quantity', 'Cost'
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadCategories();
    _loadEmployees();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _loadCategories() async {
    try {
      final categories = await _inventoryService.getCategories();
      setState(() {
        _categories = categories;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading categories: $e', style: GoogleFonts.poppins()),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  void _loadEmployees() async {
    try {
      final employees = await _usageService.getEmployees();
      setState(() {
        _employees = employees;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading employees: $e', style: GoogleFonts.poppins()),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  void _onSearchChanged() {
    setState(() {
      // Trigger rebuild to update filtered stream
    });
  }

  Stream<List<InventoryUsage>> get _filteredUsageStream {
    return _usageService.getUsageRecords(
      category: _selectedCategory != 'All' ? _selectedCategory : null,
      usageType: _selectedUsageType,
      status: _selectedStatus,
      usedBy: _selectedEmployee != 'All' ? _selectedEmployee : null,
      startDate: _startDate,
      endDate: _endDate,
      searchQuery: _searchController.text,
      sortBy: _sortBy,
      sortAscending: _sortAscending,
    );
  }



  void _verifyUsage(InventoryUsage usage) async {
    try {
      await _usageService.verifyUsage(usage.id, 'Manager');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Usage verified successfully', style: GoogleFonts.poppins()),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error verifying usage: $e', style: GoogleFonts.poppins()),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  void _disputeUsage(InventoryUsage usage) {
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Dispute Usage Record',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Please provide a reason for disputing this usage record:',
                style: GoogleFonts.poppins(fontSize: 14),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.lightGray,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      usage.itemName,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Quantity: ${usage.quantityUsed} • Cost: RM${usage.totalCost.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      'Used by: ${usage.usedBy}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Dispute Reason *',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Explain why you are disputing this record...',
                  hintStyle: GoogleFonts.poppins(color: AppColors.textSecondary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.primaryPink),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'This will mark the record as disputed and require investigation.',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.warningOrange,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Please provide a reason for the dispute', style: GoogleFonts.poppins()),
                    backgroundColor: AppColors.errorRed,
                  ),
                );
                return;
              }
              Navigator.of(context).pop();
              _performDispute(usage, reasonController.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warningOrange,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Dispute',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _performDispute(InventoryUsage usage, String reason) async {
    try {
      await _usageService.disputeUsage(usage.id, 'Manager', reason);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Usage record disputed successfully', style: GoogleFonts.poppins()),
            backgroundColor: AppColors.warningOrange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error disputing usage: $e', style: GoogleFonts.poppins()),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  void _undisputeUsage(InventoryUsage usage) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Undispute Usage Record',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to undispute this usage record?',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.lightGray,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    usage.itemName,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Quantity: ${usage.quantityUsed} • Cost: RM${usage.totalCost.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    'Used by: ${usage.usedBy}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This will change the status back to "Recorded" for verification.',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.primaryPink,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performUndispute(usage);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPink,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Undispute',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _performUndispute(InventoryUsage usage) async {
    try {
      await _usageService.undisputeUsage(usage.id, 'Manager');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Usage record undisputed successfully', style: GoogleFonts.poppins()),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error undisputing usage: $e', style: GoogleFonts.poppins()),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  void _deleteUsage(InventoryUsage usage) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Usage Record',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete this usage record?',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.lightGray,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    usage.itemName,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Quantity: ${usage.quantityUsed} • Cost: RM${usage.totalCost.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    'Used by: ${usage.usedBy}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This action cannot be undone.',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.errorRed,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performDelete(usage);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _performDelete(InventoryUsage usage) async {
    try {
      await _usageService.deleteUsage(usage.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Usage record deleted successfully', style: GoogleFonts.poppins()),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting usage: $e', style: GoogleFonts.poppins()),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  void _showStatusInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Usage Status Meanings',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusExplanation(
              'Recorded',
              'Initial status when usage is first logged. Requires manager verification.',
              AppColors.warningOrange,
              Icons.pending,
            ),
            const SizedBox(height: 16),
            _buildStatusExplanation(
              'Verified',
              'Manager has confirmed the usage is accurate and approved.',
              AppColors.successGreen,
              Icons.verified,
            ),
            const SizedBox(height: 16),
            _buildStatusExplanation(
              'Disputed',
              'Usage record is questioned and under review. Dispute reason is included in notes.',
              AppColors.errorRed,
              Icons.error,
            ),
            const SizedBox(height: 16),
            _buildStatusExplanation(
              'Cancelled',
              'Usage record has been cancelled or voided.',
              AppColors.textSecondary,
              Icons.cancel,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Got it',
              style: GoogleFonts.poppins(
                color: AppColors.primaryPink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusExplanation(String status, String description, Color color, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                status,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGray,
      appBar: AppBar(
        title: Text(
          'Usage Management',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primaryPink,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: _showStatusInfo,
            tooltip: 'Status Info',
          ),
          IconButton(
            icon: const Icon(Icons.analytics, color: Colors.white),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const InventoryAnalyticsScreen(),
                ),
              );
            },
            tooltip: 'View Analytics',
          ),
        ],
      ),
      body: StreamBuilder<List<InventoryUsage>>(
        stream: _filteredUsageStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.errorRed,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading usage records',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final usageRecords = snapshot.data ?? [];

          return Column(
            children: [
              _buildSummaryCards(usageRecords),
              _buildFiltersSection(),
              Expanded(
                child: _buildUsageList(usageRecords),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCards(List<InventoryUsage> usageRecords) {
    final totalRecords = usageRecords.length;
    final totalCost = usageRecords.fold<double>(
        0, (sum, usage) => sum + usage.totalCost);
    final totalQuantity = usageRecords.fold<int>(
        0, (sum, usage) => sum + usage.quantityUsed);
    final unverifiedCount = usageRecords
        .where((usage) => usage.status == UsageStatus.recorded).length;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // First row
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Total Records',
                  totalRecords.toString(),
                  Icons.receipt_long,
                  AppColors.primaryPink,
                  '',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'Total Cost',
                  'RM${totalCost.toStringAsFixed(2)}',
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
                  totalQuantity.toString(),
                  Icons.inventory,
                  AppColors.warningOrange,
                  '',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'Unverified',
                  unverifiedCount.toString(),
                  Icons.pending,
                  AppColors.errorRed,
                  '',
                ),
              ),
            ],
          ),
        ],
      ),
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

  Widget _buildFiltersSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by item, employee, customer, or purpose...',
              hintStyle: GoogleFonts.poppins(color: AppColors.textSecondary),
              prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.lightGray),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.primaryPink),
              ),
            ),
            onChanged: (_) {}, // Stream will automatically update
          ),
          const SizedBox(height: 12),
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Category', _selectedCategory, _categories, (value) {
                  setState(() => _selectedCategory = value);
                }),
                const SizedBox(width: 8),
                _buildFilterChip('Employee', _selectedEmployee, _employees, (value) {
                  setState(() => _selectedEmployee = value);
                }),
                const SizedBox(width: 8),
                _buildFilterChip('Sort', _sortBy, _sortOptions, (value) {
                  setState(() => _sortBy = value);
                }),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                    color: AppColors.primaryPink,
                  ),
                  onPressed: () {
                    setState(() => _sortAscending = !_sortAscending);
                  },
                  tooltip: _sortAscending ? 'Sort Ascending' : 'Sort Descending',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, List<String> options, Function(String) onChanged) {
    return PopupMenuButton<String>(
      child: Chip(
        label: Text(
          '$label: $value',
          style: GoogleFonts.poppins(fontSize: 12),
        ),
        backgroundColor: AppColors.lightGray,
      ),
      itemBuilder: (context) => options.map((option) => PopupMenuItem(
        value: option,
        child: Text(option, style: GoogleFonts.poppins()),
      )).toList(),
      onSelected: onChanged,
    );
  }

  Widget _buildUsageList(List<InventoryUsage> usageRecords) {
    if (usageRecords.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No usage records found',
              style: GoogleFonts.poppins(
                fontSize: 18,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters or check back later',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: usageRecords.length,
      itemBuilder: (context, index) {
        final usage = usageRecords[index];
        return _buildUsageCard(usage);
      },
    );
  }

  Widget _buildUsageCard(InventoryUsage usage) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        usage.itemName,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${usage.itemCategory} • ${usage.usageTypeText}',
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(usage.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        usage.statusText,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(usage.status),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMM d, HH:mm').format(usage.usageDate),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'Quantity',
                    '${usage.quantityUsed}',
                    Icons.inventory,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Cost',
                    'RM${usage.totalCost.toStringAsFixed(2)}',
                    Icons.attach_money,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Used By',
                    usage.usedBy,
                    Icons.person,
                  ),
                ),
              ],
            ),
            if (usage.customerName != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      'Customer',
                      usage.customerName!,
                      Icons.person_outline,
                    ),
                  ),
                  if (usage.vehiclePlate != null)
                    Expanded(
                      child: _buildInfoItem(
                        'Vehicle',
                        usage.vehiclePlate!,
                        Icons.directions_car,
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Purpose: ${usage.purpose}',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
            if (usage.notes != null && usage.notes!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Notes: ${usage.notes}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Delete button (always available for managers)
                TextButton.icon(
                  onPressed: () => _deleteUsage(usage),
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: Text(
                    'Delete',
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.errorRed,
                  ),
                ),
                if (usage.status == UsageStatus.recorded) ...[
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _disputeUsage(usage),
                    icon: const Icon(Icons.error_outline, size: 16),
                    label: Text(
                      'Dispute',
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.warningOrange,
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _verifyUsage(usage),
                    icon: const Icon(Icons.verified, size: 16),
                    label: Text(
                      'Verify',
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.successGreen,
                    ),
                  ),
                ],
                if (usage.status == UsageStatus.disputed) ...[
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _undisputeUsage(usage),
                    icon: const Icon(Icons.undo, size: 16),
                    label: Text(
                      'Undispute',
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryPink,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(UsageStatus status) {
    switch (status) {
      case UsageStatus.recorded:
        return AppColors.warningOrange;
      case UsageStatus.verified:
        return AppColors.successGreen;
      case UsageStatus.disputed:
        return AppColors.errorRed;
      case UsageStatus.cancelled:
        return AppColors.textSecondary;
    }
  }
}
