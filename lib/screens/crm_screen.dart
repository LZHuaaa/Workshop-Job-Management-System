import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_colors.dart';
import '../widgets/dashboard_card.dart';
import '../models/customer.dart';
import '../screens/customer_profile_screen.dart';
import '../dialogs/add_customer_dialog.dart';

class CrmScreen extends StatefulWidget {
  const CrmScreen({super.key});

  @override
  State<CrmScreen> createState() => _CrmScreenState();
}

class _CrmScreenState extends State<CrmScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';

  final List<String> _filterOptions = [
    'All',
    'VIP',
    'Recent',
    'Inactive',
  ];

  // Sample customer data
  List<Customer> _allCustomers = [
    Customer(
      id: '1',
      firstName: 'Ahmad',
      lastName: 'bin Abdullah',
      email: 'ahmad.abdullah@email.com',
      phone: '012-345-6789',
      address: 'No. 15, Jalan Bukit Bintang',
      city: 'Kuala Lumpur',
      state: 'Selangor',
      zipCode: '50200',
      createdAt: DateTime.now().subtract(const Duration(days: 365)),
      lastVisit: DateTime.now().subtract(const Duration(days: 30)),
      vehicleIds: ['v1'],
      totalSpent: 1250.75,
      visitCount: 8,
      preferences: CustomerPreferences(
        preferredContactMethod: 'phone',
        receivePromotions: true,
        receiveReminders: true,
        preferredMechanic: 'Lim Wei Ming',
      ),
      communicationHistory: [
        CommunicationLog(
          id: 'c1',
          date: DateTime.now().subtract(const Duration(days: 5)),
          type: 'call',
          subject: 'Service Reminder',
          content: 'Called to remind about upcoming oil change',
          direction: 'outbound',
          staffMember: 'Siti',
        ),
      ],
      notes: 'Prefers synthetic oil, always on time for appointments',
    ),
    Customer(
      id: '2',
      firstName: 'Tan',
      lastName: 'Mei Ling',
      email: 'tan.meiling@email.com',
      phone: '013-987-6543',
      address: 'No. 88, Jalan Gurney',
      city: 'George Town',
      state: 'Penang',
      zipCode: '10250',
      createdAt: DateTime.now().subtract(const Duration(days: 200)),
      lastVisit: DateTime.now().subtract(const Duration(days: 95)),
      vehicleIds: ['v2'],
      totalSpent: 589.50,
      visitCount: 3,
      preferences: CustomerPreferences(
        preferredContactMethod: 'email',
        receivePromotions: false,
        receiveReminders: true,
      ),
      communicationHistory: [
        CommunicationLog(
          id: 'c2',
          date: DateTime.now().subtract(const Duration(days: 95)),
          type: 'email',
          subject: 'Service Completed',
          content: 'Transmission service completed successfully',
          direction: 'outbound',
          staffMember: 'Raj',
        ),
      ],
    ),
    Customer(
      id: '3',
      firstName: 'Priya',
      lastName: 'd/o Raman',
      email: 'priya.raman@email.com',
      phone: '014-456-7890',
      createdAt: DateTime.now().subtract(const Duration(days: 500)),
      lastVisit: DateTime.now().subtract(const Duration(days: 180)),
      vehicleIds: ['v3'],
      totalSpent: 2150.25,
      visitCount: 15,
      preferences: CustomerPreferences(
        preferredContactMethod: 'phone',
        receivePromotions: true,
        receiveReminders: true,
        preferredMechanic: 'Muhammad Faiz bin Omar',
      ),
      notes: 'VIP customer, owns multiple vehicles',
    ),
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
              customer.phone.contains(searchTerm))
          .toList();
    }

    return filtered;
  }

  void _addCustomer(Customer customer) {
    setState(() {
      _allCustomers.add(customer);
    });
  }

  void _updateCustomer(Customer updatedCustomer) {
    setState(() {
      final index = _allCustomers
          .indexWhere((customer) => customer.id == updatedCustomer.id);
      if (index != -1) {
        _allCustomers[index] = updatedCustomer;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
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
                    color: Colors.black.withOpacity(0.05),
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

                  // Stats Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Total Customers',
                          _allCustomers.length.toString(),
                          AppColors.primaryPink,
                          Icons.people,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'VIP Customers',
                          _allCustomers.where((c) => c.isVip).length.toString(),
                          AppColors.accentPink,
                          Icons.star,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Inactive',
                          _allCustomers
                              .where((c) => c.daysSinceLastVisit > 90)
                              .length
                              .toString(),
                          AppColors.warningOrange,
                          Icons.warning_amber,
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
                      onChanged: (value) => setState(() {}),
                      decoration: InputDecoration(
                        hintText:
                            'Search customers by name, email, or phone...',
                        hintStyle: GoogleFonts.poppins(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: AppColors.textSecondary,
                        ),
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
                                  : AppColors.textSecondary.withOpacity(0.3),
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
                  Tab(text: 'All'),
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

  Widget _buildStatCard(
      String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            title,
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

  Widget _buildCustomersTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _filteredCustomers.length,
      itemBuilder: (context, index) {
        final customer = _filteredCustomers[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildCustomerCard(customer),
        );
      },
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Customer Growth Chart
          DashboardCard(
            title: 'Customer Growth',
            child: SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        FlSpot(0, 10),
                        FlSpot(1, 15),
                        FlSpot(2, 25),
                        FlSpot(3, 30),
                        FlSpot(4, 45),
                        FlSpot(5, 60),
                      ],
                      isCurved: true,
                      color: AppColors.primaryPink,
                      barWidth: 3,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.primaryPink.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Customer Segmentation
          DashboardCard(
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
                      value:
                          _allCustomers.where((c) => c.isVip).length.toDouble(),
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
                      value: _allCustomers
                          .where((c) => !c.isVip && c.visitCount > 0)
                          .length
                          .toDouble(),
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
                      value: _allCustomers
                          .where((c) => c.visitCount == 0)
                          .length
                          .toDouble(),
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
          ),
          const SizedBox(height: 20),

          // Key Metrics
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Avg. Spend',
                  'RM${(_allCustomers.fold(0.0, (sum, c) => sum + c.totalSpent) / _allCustomers.length).toStringAsFixed(2)}',
                  Icons.monetization_on,
                  AppColors.primaryPink,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'Retention Rate',
                  '${((_allCustomers.where((c) => c.visitCount > 1).length / _allCustomers.length) * 100).toStringAsFixed(1)}%',
                  Icons.repeat,
                  AppColors.successGreen,
                ),
              ),
            ],
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
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: AppColors.primaryPink.withOpacity(0.1),
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
                            Text(
                              customer.fullName,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
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
                        ),
                      ],
                    ),
                  ),
                  Column(
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
            ],
          ),
        ),
      ),
    );
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

  void _showAddCustomerDialog() {
    showDialog(
      context: context,
      builder: (context) => AddCustomerDialog(
        onCustomerAdded: _addCustomer,
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
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textSecondary,
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
