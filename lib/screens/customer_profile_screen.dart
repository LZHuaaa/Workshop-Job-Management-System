import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../widgets/dashboard_card.dart';
import '../models/customer.dart';
import '../models/service_record.dart' as service;
import '../services/service_record_service.dart';
import '../dialogs/add_communication_dialog.dart';
import '../dialogs/edit_customer_dialog.dart';
import '../dialogs/add_service_dialog.dart';

class CustomerProfileScreen extends StatefulWidget {
  final Customer customer;
  final Function(Customer) onCustomerUpdated;

  const CustomerProfileScreen({
    super.key,
    required this.customer,
    required this.onCustomerUpdated,
  });

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late Customer _currentCustomer;
  final ServiceRecordService _serviceRecordService = ServiceRecordService();
  List<service.ServiceRecord> _serviceRecords = [];
  bool _isLoadingServiceRecords = false;

  // Computed properties - fallback to embedded data while loading
  double get _computedTotalSpent => _serviceRecords.isNotEmpty
      ? _serviceRecords.fold(0.0, (sum, record) => sum + record.cost)
      : _currentCustomer.computedTotalSpent;

  int get _computedVisitCount => _serviceRecords.isNotEmpty
      ? _serviceRecords.length
      : _currentCustomer.visitCount;

  DateTime? get _computedLastVisit => _serviceRecords.isNotEmpty
      ? _serviceRecords
          .map((r) => r.serviceDate)
          .reduce((a, b) => a.isAfter(b) ? a : b)
      : _currentCustomer.computedLastVisit;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _currentCustomer = widget.customer;
    _loadServiceRecords();
  }

  Future<void> _loadServiceRecords() async {
    setState(() {
      _isLoadingServiceRecords = true;
    });

    try {
      final serviceRecords = await _serviceRecordService
          .getServiceRecordsByCustomer(_currentCustomer.id);
      setState(() {
        _serviceRecords = serviceRecords;
        _isLoadingServiceRecords = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingServiceRecords = false;
      });
      print('Error loading service records: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showEditCustomerDialog() {
    showDialog(
      context: context,
      builder: (context) => EditCustomerDialog(
        customer: _currentCustomer,
        onCustomerUpdated: (updatedCustomer) {
          setState(() {
            _currentCustomer = updatedCustomer;
          });
          widget.onCustomerUpdated(updatedCustomer);
        },
      ),
    );
  }

  void _showAddServiceDialog() {
    showDialog(
      context: context,
      builder: (context) => AddServiceDialog(
        customer: _currentCustomer,
        onServiceAdded: (newService) {
          // Reload service records from database to get the latest data
          _loadServiceRecords();
          widget.onCustomerUpdated(_currentCustomer);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          _currentCustomer.fullName,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.edit, color: AppColors.primaryPink),
            onPressed: () => _showEditCustomerDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Customer Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      child: Text(
                        _getCustomerInitials(_currentCustomer),
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                _currentCustomer.fullName,
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              if (_currentCustomer.isVip) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.accentPink,
                                    borderRadius: BorderRadius.circular(12),
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
                          const SizedBox(height: 4),
                          Text(
                            _currentCustomer.email,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                          Text(
                            _currentCustomer.phone,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildHeaderStat(
                        'Total Spent',
                        'RM${_computedTotalSpent.toStringAsFixed(2)}',
                        Icons.monetization_on,
                      ),
                    ),
                    Expanded(
                      child: _buildHeaderStat(
                        'Visits',
                        '${_computedVisitCount}',
                        Icons.event,
                      ),
                    ),
                    Expanded(
                      child: _buildHeaderStat(
                        'Vehicles',
                        '${_currentCustomer.vehicleIds.length}',
                        Icons.directions_car,
                      ),
                    ),
                    Expanded(
                      child: _buildHeaderStat(
                        'Last Visit',
                        _computedLastVisit != null
                            ? '${DateTime.now().difference(_computedLastVisit!).inDays} days ago'
                            : 'Never',
                        Icons.schedule,
                      ),
                    ),
                  ],
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
                Tab(text: 'Details'),
                Tab(text: 'Communications'),
                Tab(text: 'Service History'),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDetailsTab(),
                _buildCommunicationsTab(),
                _buildServiceHistoryTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white.withValues(alpha: 0.8),
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 9,
            color: Colors.white.withValues(alpha: 0.8),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          DashboardCard(
            title: 'Contact Information',
            child: Column(
              children: [
                _buildDetailRow('Full Name', _currentCustomer.fullName),
                _buildDetailRow('Email', _currentCustomer.email),
                _buildDetailRow('Phone', _currentCustomer.phone),
                if (_currentCustomer.fullAddress.isNotEmpty)
                  _buildDetailRow('Address', _currentCustomer.fullAddress),
                _buildDetailRow('Customer Since',
                    DateFormat('MMM d, y').format(_currentCustomer.createdAt)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          DashboardCard(
            title: 'Preferences',
            child: Column(
              children: [
                _buildDetailRow(
                    'Contact Method',
                    _currentCustomer.preferences.preferredContactMethod
                        .toUpperCase()),
                if (_currentCustomer.preferences.preferredMechanic != null)
                  _buildDetailRow('Preferred Mechanic',
                      _currentCustomer.preferences.preferredMechanic!),
                if (_currentCustomer.preferences.preferredServiceTime != null)
                  _buildDetailRow(
                      'Preferred Service Time',
                      _currentCustomer.preferences.preferredServiceTime!
                          .toUpperCase()),
                _buildDetailRow(
                    'Receive Promotions',
                    _currentCustomer.preferences.receivePromotions
                        ? 'Yes'
                        : 'No'),
                _buildDetailRow(
                    'Receive Reminders',
                    _currentCustomer.preferences.receiveReminders
                        ? 'Yes'
                        : 'No'),
              ],
            ),
          ),
          if (_currentCustomer.notes != null) ...[
            const SizedBox(height: 20),
            DashboardCard(
              title: 'Notes',
              child: Text(
                _currentCustomer.notes!,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.textDark,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCommunicationsTab() {
    return Column(
      children: [
        // Communication Actions Header
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
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Communication History',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: ElevatedButton.icon(
                      onPressed: _showAddCommunicationDialog,
                      icon: const Icon(Icons.add, size: 16),
                      label: Text(
                        'Log Communication',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryPink,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        minimumSize: const Size(0, 36),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Communication List
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: _currentCustomer.communicationHistory.isEmpty
                  ? [
                      Container(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 64,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No Communications',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                            ),
                            Text(
                              'Start by logging your first communication with this customer',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ]
                  : _currentCustomer.communicationHistory
                      .map((comm) => Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: _buildCommunicationCard(comm),
                          ))
                      .toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildServiceHistoryTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Header with action button
          Row(
            children: [
              Text(
                'Service History',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showAddServiceDialog(),
                icon: const Icon(Icons.add, size: 18),
                label: Text(
                  'Add Service',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPink,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Service history content
          Expanded(
            child: _isLoadingServiceRecords
                ? const Center(child: CircularProgressIndicator())
                : _serviceRecords.isEmpty &&
                        _currentCustomer.serviceHistory.isEmpty
                    ? _buildEmptyServiceState()
                    : RefreshIndicator(
                        onRefresh: _loadServiceRecords,
                        child: ListView.builder(
                          itemCount: _serviceRecords.isNotEmpty
                              ? _serviceRecords.length
                              : _currentCustomer.serviceHistory.length,
                          itemBuilder: (context, index) {
                            if (_serviceRecords.isNotEmpty) {
                              // Use database records
                              final serviceRecord = _serviceRecords[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                child: _buildServiceCard(serviceRecord),
                              );
                            } else {
                              // Fallback to embedded records
                              final serviceRecord =
                                  _currentCustomer.serviceHistory[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                child: _buildServiceCard(serviceRecord),
                              );
                            }
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyServiceState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primaryPink.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Icon(
              Icons.build_outlined,
              size: 40,
              color: AppColors.primaryPink,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Service History',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No service records found for this customer.\nService history will appear here once added.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddServiceDialog(),
            icon: const Icon(Icons.add, size: 20),
            label: Text(
              'Add First Service Record',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPink,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(service.ServiceRecord serviceRecord) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryPink.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  serviceRecord.serviceType,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primaryPink,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                DateFormat('MMM dd, yyyy').format(serviceRecord.serviceDate),
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            serviceRecord.description,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildServiceDetail('Mileage', '${serviceRecord.mileage} km'),
              const SizedBox(width: 20),
              _buildServiceDetail(
                  'Cost', 'RM ${serviceRecord.cost.toStringAsFixed(2)}'),
              const Spacer(),
              _buildServiceDetail('Mechanic', serviceRecord.mechanicName),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServiceDetail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunicationCard(CommunicationLog comm) {
    final isInbound = comm.direction == 'inbound';
    final typeColor = _getTypeColor(comm.type);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isInbound
              ? AppColors.infoBlue.withValues(alpha: 0.2)
              : AppColors.primaryPink.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
            // Header with type, direction, and date
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getCommIcon(comm.type),
                        size: 14,
                        color: typeColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        comm.type.toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: typeColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isInbound
                        ? AppColors.infoBlue.withValues(alpha: 0.1)
                        : AppColors.primaryPink.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isInbound ? Icons.call_received : Icons.call_made,
                        size: 12,
                        color: isInbound
                            ? AppColors.infoBlue
                            : AppColors.primaryPink,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        comm.direction.toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isInbound
                              ? AppColors.infoBlue
                              : AppColors.primaryPink,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormat('MMM d, y • h:mm a').format(comm.date),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Subject
            Text(
              comm.subject,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),

            const SizedBox(height: 8),

            // Content
            Text(
              comm.content,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textDark,
                height: 1.4,
              ),
            ),

            if (comm.staffMember != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Handled by ${comm.staffMember}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
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

  void _showAddCommunicationDialog() {
    showDialog(
      context: context,
      builder: (context) => AddCommunicationDialog(
        customer: _currentCustomer,
        onCommunicationAdded: _addCommunication,
      ),
    );
  }

  void _addCommunication(CommunicationLog communication) {
    setState(() {
      _currentCustomer = _currentCustomer.copyWith(
        communicationHistory: [
          ..._currentCustomer.communicationHistory,
          communication,
        ],
      );
    });
    widget.onCustomerUpdated(_currentCustomer);
  }

  // Helper method to safely get customer initials
  String _getCustomerInitials(Customer customer) {
    final firstInitial = customer.firstName.isNotEmpty
        ? customer.firstName[0].toUpperCase()
        : '';
    final lastInitial =
        customer.lastName.isNotEmpty ? customer.lastName[0].toUpperCase() : '';

    if (firstInitial.isEmpty && lastInitial.isEmpty) {
      return '?'; // Fallback for customers with no name
    }

    return firstInitial + lastInitial;
  }
}
