import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../widgets/dashboard_card.dart';
import '../models/job_appointment.dart';
import '../services/job_appointment_service.dart';

class MechanicTasksDetailScreen extends StatefulWidget {
  final String mechanicName;

  const MechanicTasksDetailScreen({
    super.key,
    required this.mechanicName,
  });

  @override
  State<MechanicTasksDetailScreen> createState() => _MechanicTasksDetailScreenState();
}

class _MechanicTasksDetailScreenState extends State<MechanicTasksDetailScreen> {
  final JobAppointmentService _jobService = JobAppointmentService();
  List<JobAppointment> _mechanicTasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMechanicTasks();
  }

  void _loadMechanicTasks() {
    _jobService.getAppointmentsStream().listen((allJobs) {
      if (mounted) {
        setState(() {
          _mechanicTasks = allJobs
              .where((job) => job.mechanicName == widget.mechanicName)
              .toList();
          // Sort by start time
          _mechanicTasks.sort((a, b) => a.startTime.compareTo(b.startTime));
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          '${widget.mechanicName} - Tasks',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryPink,
              ),
            )
          : SafeArea(
              child: Column(
                children: [
                  // Header with task summary
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Tasks',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                '${_mechanicTasks.length}',
                                style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryPink,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Completed',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                '${_mechanicTasks.where((task) => task.status == JobStatus.completed).length}',
                                style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.successGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'In Progress',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                '${_mechanicTasks.where((task) => task.status == JobStatus.inProgress).length}',
                                style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Task list
                  Expanded(
                    child: _mechanicTasks.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.assignment_outlined,
                                  size: 64,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No tasks assigned',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'This mechanic has no current task assignments',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _mechanicTasks.length,
                            itemBuilder: (context, index) {
                              final task = _mechanicTasks[index];
                              return _buildTaskCard(task);
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTaskCard(JobAppointment task) {
    final statusColor = _getStatusColor(task.status);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: DashboardCard(
        title: '', // Empty title since we don't need a title for individual task cards
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with vehicle info and status
            Row(
              children: [
                Expanded(
                  child: Text(
                    task.vehicleInfo,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    task.status.name.toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Service type
            Text(
              task.serviceType,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.primaryPink,
              ),
            ),

            const SizedBox(height: 8),

            // Customer name
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  task.customerName,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Date and time
            Row(
              children: [
                Icon(
                  Icons.schedule_outlined,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  '${DateFormat('MMM d, yyyy').format(task.startTime)} • ${DateFormat('h:mm a').format(task.startTime)} - ${DateFormat('h:mm a').format(task.endTime)}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),

            // Notes (if available)
            if (task.notes != null && task.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.note_outlined,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      task.notes!,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // Estimated cost (if available)
            if (task.estimatedCost != null && task.estimatedCost! > 0) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.attach_money_outlined,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Estimated: RM ${task.estimatedCost!.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
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

  Color _getStatusColor(JobStatus status) {
    switch (status) {
      case JobStatus.scheduled:
        return Colors.blue;
      case JobStatus.inProgress:
        return Colors.orange;
      case JobStatus.completed:
        return AppColors.successGreen;
      case JobStatus.cancelled:
        return AppColors.errorRed;
    }
  }
}
