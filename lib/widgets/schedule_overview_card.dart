import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../widgets/dashboard_card.dart';
import '../dialogs/new_job_dialog.dart';
import '../dialogs/new_service_record_dialog.dart';
import '../models/job_appointment.dart';
import '../screens/job_details_screen.dart';

class ScheduleOverviewCard extends StatefulWidget {
  final Function(JobAppointment)? onJobCreated;

  const ScheduleOverviewCard({
    super.key,
    this.onJobCreated,
  });

  @override
  State<ScheduleOverviewCard> createState() => _ScheduleOverviewCardState();
}

class _ScheduleOverviewCardState extends State<ScheduleOverviewCard> {
  List<JobAppointment> _todayAppointments = [];
  bool _isLoading = true;
  Map<JobStatus, int> _statusCounts = {
    JobStatus.scheduled: 0,
    JobStatus.inProgress: 0,
    JobStatus.completed: 0,
    JobStatus.cancelled: 0,
  };

  @override
  void initState() {
    super.initState();
    _loadTodayAppointments();
  }

  void _loadTodayAppointments() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    FirebaseFirestore.instance
        .collection('appointments')
        .where('startTime', isGreaterThanOrEqualTo: startOfDay)
        .where('startTime', isLessThan: endOfDay)
        .orderBy('startTime')
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        final appointments = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;

          if (data['startTime'] is Timestamp) {
            data['startTime'] = (data['startTime'] as Timestamp).toDate();
          }
          if (data['endTime'] is Timestamp) {
            data['endTime'] = (data['endTime'] as Timestamp).toDate();
          }

          return JobAppointment.fromMap(data);
        }).toList();

        // Sort by start time
        appointments.sort((a, b) => a.startTime.compareTo(b.startTime));

        // Update status counts
        final counts = {
          JobStatus.scheduled: 0,
          JobStatus.inProgress: 0,
          JobStatus.completed: 0,
          JobStatus.cancelled: 0,
        };

        for (var appointment in appointments) {
          counts[appointment.status] = counts[appointment.status]! + 1;
        }

        setState(() {
          _todayAppointments = appointments;
          _statusCounts = counts;
          _isLoading = false;
        });
      }
    });
  }

  void _showNewJobDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => NewJobDialog(
        onJobCreated: (job) {
          if (widget.onJobCreated != null) {
            widget.onJobCreated!(job);
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
                        toY: _statusCounts[JobStatus.scheduled]!.toDouble(),
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
                        toY: _statusCounts[JobStatus.inProgress]!.toDouble(),
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
                        toY: _statusCounts[JobStatus.completed]!.toDouble(),
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
            '${_statusCounts[JobStatus.inProgress]} Jobs In Progress, ${_statusCounts[JobStatus.scheduled]} Awaiting Start',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 20),

          // Upcoming Jobs List
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryPink,
              ),
            )
          else if (_todayAppointments.isEmpty)
            Center(
              child: Text(
                'No jobs scheduled for today',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          else
            Column(
              children: _todayAppointments.map((appointment) {
                return Column(
                  children: [
                    _buildJobItem(
                      vehicle: appointment.vehicleInfo,
                      mechanic: appointment.mechanicName,
                      time: DateFormat('h:mm a').format(appointment.startTime),
                      appointment: appointment,
                    ),
                    const SizedBox(height: 12),
                  ],
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  void _navigateToJobDetails(BuildContext context, JobAppointment appointment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JobDetailsScreen(
          job: appointment,
          onJobUpdated: (updatedJob) {
            // The schedule will automatically update through Firebase listener
          },
        ),
      ),
    );
  }

  Widget _buildJobItem({
    required String vehicle,
    required String mechanic,
    required String time,
    required JobAppointment appointment,
  }) {
    return InkWell(
      onTap: () => _navigateToJobDetails(context, appointment),
      borderRadius: BorderRadius.circular(8),
      child: Container(
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
      ),
    );
  }
}
