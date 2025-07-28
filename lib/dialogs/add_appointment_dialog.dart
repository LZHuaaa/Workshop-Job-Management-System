import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../widgets/custom_dialog.dart';
import '../models/job_appointment.dart';

class AddAppointmentDialog extends StatefulWidget {
  final DateTime selectedDate;
  final Function(JobAppointment) onAppointmentCreated;

  const AddAppointmentDialog({
    super.key,
    required this.selectedDate,
    required this.onAppointmentCreated,
  });

  @override
  State<AddAppointmentDialog> createState() => _AddAppointmentDialogState();
}

class _AddAppointmentDialogState extends State<AddAppointmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _customerController = TextEditingController();
  final _phoneController = TextEditingController();
  final _serviceTypeController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedVehicle;
  String? _selectedMechanic;
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay _endTime = TimeOfDay(hour: TimeOfDay.now().hour + 2, minute: 0);
  bool _isLoading = false;

  final List<String> _vehicles = [
    '2020 Honda Civic - ABC 1234',
    '2019 Toyota Camry - XYZ 5678',
    '2021 Ford Focus - DEF 9012',
    '2018 BMW 3 Series - GHI 3456',
    '2022 Nissan Altima - JKL 7890',
  ];

  final List<String> _mechanics = [
    'Mike Johnson',
    'Sarah Wilson',
    'Tom Davis',
    'Lisa Chen',
    'Robert Brown',
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
  void dispose() {
    _customerController.dispose();
    _phoneController.dispose();
    _serviceTypeController.dispose();
    _notesController.dispose();
    super.dispose();
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

  Future<void> _createAppointment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    final startDateTime = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
      _startTime.hour,
      _startTime.minute,
    );

    final endDateTime = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
      _endTime.hour,
      _endTime.minute,
    );

    final newAppointment = JobAppointment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      vehicleInfo: _selectedVehicle!,
      customerName: _customerController.text,
      mechanicName: _selectedMechanic!,
      startTime: startDateTime,
      endTime: endDateTime,
      serviceType: _serviceTypeController.text,
      status: JobStatus.scheduled,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
    );

    widget.onAppointmentCreated(newAppointment);

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Appointment scheduled successfully!',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: AppColors.successGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomDialog(
      title: 'Schedule Appointment',
      content: Form(
        key: _formKey,
        child: Column(
          children: [
            // Date Display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.softPink,
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
                    'Date: ${DateFormat('EEEE, MMMM d, y').format(widget.selectedDate)}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            CustomDropdown<String>(
              label: 'Vehicle',
              value: _selectedVehicle,
              items: _vehicles.map((vehicle) {
                return DropdownMenuItem(
                  value: vehicle,
                  child: Text(vehicle),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedVehicle = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select a vehicle';
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
                    hint: '(555) 123-4567',
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
                    value: _serviceTypeController.text.isEmpty ? null : _serviceTypeController.text,
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

            // Time Selection
            Row(
              children: [
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
                                Icons.access_time,
                                color: AppColors.textDark,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _startTime.format(context),
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
                                Icons.access_time,
                                color: AppColors.textDark,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _endTime.format(context),
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
              ],
            ),
            const SizedBox(height: 16),

            CustomTextField(
              label: 'Notes (Optional)',
              hint: 'Additional information...',
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
          text: 'Schedule',
          onPressed: _createAppointment,
          isLoading: _isLoading,
        ),
      ],
    );
  }
}
