import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_colors.dart';
import '../models/job_appointment.dart';
import '../models/service_details.dart';
import 'new_job_dialog.dart';

class NewServiceRecordDialog extends StatefulWidget {
  final JobAppointment job;
  const NewServiceRecordDialog({
    super.key,
    required this.job,
  });

  @override
  State<NewServiceRecordDialog> createState() => _NewServiceRecordDialogState();
}

class _NewServiceRecordDialogState extends State<NewServiceRecordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _mileageController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isLoading = false;
  double _cost = 0;
  List<String> _selectedServices = [];
  List<String> _selectedParts = [];
  late ServiceInfo _serviceInfo;
  late DateTime _nextServiceDate;

  @override
  void initState() {
    super.initState();
    _serviceInfo = ServiceMappings.services[widget.job.serviceType] ?? ServiceMappings.services['General Service']!;
    // Set cost from appointment data
    _cost = widget.job.estimatedCost ?? _serviceInfo.defaultPrice;
    _nextServiceDate = DateTime.now().add(Duration(days: _serviceInfo.nextServiceMonths * 30));
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _mileageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveServiceRecord() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Create a new service record
      final serviceRecord = {
        'cost': _cost,
        'customerId': widget.job.customerName,
        'description': _descriptionController.text,
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'mechanicName': widget.job.mechanicName,
        'mileage': int.parse(_mileageController.text),
        'nextServiceDue': Timestamp.fromDate(_nextServiceDate),
        'notes': _notesController.text,
        'partsReplaced': _selectedParts,
        'serviceDate': Timestamp.fromDate(DateTime.now()),
        'serviceType': widget.job.serviceType,
        'servicesPerformed': _selectedServices,
        'status': 'completed',
        'vehicleId': widget.job.vehicleInfo,
        'previousAppointmentId': widget.job.id, // Link to the appointment that created this service
        'nextAppointmentId': null, // Will be updated after creating next appointment
      };

      // Save to Firebase
      final serviceRecordRef = await FirebaseFirestore.instance
          .collection('service_records')
          .add(serviceRecord);
      
      final String serviceRecordId = serviceRecordRef.id;
      
      // Update service record with its ID
      await serviceRecordRef.update({
        'id': serviceRecordId,
        'appointmentId': widget.job.id, // Link to the original appointment
      });

      // Update original appointment with completed status and link to service record
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(widget.job.id)
          .update({
            'status': JobStatus.completed.name,
            'serviceRecordId': serviceRecordId,
            'completedDate': Timestamp.fromDate(DateTime.now()),
          });

      if (mounted) {
        // Close the current dialog
        Navigator.of(context).pop(true);
        
        // Show new job dialog for next appointment with pre-filled data
        await showDialog(
          context: context,
          builder: (context) => NewJobDialog(
            vehicleInfo: widget.job.vehicleInfo,
            customerName: widget.job.customerName,
            initialMechanic: widget.job.mechanicName,
            onJobCreated: (job) async {
              try {
                // First save the new appointment
                final nextAppointmentRef = await FirebaseFirestore.instance.collection('appointments').add({
                  'vehicleInfo': job.vehicleInfo,
                  'customerName': job.customerName,
                  'mechanicName': job.mechanicName,
                  'startTime': Timestamp.fromDate(job.startTime),
                  'endTime': Timestamp.fromDate(job.endTime),
                  'serviceType': job.serviceType,
                  'status': job.status.name,
                  'notes': job.notes,
                  'estimatedCost': job.estimatedCost,
                  'id': DateTime.now().millisecondsSinceEpoch.toString(),
                  'isNextService': true,
                  'previousServiceId': widget.job.id, // Link to previous service
                });

                final nextAppointmentId = nextAppointmentRef.id;
                await nextAppointmentRef.update({'id': nextAppointmentId});

                // Update service record with next appointment reference
                await FirebaseFirestore.instance
                    .collection('service_records')
                    .doc(serviceRecordId) // We'll define this variable
                    .update({
                  'nextAppointmentId': nextAppointmentId,
                  'nextServiceDue': Timestamp.fromDate(job.startTime),
                });

                // Show success message
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Next service appointment scheduled successfully!',
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
                        'Error scheduling next appointment: $e',
                        style: GoogleFonts.poppins(),
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
        );

        // Show final success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Service record saved successfully!',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: AppColors.successGreen,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error saving service record: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Service Record',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 20),

                // Service Description
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Service Description',
                    hintText: 'Enter service description',
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Please enter description' : null,
                ),
                const SizedBox(height: 16),

                // Mileage
                TextFormField(
                  controller: _mileageController,
                  decoration: const InputDecoration(
                    labelText: 'Current Mileage',
                    hintText: 'Enter current mileage',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Please enter mileage' : null,
                ),
                const SizedBox(height: 16),

                // Cost
                TextFormField(
                  initialValue: _cost.toString(),
                  decoration: InputDecoration(
                    labelText: 'Service Cost',
                    hintText: 'Cost from appointment',
                    prefixText: 'RM ',
                    filled: true,
                    fillColor: Colors.grey[200],
                  ),
                  enabled: false, // Disable editing
                  style: GoogleFonts.poppins(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),

                // Services Performed
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Services Performed',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _serviceInfo.servicesToPerform.map((service) {
                        final isSelected = _selectedServices.contains(service);
                        return FilterChip(
                          label: Text(service),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedServices.add(service);
                              } else {
                                _selectedServices.remove(service);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Parts Replaced
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Parts Replaced',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _serviceInfo.partsToReplace.map((part) {
                        final isSelected = _selectedParts.contains(part);
                        return FilterChip(
                          label: Text(part),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedParts.add(part);
                              } else {
                                _selectedParts.remove(part);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Notes
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    hintText: 'Enter any additional notes',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(color: AppColors.textSecondary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveServiceRecord,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryPink,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Save Record',
                              style: GoogleFonts.poppins(color: Colors.white),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
