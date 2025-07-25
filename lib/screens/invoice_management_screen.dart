import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../widgets/dashboard_card.dart';
import '../models/invoice.dart';

class InvoiceManagementScreen extends StatefulWidget {
  const InvoiceManagementScreen({super.key});

  @override
  State<InvoiceManagementScreen> createState() => _InvoiceManagementScreenState();
}

class _InvoiceManagementScreenState extends State<InvoiceManagementScreen> {
  String _selectedFilter = 'All';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _filterOptions = [
    'All',
    'Draft',
    'Pending',
    'Approved',
    'Paid',
    'Overdue',
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Quick Stats
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Pending Approval',
                    '5',
                    AppColors.warningOrange,
                    Icons.pending_actions,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Overdue',
                    '3',
                    AppColors.errorRed,
                    Icons.warning_amber,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'This Month',
                    'RM 12.5K',
                    AppColors.primaryPink,
                    Icons.payments,
                  ),
                ),
              ],
            ),
          ),

          // Search and Filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                // Search
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search invoices by ID, customer, or job...',
                    prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.textSecondary.withOpacity(0.2),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.textSecondary.withOpacity(0.2),
                      ),
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

          const SizedBox(height: 16),

          // Recent Invoices
          DashboardCard(
            title: 'Recent Invoices',
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                for (var i = 0; i < 5; i++)
                  _buildInvoiceCard(
                    jobId: 'JOB-${1000 + i}',
                    invoiceId: 'INV-${2000 + i}',
                    customerName: 'Customer ${i + 1}',
                    jobType: i % 2 == 0 ? 'Oil Change' : 'Brake Service',
                    amount: (150 + i * 100).toDouble(),
                    date: DateTime.now().subtract(Duration(days: i)),
                    status: i % 3 == 0
                        ? InvoiceStatus.pending
                        : (i % 3 == 1
                            ? InvoiceStatus.approved
                            : InvoiceStatus.paid),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceCard({
    required String jobId,
    required String invoiceId,
    required String customerName,
    required String jobType,
    required double amount,
    required DateTime date,
    required InvoiceStatus status,
  }) {
    Color statusColor;
    switch (status) {
      case InvoiceStatus.draft:
        statusColor = AppColors.textSecondary;
        break;
      case InvoiceStatus.pending:
        statusColor = AppColors.warningOrange;
        break;
      case InvoiceStatus.approved:
        statusColor = AppColors.primaryPink;
        break;
      case InvoiceStatus.paid:
        statusColor = AppColors.successGreen;
        break;
      case InvoiceStatus.cancelled:
        statusColor = AppColors.errorRed;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.textSecondary.withOpacity(0.1),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    invoiceId,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    'Job: $jobId',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status.name.toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customerName,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      jobType,
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
                    'RM ${amount.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryPink,
                    ),
                  ),
                  Text(
                    DateFormat('MMM d, y').format(date),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (status == InvoiceStatus.pending) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    // TODO: Implement approve action
                  },
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('Approve'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.successGreen,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () {
                    // TODO: Implement reject action
                  },
                  icon: const Icon(Icons.cancel_outlined, size: 18),
                  label: const Text('Reject'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.errorRed,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
} 