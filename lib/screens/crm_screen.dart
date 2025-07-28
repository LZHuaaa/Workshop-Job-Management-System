import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_colors.dart';
import '../widgets/dashboard_card.dart';
import '../models/customer.dart';
import '../models/service_record.dart';
import '../screens/customer_profile_screen.dart';
import '../dialogs/add_customer_dialog.dart';
import '../dialogs/edit_customer_dialog.dart';
import '../services/crm_analytics_service.dart';
import '../services/customer_service.dart';

class CrmScreen extends StatefulWidget {
  const CrmScreen({super.key});

  @override
  State<CrmScreen> createState() => _CrmScreenState();
}

class _CrmScreenState extends State<CrmScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';

  final CustomerService _customerService = CustomerService();
  List<Customer> _allCustomers = [];
  bool _isLoading = true;
  String? _errorMessage;

  final List<String> _filterOptions = [
    'All',
    'VIP',
    'Recent',
    'Inactive',
  ];

  List<Customer> get _filteredCustomers {
    List<Customer> filtered = _allCustomers;

    // Apply filter
    switch (_selectedFilter) {
      case 'VIP':
        filtered = filtered.where((customer) => customer.isVip).toList();
        break;
      case 'Recent':
        filtered = filtered
            .where((customer) =>
                customer.lastVisit != null && customer.daysSinceLastVisit <= 30)
            .toList();
        break;
      case 'Inactive':
        filtered = filtered
            .where((customer) =>
                customer.lastVisit == null || customer.daysSinceLastVisit > 90)
            .toList();
        break;
    }

    // Apply search
    if (_searchController.text.isNotEmpty) {
      final searchTerm = _searchController.text.toLowerCase();
      filtered = filtered
          .where((customer) =>
              customer.fullName.toLowerCase().contains(searchTerm) ||
              customer.email.toLowerCase().contains(searchTerm) ||
              customer.phone.contains(searchTerm) ||
              (customer.address?.toLowerCase().contains(searchTerm) ?? false))
          .toList();
    }

    return filtered;
  }

  Future<void> _addCustomer(Customer customer) async {
    try {
    setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Customer is already created in the dialog, just reload the list
      await _loadCustomers(); // Reload customers from Firebase

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Customer added successfully!',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to add customer: ${e.toString()}',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _updateCustomer(Customer updatedCustomer) async {
    try {
    setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      await _customerService.updateCustomer(updatedCustomer);
      await _loadCustomers(); // Reload customers from Firebase

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Customer updated successfully!',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to update customer: ${e.toString()}',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _deleteCustomer(Customer customer) async {
    // Show confirmation dialog
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Customer',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to delete ${customer.fullName}? This action cannot be undone.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(color: AppColors.errorRed),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      try {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });

        await _customerService.deleteCustomer(customer.id);
        await _loadCustomers(); // Reload customers from Firebase

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Customer deleted successfully!',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: AppColors.successGreen,
            ),
          );
        }
      } catch (e) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to delete customer: ${e.toString()}',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: AppColors.errorRed,
            ),
          );
        }
      }
    }
  }

  Future<void> _loadCustomers() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final customers = await _customerService.getAllCustomers();

      setState(() {
        _allCustomers = customers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeRealtimeData();
    
    // Add listener to search controller for real-time search
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    // Trigger rebuild when search text changes for real-time filtering
    if (mounted) {
      setState(() {
        // The _getFilteredCustomers method will automatically filter based on search text
      });
    }
  }

  void _initializeRealtimeData() {
    // Use real-time listeners for live data updates
    _customerService.getCustomersStream().listen(
      (customers) {
        if (mounted) {
          setState(() {
            _allCustomers = customers;
            _isLoading = false;
            _errorMessage = null;
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _errorMessage = error.toString();
            _isLoading = false;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Customers',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showAddCustomerDialog(),
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(
                          'Add Customer',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryPink,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search customers by name, email, or phone...',
                        prefixIcon: Icon(
                          Icons.search,
                          color: AppColors.textSecondary,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  color: AppColors.textSecondary,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  _loadCustomers();
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Filter Chips
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _filterOptions.length,
                      itemBuilder: (context, index) {
                        final filter = _filterOptions[index];
                        final isSelected = filter == _selectedFilter;

                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(
                              filter,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedFilter = filter;
                              });
                            },
                            backgroundColor: Colors.white,
                            selectedColor: AppColors.primaryPink,
                            checkmarkColor: Colors.white,
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.primaryPink
                                  : AppColors.textSecondary
                                      .withValues(alpha: 0.3),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Tab Bar
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: AppColors.primaryPink,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primaryPink,
                labelStyle: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Communications'),
                  Tab(text: 'Analytics'),
                ],
              ),
            ),

            // Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildCustomersTab(),
                  _buildCommunicationsTab(),
                  _buildAnalyticsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomersTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
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
              'Error loading customers',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadCustomers,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPink,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Retry',
                style: GoogleFonts.poppins(),
              ),
            ),
          ],
        ),
      );
    }

    if (_filteredCustomers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No customers found',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchController.text.isNotEmpty
                  ? 'Try adjusting your search criteria'
                  : 'Add your first customer to get started',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _showAddCustomerDialog(),
              icon: const Icon(Icons.add, size: 18),
              label: Text(
                'Add Customer',
                style: GoogleFonts.poppins(),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPink,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCustomers,
      child: ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _filteredCustomers.length,
      itemBuilder: (context, index) {
        final customer = _filteredCustomers[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildCustomerCard(customer),
        );
      },
      ),
    );
  }

  Widget _buildCommunicationsTab() {
    final allCommunications = _allCustomers
        .expand((customer) => customer.communicationHistory)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          DashboardCard(
            title: 'Recent Communications',
            child: Column(
              children: allCommunications.isEmpty
                  ? [
                      Container(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 48,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No Communications',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                            ),
                            Text(
                              'No customer communications recorded yet',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ]
                  : allCommunications
                      .take(10)
                      .map((comm) => _buildCommunicationItem(comm))
                      .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    final analytics = CrmAnalyticsService.calculateAnalytics(_allCustomers);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Key Performance Indicators
          _buildKpiRow(analytics),
          const SizedBox(height: 20),

          // Customer Lifecycle Analysis
          _buildCustomerLifecycleCard(analytics),
          const SizedBox(height: 20),

          // Communication Analytics
          _buildCommunicationAnalyticsCard(analytics),
          const SizedBox(height: 20),

          // Customer Growth Chart
          _buildCustomerGrowthCard(analytics),
          const SizedBox(height: 20),

          // Customer Segmentation
          _buildCustomerSegmentationCard(analytics),
          const SizedBox(height: 20),

          // Top Customers
          _buildTopCustomersCard(analytics),
        ],
      ),
    );
  }

  Widget _buildKpiRow(CrmAnalytics analytics) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use different layouts based on available width
        if (constraints.maxWidth < 600) {
          // Stack vertically on smaller screens
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      'Customers',
                      '${analytics.totalCustomers}',
                      Icons.people,
                      AppColors.primaryPink,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricCard(
                      'Revenue',
                      'RM${(analytics.totalRevenue / 1000).toStringAsFixed(0)}k',
                      Icons.monetization_on,
                      AppColors.successGreen,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      'Avg. Spend',
                      'RM${analytics.averageSpend.toStringAsFixed(0)}',
                      Icons.trending_up,
                      AppColors.infoBlue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricCard(
                      'Retention',
                      '${analytics.retentionRate.toStringAsFixed(0)}%',
                      Icons.repeat,
                      AppColors.warningOrange,
                    ),
                  ),
                ],
              ),
            ],
          );
        } else {
          // Single row for larger screens
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Total Customers',
                    analytics.totalCustomers.toString(),
                    Icons.people,
                    AppColors.primaryPink,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'Total Revenue',
                    'RM${analytics.totalRevenue.toStringAsFixed(0)}',
                    Icons.monetization_on,
                    AppColors.successGreen,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'Avg. Spend',
                    'RM${analytics.averageSpend.toStringAsFixed(2)}',
                    Icons.trending_up,
                    AppColors.infoBlue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'Retention Rate',
                    '${analytics.retentionRate.toStringAsFixed(1)}%',
                    Icons.repeat,
                    AppColors.warningOrange,
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildCustomerLifecycleCard(CrmAnalytics analytics) {
    return DashboardCard(
      title: 'Customer Lifecycle Analysis',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildLifecycleMetric(
                  'Active',
                  analytics.activeCustomers,
                  analytics.totalCustomers,
                  AppColors.successGreen,
                  'Last 90 days',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildLifecycleMetric(
                  'Dormant',
                  analytics.dormantCustomers,
                  analytics.totalCustomers,
                  AppColors.warningOrange,
                  '90-365 days',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildLifecycleMetric(
                  'Lost',
                  analytics.lostCustomers,
                  analytics.totalCustomers,
                  AppColors.errorRed,
                  '365+ days',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLifecycleMetric(
      String label, int count, int total, Color color, String subtitle) {
    final percentage = total > 0 ? (count / total * 100) : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(Customer customer) {
    return GestureDetector(
      onTap: () => _showCustomerDetails(customer),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 25,
                        backgroundColor:
                            AppColors.primaryPink.withValues(alpha: 0.1),
                        child: Text(
                          customer.firstName[0] + customer.lastName[0],
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryPink,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    customer.fullName,
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textDark,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                                if (customer.isVip) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.accentPink,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'VIP',
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            Text(
                              customer.email,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                            right: 80), // Space for action buttons
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'RM${customer.totalSpent.toStringAsFixed(2)}',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryPink,
                              ),
                            ),
                            Text(
                              '${customer.visitCount} visits',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        Icons.phone,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        customer.phone,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        customer.lastVisit != null
                            ? 'Last visit: ${DateFormat('MMM d').format(customer.lastVisit!)}'
                            : 'No visits yet',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  if (customer.vehicleIds.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.softPink,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.directions_car,
                            size: 16,
                            color: AppColors.primaryPink,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${customer.vehicleIds.length} vehicle${customer.vehicleIds.length != 1 ? 's' : ''}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppColors.primaryPink,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (customer.totalSpent > 0) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Spent',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                'RM ${customer.totalSpent.toStringAsFixed(2)}',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryPink,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Last Payment',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                customer.lastVisit != null
                                    ? DateFormat('MMM d, y')
                                        .format(customer.lastVisit!)
                                    : 'No payments',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Action buttons
            Positioned(
              top: 8,
              right: 8,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                onTap: () {
                  _showEditCustomerDialog(customer);
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPink.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.edit,
                    size: 16,
                    color: AppColors.primaryPink,
                  ),
                ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      _deleteCustomer(customer);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.errorRed.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.delete,
                        size: 16,
                        color: AppColors.errorRed,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommunicationAnalyticsCard(CrmAnalytics analytics) {
    return DashboardCard(
      title: 'Communication Analytics',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildCommMetric(
                  'Total Communications',
                  analytics.totalCommunications.toString(),
                  Icons.chat,
                  AppColors.primaryPink,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildCommMetric(
                  'Engagement Rate',
                  '${analytics.communicationEngagementRate.toStringAsFixed(1)}%',
                  Icons.trending_up,
                  AppColors.successGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (analytics.communicationsByType.isNotEmpty) ...[
            Text(
              'Communication Types',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: analytics.communicationsByType.entries.map((entry) {
                return _buildCommTypeChip(entry.key, entry.value);
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCommMetric(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCommTypeChip(String type, int count) {
    final color = _getCommTypeColor(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getCommTypeIcon(type), size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            '${type.toUpperCase()}: $count',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getCommTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'call':
        return AppColors.primaryPink;
      case 'email':
        return AppColors.infoBlue;
      case 'text':
        return AppColors.successGreen;
      case 'in-person':
        return AppColors.warningOrange;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getCommTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'call':
        return Icons.phone;
      case 'email':
        return Icons.email;
      case 'text':
        return Icons.sms;
      case 'in-person':
        return Icons.person;
      default:
        return Icons.chat;
    }
  }

  void _showCustomerDetails(Customer customer) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CustomerProfileScreen(
          customer: customer,
          onCustomerUpdated: _updateCustomer,
        ),
      ),
    );
  }

  Widget _buildCustomerGrowthCard(CrmAnalytics analytics) {
    return DashboardCard(
      title: 'Customer Growth Trend',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subtitle with time period info
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'Last 12 months customer acquisition',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          // Chart
          SizedBox(
            height: 240,
            child: Padding(
              padding: const EdgeInsets.only(right: 16, top: 16, bottom: 16),
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: AppColors.textSecondary.withValues(alpha: 0.1),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 2,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          if (value.toInt() >= 0 &&
                              value.toInt() < analytics.growthData.length) {
                            final monthData =
                                analytics.growthData[value.toInt()];
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                DateFormat('MMM').format(monthData.month),
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: analytics.growthData.isNotEmpty
                            ? (analytics.growthData
                                        .map((e) => e.customerCount)
                                        .reduce((a, b) => a > b ? a : b) /
                                    4)
                                .ceilToDouble()
                            : 1,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          return Text(
                            value.toInt().toString(),
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      bottom: BorderSide(
                        color: AppColors.textSecondary.withValues(alpha: 0.2),
                        width: 1,
                      ),
                      left: BorderSide(
                        color: AppColors.textSecondary.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: analytics.growthData.asMap().entries.map((entry) {
                        return FlSpot(entry.key.toDouble(),
                            entry.value.customerCount.toDouble());
                      }).toList(),
                      isCurved: true,
                      color: AppColors.primaryPink,
                      barWidth: 3,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 3,
                            color: AppColors.primaryPink,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.primaryPink.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerSegmentationCard(CrmAnalytics analytics) {
    return DashboardCard(
      title: 'Customer Segmentation',
      child: SizedBox(
        height: 200,
        child: PieChart(
          PieChartData(
            sectionsSpace: 2,
            centerSpaceRadius: 40,
            sections: [
              PieChartSectionData(
                color: AppColors.primaryPink,
                value: analytics.vipCustomers.toDouble(),
                title: 'VIP',
                radius: 50,
                titleStyle: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              PieChartSectionData(
                color: AppColors.accentPink,
                value: analytics.regularCustomers.toDouble(),
                title: 'Regular',
                radius: 50,
                titleStyle: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              PieChartSectionData(
                color: AppColors.lightPink,
                value: analytics.newCustomers.toDouble(),
                title: 'New',
                radius: 50,
                titleStyle: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopCustomersCard(CrmAnalytics analytics) {
    return DashboardCard(
      title: 'Top Customers by Spend',
      child: Column(
        children: analytics.topCustomers.isEmpty
            ? [
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'No customer data available',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ]
            : analytics.topCustomers.map((customer) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primaryPink.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor:
                            AppColors.primaryPink.withValues(alpha: 0.1),
                        child: Text(
                          customer.firstName[0] + customer.lastName[0],
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryPink,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              customer.fullName,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                            ),
                            Text(
                              '${customer.visitCount} visits',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'RM${customer.totalSpent.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryPink,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
      ),
    );
  }

  void _showAddCustomerDialog() {
    showDialog(
      context: context,
      builder: (context) => AddCustomerDialog(
        onCustomerAdded: _addCustomer,
      ),
    );
  }

  void _showEditCustomerDialog(Customer customer) {
    showDialog(
      context: context,
      builder: (context) => EditCustomerDialog(
        customer: customer,
        onCustomerUpdated: _updateCustomer,
      ),
    );
  }

  Widget _buildCommunicationItem(CommunicationLog comm) {
    final customer =
        _allCustomers.firstWhere((c) => c.communicationHistory.contains(comm));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.softPink,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            _getCommIcon(comm.type),
            color: AppColors.primaryPink,
            size: 16,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${customer.fullName} • ${comm.subject}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  DateFormat('MMM d, y').format(comm.date),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      height: 110, // Reduced height to prevent overflow
      padding: const EdgeInsets.all(12), // Reduced padding
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min, // Prevent overflow
        children: [
          Container(
            padding: const EdgeInsets.all(6), // Reduced padding
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              color: color,
              size: 18, // Slightly smaller icon
            ),
          ),
          const SizedBox(height: 8), // Reduced spacing
          Flexible(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 16, // Smaller font
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 2), // Reduced spacing
          Flexible(
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 10, // Smaller font
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCommIcon(String type) {
    switch (type.toLowerCase()) {
      case 'call':
        return Icons.phone;
      case 'email':
        return Icons.email;
      case 'text':
        return Icons.sms;
      case 'in-person':
        return Icons.person;
      default:
        return Icons.chat;
    }
  }
}
