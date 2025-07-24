import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../widgets/dashboard_card.dart';
import '../models/job_appointment.dart';

class JobDetailsScreen extends StatefulWidget {
  final JobAppointment job;
  final Function(JobAppointment) onJobUpdated;

  const JobDetailsScreen({
    super.key,
    required this.job,
    required this.onJobUpdated,
  });

  @override
  State<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen> {
  late JobAppointment _currentJob;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _currentJob = widget.job;
  }

  Future<void> _updateJobStatus(JobStatus newStatus) async {
    setState(() {
      _isUpdating = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    final updatedJob = _currentJob.copyWith(status: newStatus);

    setState(() {
      _currentJob = updatedJob;
      _isUpdating = false;
    });

    widget.onJobUpdated(updatedJob);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Job status updated to ${newStatus.name.toUpperCase()}',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: AppColors.successGreen,
      ),
    );
  }

  Color _getStatusColor(JobStatus status) {
    switch (status) {
      case JobStatus.scheduled:
        return AppColors.accentPink;
      case JobStatus.inProgress:
        return AppColors.primaryPink;
      case JobStatus.completed:
        return AppColors.successGreen;
      case JobStatus.cancelled:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Job Details',
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Job Header Card
            DashboardCard(
              title: 'Job Information',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _currentJob.vehicleInfo,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getStatusColor(_currentJob.status),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _currentJob.status.name.toUpperCase(),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                      Icons.build, 'Service Type', _currentJob.serviceType),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                      Icons.person, 'Customer', _currentJob.customerName),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                      Icons.engineering, 'Mechanic', _currentJob.mechanicName),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.schedule,
                    'Scheduled Time',
                    '${DateFormat('MMM d, y • h:mm a').format(_currentJob.startTime)} - ${DateFormat('h:mm a').format(_currentJob.endTime)}',
                  ),
                  if (_currentJob.estimatedCost != null) ...[
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      Icons.attach_money,
                      'Estimated Cost',
                      'RM${_currentJob.estimatedCost!.toStringAsFixed(2)}',
                    ),
                  ],
                  if (_currentJob.notes != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Notes',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.softPink,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _currentJob.notes!,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Parts Needed Card
            if (_currentJob.partsNeeded != null &&
                _currentJob.partsNeeded!.isNotEmpty)
              DashboardCard(
                title: 'Parts Required',
                child: Column(
                  children: _currentJob.partsNeeded!
                      .map((part) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.inventory_2,
                                  color: AppColors.primaryPink,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    part,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.check_circle,
                                  color: AppColors.successGreen,
                                  size: 20,
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),

            const SizedBox(height: 20),

            // Status Update Card
            DashboardCard(
              title: 'Update Job Status',
              child: Column(
                children: [
                  Text(
                    'Current Status: ${_currentJob.status.name.toUpperCase()}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_currentJob.status == JobStatus.scheduled) ...[
                    _buildStatusButton(
                      'Start Job',
                      Icons.play_arrow,
                      AppColors.primaryPink,
                      () => _updateJobStatus(JobStatus.inProgress),
                    ),
                    const SizedBox(height: 12),
                    _buildStatusButton(
                      'Cancel Job',
                      Icons.cancel,
                      AppColors.errorRed,
                      () => _updateJobStatus(JobStatus.cancelled),
                    ),
                  ] else if (_currentJob.status == JobStatus.inProgress) ...[
                    _buildStatusButton(
                      'Complete Job',
                      Icons.check_circle,
                      AppColors.successGreen,
                      () => _updateJobStatus(JobStatus.completed),
                    ),
                    const SizedBox(height: 12),
                    _buildStatusButton(
                      'Cancel Job',
                      Icons.cancel,
                      AppColors.errorRed,
                      () => _updateJobStatus(JobStatus.cancelled),
                    ),
                  ] else if (_currentJob.status == JobStatus.completed) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.successGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: AppColors.successGreen,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Job completed successfully!',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.successGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else if (_currentJob.status == JobStatus.cancelled) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.errorRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.cancel,
                            color: AppColors.errorRed,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Job was cancelled',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.errorRed,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: AppColors.primaryPink,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusButton(
      String text, IconData icon, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isUpdating ? null : onPressed,
        icon: _isUpdating
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Icon(icon, size: 18),
        label: Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
