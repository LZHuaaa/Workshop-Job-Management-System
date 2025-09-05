import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_colors.dart';
import '../widgets/custom_dialog.dart';
import '../models/job_appointment.dart';
import 'new_service_record_dialog.dart';

class NewJobDialog extends StatefulWidget {
  final Function(JobAppointment) onJobCreated;
  final String? vehicleInfo;
  final String? customerName;
  final String? phoneNumber;
  final String? initialMechanic;

  const NewJobDialog({
    super.key,
    required this.onJobCreated,
    this.vehicleInfo,
    this.customerName,
    this.phoneNumber,
    this.initialMechanic,
  });

  @override
  State<NewJobDialog> createState() => _NewJobDialogState();
}

class _NewJobDialogState extends State<NewJobDialog> {
  final _formKey = GlobalKey<FormState>();
  final _vehicleController = TextEditingController();
  final _customerController = TextEditingController();
  final _phoneController = TextEditingController();
  final _serviceTypeController = TextEditingController();
  final _notesController = TextEditingController();
  final _estimatedCostController = TextEditingController();

  String? _selectedMechanic;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay _endTime = TimeOfDay(hour: TimeOfDay.now().hour + 2, minute: 0);
  JobStatus _selectedStatus = JobStatus.scheduled;

  final List<String> _mechanics = [
    'Lee Chong Wei',
    'Priya a/p Devi',
    'Ravi a/l Kumar',
    'Ahmad bin Razak',
    'Salmah binti Inrahim',
    'Wong Ah Beng',
    'Zainab binti Omar',
    'Chen Wei Liang',
  ];

  final List<String> _serviceTypes = [
    'Oil Change',
    'Brake Service',
    'Transmission Service',
    'Engine Repair',
    'Tire Replacement',
    'Battery Replacement',
    'Air Conditioning',
    'Electrical Repair',
    'Suspension Repair',
    'General Inspection',
  ];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.vehicleInfo != null) {
      _vehicleController.text = widget.vehicleInfo!;
    }
    if (widget.customerName != null) {
      _customerController.text = widget.customerName!;
    }
    if (widget.phoneNumber != null) {
      _phoneController.text = widget.phoneNumber!;
    }
    if (widget.initialMechanic != null) {
      _selectedMechanic = widget.initialMechanic!;
    }
  }

  @override
  void dispose() {
    _vehicleController.dispose();
    _customerController.dispose();
    _phoneController.dispose();
    _serviceTypeController.dispose();
    _notesController.dispose();
    _estimatedCostController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryPink,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTime : _endTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryPink,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
          // Automatically set end time to 2 hours later
          _endTime = TimeOfDay(
            hour: (picked.hour + 2) % 24,
            minute: picked.minute,
          );
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _createJob() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final startDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _startTime.hour,
        _startTime.minute,
      );

      final endDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _endTime.hour,
        _endTime.minute,
      );

      // Create job in Firestore
      final docRef = await FirebaseFirestore.instance.collection('appointments').add({
        'vehicleInfo': _vehicleController.text,
        'customerName': _customerController.text,
        'mechanicName': _selectedMechanic!,
        'startTime': Timestamp.fromDate(startDateTime),
        'endTime': Timestamp.fromDate(endDateTime),
        'serviceType': _serviceTypeController.text,
        'status': _selectedStatus.name,
        'notes': _notesController.text.isEmpty ? null : _notesController.text,
        'estimatedCost': _estimatedCostController.text.isEmpty
            ? null
            : double.tryParse(_estimatedCostController.text),
      });

      // Update with the document ID
      await docRef.update({'id': docRef.id});

      final newJob = JobAppointment(
        id: docRef.id,
        vehicleInfo: _vehicleController.text,
        customerName: _customerController.text,
        mechanicName: _selectedMechanic!,
        startTime: startDateTime,
        endTime: endDateTime,
        serviceType: _serviceTypeController.text,
        status: _selectedStatus,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        estimatedCost: _estimatedCostController.text.isEmpty
            ? null
            : double.tryParse(_estimatedCostController.text),
      );

      widget.onJobCreated(newJob);

      // If the status is completed, show service record dialog
      if (_selectedStatus == JobStatus.completed && mounted) {
        await showDialog(
          context: context,
          builder: (context) => NewServiceRecordDialog(job: newJob),
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error creating job: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomDialog(
      title: 'Create New Job',
      content: Form(
        key: _formKey,
        child: Column(
          children: [
            CustomTextField(
              label: 'Vehicle Information',
              hint: 'e.g., 2020 Honda Civic - ABC 1234',
              controller: _vehicleController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter vehicle information';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    label: 'Customer Name',
                    hint: 'Full name',
                    controller: _customerController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter customer name';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomTextField(
                    label: 'Phone Number',
                    hint: '0123456789',
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: CustomDropdown<String>(
                    label: 'Service Type',
                    value: _serviceTypeController.text.isEmpty
                        ? null
                        : _serviceTypeController.text,
                    items: _serviceTypes.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _serviceTypeController.text = value ?? '';
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select service type';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomDropdown<String>(
                    label: 'Assigned Mechanic',
                    value: _selectedMechanic,
                    items: _mechanics.map((mechanic) {
                      return DropdownMenuItem(
                        value: mechanic,
                        child: Text(mechanic),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedMechanic = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Please select mechanic';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Date and Time Selection
            Row(
              children: [
                // Date Field
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Date',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _selectDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.textSecondary.withOpacity(0.3),
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                color: AppColors.primaryPink,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                DateFormat('MMM d, y').format(_selectedDate),
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // Start Time Field
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Start Time',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _selectTime(true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.textSecondary.withOpacity(0.3),
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              _startTime.format(context),
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: AppColors.textDark,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // End Time Field
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'End Time',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _selectTime(false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.textSecondary.withOpacity(0.3),
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              _endTime.format(context),
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: AppColors.textDark,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: CustomDropdown<JobStatus>(
                    label: 'Status',
                    value: _selectedStatus,
                    items: JobStatus.values.map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(status.name.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedStatus = value!;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomTextField(
                    label: 'Estimated Cost (RM)',
                    hint: '0.00',
                    controller: _estimatedCostController,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            CustomTextField(
              label: 'Notes (Optional)',
              hint: 'Additional information about the job...',
              controller: _notesController,
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        SecondaryButton(
          text: 'Cancel',
          onPressed: () => Navigator.of(context).pop(),
        ),
        PrimaryButton(
          text: 'Create Job',
          onPressed: _createJob,
          isLoading: _isLoading,
        ),
      ],
    );
  }
}
