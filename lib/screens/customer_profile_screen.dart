import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../widgets/dashboard_card.dart';
import '../models/customer.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _currentCustomer = widget.customer;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Edit functionality coming soon!'),
                  backgroundColor: AppColors.primaryPink,
                ),
              );
            },
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
                  color: Colors.black.withOpacity(0.1),
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
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: Text(
                        _currentCustomer.firstName[0] + _currentCustomer.lastName[0],
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
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                          Text(
                            _currentCustomer.phone,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
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
                        '\$${_currentCustomer.totalSpent.toStringAsFixed(2)}',
                        Icons.monetization_on,
                      ),
                    ),
                    Expanded(
                      child: _buildHeaderStat(
                        'Visits',
                        '${_currentCustomer.visitCount}',
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
                        _currentCustomer.lastVisit != null
                            ? '${_currentCustomer.daysSinceLastVisit} days ago'
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
          color: Colors.white.withOpacity(0.8),
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
            color: Colors.white.withOpacity(0.8),
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
                _buildDetailRow('Customer Since', DateFormat('MMM d, y').format(_currentCustomer.createdAt)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          DashboardCard(
            title: 'Preferences',
            child: Column(
              children: [
                _buildDetailRow('Contact Method', _currentCustomer.preferences.preferredContactMethod.toUpperCase()),
                if (_currentCustomer.preferences.preferredMechanic != null)
                  _buildDetailRow('Preferred Mechanic', _currentCustomer.preferences.preferredMechanic!),
                if (_currentCustomer.preferences.preferredServiceTime != null)
                  _buildDetailRow('Preferred Service Time', _currentCustomer.preferences.preferredServiceTime!.toUpperCase()),
                _buildDetailRow('Receive Promotions', _currentCustomer.preferences.receivePromotions ? 'Yes' : 'No'),
                _buildDetailRow('Receive Reminders', _currentCustomer.preferences.receiveReminders ? 'Yes' : 'No'),
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
    return SingleChildScrollView(
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
                        'No communication history with this customer yet',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
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
    );
  }

  Widget _buildServiceHistoryTab() {
    return const Center(
      child: Text('Service history functionality coming soon!'),
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
    return DashboardCard(
      title: comm.subject,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getCommIcon(comm.type),
                size: 16,
                color: AppColors.primaryPink,
              ),
              const SizedBox(width: 8),
              Text(
                '${comm.type.toUpperCase()} • ${comm.direction.toUpperCase()}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primaryPink,
                ),
              ),
              const Spacer(),
              Text(
                DateFormat('MMM d, y').format(comm.date),
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            comm.content,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.textDark,
            ),
          ),
          if (comm.staffMember != null) ...[
            const SizedBox(height: 8),
            Text(
              'Staff: ${comm.staffMember}',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
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
