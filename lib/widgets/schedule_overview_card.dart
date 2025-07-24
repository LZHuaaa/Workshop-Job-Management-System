import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_colors.dart';
import '../widgets/dashboard_card.dart';
import '../dialogs/new_job_dialog.dart';
import '../models/job_appointment.dart';

class ScheduleOverviewCard extends StatelessWidget {
  final Function(JobAppointment)? onJobCreated;

  const ScheduleOverviewCard({
    super.key,
    this.onJobCreated,
  });

  void _showNewJobDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => NewJobDialog(
        onJobCreated: (job) {
          if (onJobCreated != null) {
            onJobCreated!(job);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      title: "Today's Schedule",
      action: ActionButton(
        label: 'New Job',
        icon: Icons.add,
        onPressed: () => _showNewJobDialog(context),
      ),
      child: Column(
        children: [
          // Horizontal Bar Chart
          SizedBox(
            height: 60,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 10,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const titles = [
                          'Scheduled',
                          'In Progress',
                          'Completed'
                        ];
                        if (value.toInt() < titles.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              titles[value.toInt()],
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: 5,
                        color: AppColors.accentPink,
                        width: 40,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: 3,
                        color: AppColors.primaryPink,
                        width: 40,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 2,
                    barRods: [
                      BarChartRodData(
                        toY: 7,
                        color: AppColors.lightPink,
                        width: 40,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Summary Text
          Text(
            '3 Jobs In Progress, 5 Awaiting Start',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 20),

          // Upcoming Jobs List
          Column(
            children: [
              _buildJobItem(
                vehicle: 'Honda Civic - WXY 1234',
                mechanic: 'John Smith',
                time: '10:30 AM',
              ),
              const SizedBox(height: 12),
              _buildJobItem(
                vehicle: 'Toyota Camry - ABC 5678',
                mechanic: 'Mike Johnson',
                time: '11:15 AM',
              ),
              const SizedBox(height: 12),
              _buildJobItem(
                vehicle: 'Ford Focus - DEF 9012',
                mechanic: 'Sarah Wilson',
                time: '2:00 PM',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildJobItem({
    required String vehicle,
    required String mechanic,
    required String time,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.softPink,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryPink.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.directions_car,
              color: AppColors.primaryPink,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vehicle,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  mechanic,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.primaryPink,
            ),
          ),
        ],
      ),
    );
  }
}
