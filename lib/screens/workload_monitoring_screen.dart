import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../widgets/dashboard_card.dart';
import '../models/job_appointment.dart';
import '../services/job_appointment_service.dart';
import 'mechanic_tasks_detail_screen.dart';

class WorkloadMonitoringScreen extends StatefulWidget {
  const WorkloadMonitoringScreen({super.key});

  @override
  State<WorkloadMonitoringScreen> createState() => _WorkloadMonitoringScreenState();
}

class _WorkloadMonitoringScreenState extends State<WorkloadMonitoringScreen> {
  final JobAppointmentService _jobService = JobAppointmentService();
  List<JobAppointment> _allJobs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  void _loadJobs() {
    _jobService.getAppointmentsStream().listen((jobs) {
      if (mounted) {
        setState(() {
          _allJobs = jobs;
          _isLoading = false;
        });
      }
    });
  }

  Map<String, List<JobAppointment>> _getMechanicWorkload() {
    final Map<String, List<JobAppointment>> workload = {};
    for (final job in _allJobs) {
      if (!workload.containsKey(job.mechanicName)) {
        workload[job.mechanicName] = [];
      }
      workload[job.mechanicName]!.add(job);
    }
    return workload;
  }

  Map<JobStatus, int> _getJobStatusCounts() {
    final Map<JobStatus, int> statusCounts = {};
    for (final status in JobStatus.values) {
      statusCounts[status] = 0;
    }
    for (final job in _allJobs) {
      statusCounts[job.status] = (statusCounts[job.status] ?? 0) + 1;
    }
    return statusCounts;
  }

  double _getMechanicCompletionRate(List<JobAppointment> jobs) {
    if (jobs.isEmpty) return 0.0;
    final completedJobs = jobs.where((job) => job.status == JobStatus.completed).length;
    return (completedJobs / jobs.length) * 100;
  }

  Color _getCapacityColor(int jobCount) {
    if (jobCount <= 2) return AppColors.successGreen; // Low utilization
    if (jobCount <= 4) return Colors.orange; // Medium utilization
    return AppColors.errorRed; // High utilization
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: const Center(
          child: CircularProgressIndicator(
            color: AppColors.primaryPink,
          ),
        ),
      );
    }

    final mechanicWorkload = _getMechanicWorkload();
    final statusCounts = _getJobStatusCounts();
    final totalJobs = _allJobs.length;
    final completedJobs = statusCounts[JobStatus.completed] ?? 0;
    final overallCompletionRate = totalJobs > 0 ? (completedJobs / totalJobs) * 100 : 0.0;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Workload Monitoring',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Overall Metrics
                    Row(
                      children: [
                        Expanded(
                          child: DashboardCard(
                            title: 'Total Jobs',
                            child: Column(
                              children: [
                                Text(
                                  '$totalJobs',
                                  style: GoogleFonts.poppins(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryPink,
                                  ),
                                ),
                                Text(
                                  'Active Jobs',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DashboardCard(
                            title: 'Completion Rate',
                            child: Column(
                              children: [
                                Text(
                                  '${overallCompletionRate.toStringAsFixed(1)}%',
                                  style: GoogleFonts.poppins(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.successGreen,
                                  ),
                                ),
                                Text(
                                  'Overall Rate',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Job Progress Status
                    DashboardCard(
                      title: 'Job Progress Status',
                      child: Column(
                        children: JobStatus.values.map((status) {
                          final count = statusCounts[status] ?? 0;
                          final percentage = totalJobs > 0 ? (count / totalJobs) * 100 : 0.0;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(status),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    status.name.toUpperCase(),
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                ),
                                Text(
                                  '$count (${percentage.toStringAsFixed(1)}%)',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Mechanic Workload Distribution
                    DashboardCard(
                      title: 'Mechanic Workload Distribution',
                      child: Column(
                        children: mechanicWorkload.entries.map((entry) {
                          final mechanicName = entry.key;
                          final jobs = entry.value;
                          final completionRate = _getMechanicCompletionRate(jobs);
                          final capacityColor = _getCapacityColor(jobs.length);

                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _navigateToMechanicTasks(mechanicName),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: capacityColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: capacityColor.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              mechanicName,
                                              style: GoogleFonts.poppins(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.textDark,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: capacityColor,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              '${jobs.length} jobs',
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'Completion Rate: ${completionRate.toStringAsFixed(1)}%',
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              Text(
                                                _getCapacityLabel(jobs.length),
                                                style: GoogleFonts.poppins(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: capacityColor,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Icon(
                                                Icons.arrow_forward_ios,
                                                size: 12,
                                                color: AppColors.textSecondary,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(JobStatus status) => switch (status) {
    JobStatus.scheduled => Colors.blue,
    JobStatus.inProgress => Colors.orange,
    JobStatus.completed => AppColors.successGreen,
    JobStatus.cancelled => AppColors.textSecondary,
    JobStatus.overdue => AppColors.errorRed,
  };

  String _getCapacityLabel(int jobCount) {
    if (jobCount <= 2) return 'Available';
    if (jobCount <= 4) return 'Moderate Load';
    return 'Overloaded';
  }

  void _navigateToMechanicTasks(String mechanicName) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MechanicTasksDetailScreen(
          mechanicName: mechanicName,
        ),
      ),
    );
  }
}
