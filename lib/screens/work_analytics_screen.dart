import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../widgets/dashboard_card.dart';

class WorkAnalyticsScreen extends StatelessWidget {
  const WorkAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Work Analytics',
          style: GoogleFonts.poppins(
            color: AppColors.textDark,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: AppColors.textDark,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Quick Stats Row
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Jobs Completed',
                      '45',
                      'This Month',
                      AppColors.primaryPink,
                      Icons.build,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Revenue',
                      'RM 12.5K',
                      'This Month',
                      AppColors.successGreen,
                      Icons.payments,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Performance Metrics
              DashboardCard(
                title: 'Performance Metrics',
                child: Column(
                  children: [
                    _buildMetricRow(
                      'Average Job Duration',
                      '2.5 hours',
                      Icons.timer,
                      AppColors.primaryPink,
                    ),
                    const Divider(),
                    _buildMetricRow(
                      'Customer Satisfaction',
                      '4.8/5.0',
                      Icons.star,
                      AppColors.warningOrange,
                    ),
                    const Divider(),
                    _buildMetricRow(
                      'On-time Completion',
                      '95%',
                      Icons.check_circle,
                      AppColors.successGreen,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Financial Summary
              DashboardCard(
                title: 'Financial Summary',
                child: Column(
                  children: [
                    _buildFinancialMetric(
                      'Total Revenue',
                      'RM 45,250',
                      '+12% vs last month',
                      true,
                    ),
                    const Divider(),
                    _buildFinancialMetric(
                      'Average Invoice',
                      'RM 850',
                      '+5% vs last month',
                      true,
                    ),
                    const Divider(),
                    _buildFinancialMetric(
                      'Pending Payments',
                      'RM 12,350',
                      '8 invoices',
                      false,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Workload Distribution
              DashboardCard(
                title: 'Workload Distribution',
                child: Column(
                  children: [
                    _buildWorkloadBar('Oil Change', 35),
                    const SizedBox(height: 12),
                    _buildWorkloadBar('Brake Service', 25),
                    const SizedBox(height: 12),
                    _buildWorkloadBar('Tire Service', 20),
                    const SizedBox(height: 12),
                    _buildWorkloadBar('Engine Repair', 15),
                    const SizedBox(height: 12),
                    _buildWorkloadBar('Others', 5),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    String subtitle,
    Color color,
    IconData icon,
  ) {
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
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textDark,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialMetric(
    String label,
    String value,
    String change,
    bool isPositive,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  change,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: isPositive
                        ? AppColors.successGreen
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryPink,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkloadBar(String label, int percentage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textDark,
              ),
            ),
            Text(
              '$percentage%',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryPink,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: percentage / 100,
          backgroundColor: AppColors.primaryPink.withOpacity(0.1),
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryPink),
        ),
      ],
    );
  }
} 