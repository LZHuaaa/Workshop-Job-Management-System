import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../widgets/dashboard_card.dart';
import '../models/job_appointment.dart';
import '../screens/job_details_screen.dart';
import '../dialogs/new_job_dialog.dart';
import '../dialogs/edit_job_dialog.dart';
import '../services/job_appointment_service.dart';

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  String _selectedFilter = 'All';
  final TextEditingController _searchController = TextEditingController();
  final JobAppointmentService _jobService = JobAppointmentService();

  final List<String> _filterOptions = [
    'All',
    'Scheduled',
    'In Progress',
    'Completed',
    'Overdue',
  ];

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

          // ✅ Always sort jobs by latest startTime first
          _allJobs.sort((a, b) => b.startTime.compareTo(a.startTime));

          _isLoading = false;
        });
      }
    });
  }

  List<JobAppointment> get _filteredJobs {
    List<JobAppointment> filtered = _allJobs;

    if (_selectedFilter != 'All') {
      if (_selectedFilter == 'Overdue') {
        filtered = filtered.where((job) => job.isOverdue).toList();
      } else {
        final status = JobStatus.values.firstWhere(
          (s) => s.name.toLowerCase() ==
              _selectedFilter.toLowerCase().replaceAll(' ', ''),
        );
        filtered =
            filtered.where((job) => job.status == status && !job.isOverdue).toList();
      }
    }

    if (_searchController.text.isNotEmpty) {
      final searchTerm = _searchController.text.toLowerCase();
      filtered = filtered
          .where((job) =>
              job.vehicleInfo.toLowerCase().contains(searchTerm) ||
              job.customerName.toLowerCase().contains(searchTerm) ||
              job.mechanicName.toLowerCase().contains(searchTerm) ||
              job.serviceType.toLowerCase().contains(searchTerm))
          .toList();
    }

    return filtered;
  }

  Future<void> _updateJob(JobAppointment updatedJob) async {
    try {
      await _jobService.updateAppointment(updatedJob);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Job updated successfully!',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to update job: ${e.toString()}',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _deleteJob(JobAppointment job) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Job',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this job for ${job.customerName}? This action cannot be undone.',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(
                color: AppColors.errorRed,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _jobService.deleteAppointment(job.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Job deleted successfully!',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: AppColors.successGreen,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to delete job: ${e.toString()}',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: AppColors.errorRed,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.primaryPink,
          ),
        ),
      );
    }

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
                        'Jobs',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => NewJobDialog(
                              onJobCreated: (job) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Job created successfully!',
                                        style: GoogleFonts.poppins(),
                                      ),
                                      backgroundColor: AppColors.successGreen,
                                    ),
                                  );
                                }
                              },
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryPink.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.primaryPink.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add,
                                  size: 18, color: AppColors.primaryPink),
                              const SizedBox(width: 4),
                              Text(
                                'New Job',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: AppColors.primaryPink,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Search
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Search jobs, customers, or vehicles...',
                        hintStyle: GoogleFonts.poppins(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                        prefixIcon:
                            Icon(Icons.search, color: AppColors.textSecondary),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Filter chips
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _filterOptions.length,
                      itemBuilder: (context, index) {
                        final filter = _filterOptions[index];
                        final isSelected = filter == _selectedFilter;

                        // ✅ Show count only for All
                        String label = filter;
                        if (filter == 'All') {
                          label = 'All (${_allJobs.length})';
                        }

                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(
                              label,
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

            // Jobs list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: _filteredJobs.length,
                itemBuilder: (context, index) {
                  final job = _filteredJobs[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildJobCard(job),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobCard(JobAppointment job) {
    final now = DateTime.now();
    final isOverdue =
        job.startTime.isBefore(now) && job.status != JobStatus.completed;
    final isOvertime =
        job.status == JobStatus.inProgress && job.endTime.isBefore(now);

    return GestureDetector(
      onTap: () => _showJobDetails(job),
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.vehicleInfo,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          job.serviceType,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(job.status),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      job.status.name.toUpperCase(),
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

              if (isOverdue) ...[
                Text(
                  "⚠️ This job is overdue. Please reschedule, complete, or cancel.",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.errorRed,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
              ] else if (isOvertime) ...[
                Text(
                  "⏳ This job is in progress but past its expected time.",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
              ],

              Row(
                children: [
                  Icon(Icons.person, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    job.customerName,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.build, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    job.mechanicName,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    '${DateFormat('MMM d, h:mm a').format(job.startTime)} - ${DateFormat('h:mm a').format(job.endTime)}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  if (job.estimatedCost != null)
                    Text(
                      'RM${job.estimatedCost!.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryPink,
                      ),
                    ),
                ],
              ),
              if (job.partsNeeded != null && job.partsNeeded!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: job.partsNeeded!
                      .map((part) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.softPink,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              part,
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: AppColors.primaryPink,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ],

              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () => _showEditJobDialog(job),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryPink.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.primaryPink.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit,
                              size: 16, color: AppColors.primaryPink),
                          const SizedBox(width: 4),
                          Text(
                            'Edit',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primaryPink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _deleteJob(job),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.errorRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.errorRed.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.delete,
                              size: 16, color: AppColors.errorRed),
                          const SizedBox(width: 4),
                          Text(
                            'Delete',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.errorRed,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
      case JobStatus.overdue:
        return AppColors.errorRed;
    }
  }

  void _showJobDetails(JobAppointment job) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => JobDetailsScreen(
          job: job,
          onJobUpdated: _updateJob,
        ),
      ),
    );
  }

  void _showEditJobDialog(JobAppointment job) {
    showDialog(
      context: context,
      builder: (context) => EditJobDialog(
        job: job,
        onJobUpdated: _updateJob,
      ),
    );
  }
}
