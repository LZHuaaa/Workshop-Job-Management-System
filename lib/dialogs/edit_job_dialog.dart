import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../widgets/custom_dialog.dart';
import '../models/job_appointment.dart';

class EditJobDialog extends StatefulWidget {
  final JobAppointment job;
  final Function(JobAppointment) onJobUpdated;

  const EditJobDialog({
    super.key,
    required this.job,
    required this.onJobUpdated,
  });

  @override
  State<EditJobDialog> createState() => _EditJobDialogState();
}

class _EditJobDialogState extends State<EditJobDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _vehicleController;
  late TextEditingController _customerController;
  late TextEditingController _serviceTypeController;
  late TextEditingController _notesController;
  late TextEditingController _estimatedCostController;

  late DateTime _selectedDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late JobStatus _selectedStatus;
  String? _selectedMechanic;
  bool _isLoading = false;

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

  @override
  void initState() {
    super.initState();
    
    // Initialize controllers with existing job data
    _vehicleController = TextEditingController(text: widget.job.vehicleInfo);
    _customerController = TextEditingController(text: widget.job.customerName);
    
    // Ensure service type is in the list
    final serviceType = _serviceTypes.contains(widget.job.serviceType) 
        ? widget.job.serviceType 
        : _serviceTypes.isNotEmpty ? _serviceTypes.first : '';
    _serviceTypeController = TextEditingController(text: serviceType);
    
    _notesController = TextEditingController(text: widget.job.notes ?? '');
    _estimatedCostController = TextEditingController(
      text: widget.job.estimatedCost?.toStringAsFixed(2) ?? ''
    );

    _selectedDate = DateTime(
      widget.job.startTime.year,
      widget.job.startTime.month,
      widget.job.startTime.day,
    );
    _startTime = TimeOfDay.fromDateTime(widget.job.startTime);
    _endTime = TimeOfDay.fromDateTime(widget.job.endTime);
    _selectedStatus = widget.job.status;
    // Ensure selected mechanic is in the list, otherwise set to null
    _selectedMechanic = _mechanics.contains(widget.job.mechanicName)
        ? widget.job.mechanicName
        : _mechanics.isNotEmpty ? _mechanics.first : null;
  }

  @override
  void dispose() {
    _vehicleController.dispose();
    _customerController.dispose();
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
            colorScheme: const ColorScheme.light(
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
            colorScheme: const ColorScheme.light(
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
          // Auto-adjust end time if it's before start time
          if (_endTime.hour < _startTime.hour || 
              (_endTime.hour == _startTime.hour && _endTime.minute <= _startTime.minute)) {
            _endTime = TimeOfDay(
              hour: (_startTime.hour + 1) % 24,
              minute: _startTime.minute,
            );
          }
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _updateJob() async {
    if (!_formKey.currentState!.validate()) return;

    // Show confirmation dialog
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Update Job',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        content: Text(
          'Are you sure you want to update this job?',
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
              'Update',
              style: GoogleFonts.poppins(
                color: AppColors.primaryPink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

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

      final updatedJob = widget.job.copyWith(
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

      widget.onJobUpdated(updatedJob);

      if (mounted) {
        Navigator.of(context).pop();
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
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomDialog(
      title: 'Edit Job',
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
            
            CustomTextField(
              label: 'Customer Name',
              hint: 'Enter customer name',
              controller: _customerController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter customer name';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: CustomDropdown<String>(
                    label: 'Service Type',
                    value: _serviceTypes.contains(_serviceTypeController.text)
                        ? _serviceTypeController.text
                        : null,
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

            // Date Selection
            GestureDetector(
              onTap: _selectDate,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.borderLight),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: AppColors.primaryPink,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Date: ${DateFormat('EEEE, MMMM d, y').format(_selectedDate)}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Time Selection
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selectTime(true),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.borderLight),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            color: AppColors.primaryPink,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Start: ${_startTime.format(context)}',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selectTime(false),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.borderLight),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            color: AppColors.primaryPink,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'End: ${_endTime.format(context)}',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Status Dropdown
            DropdownButtonFormField<JobStatus>(
              value: _selectedStatus,
              decoration: InputDecoration(
                labelText: 'Status',
                labelStyle: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.primaryPink),
                ),
              ),
              items: JobStatus.values.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(
                    status.name.toUpperCase(),
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value!;
                });
              },
            ),

            const SizedBox(height: 16),

            CustomTextField(
              label: 'Estimated Cost (RM)',
              hint: 'Enter estimated cost',
              controller: _estimatedCostController,
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 16),

            CustomTextField(
              label: 'Notes (Optional)',
              hint: 'Additional notes or instructions',
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
          text: 'Update Job',
          onPressed: _updateJob,
          isLoading: _isLoading,
        ),
      ],
    );
  }
}
