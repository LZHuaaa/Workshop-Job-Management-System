import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/job_appointment.dart';
import '../models/service_details.dart';
import '../theme/app_colors.dart';
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
      // Try to get actual IDs from the job first, otherwise look them up
      String? vehicleId = widget.job.vehicleId;
      String? customerId = widget.job.customerId;
      
      print('🔍 Job has Vehicle ID: $vehicleId, Customer ID: $customerId');
      
      // If we don't have the IDs in the job, look them up from display names
      if (vehicleId == null || customerId == null) {
        print('🔍 Looking up IDs from display info: ${widget.job.vehicleInfo}');
        
        try {
          // First, try to extract license plate from vehicleInfo (format: "YYYY Make Model - LicensePlate")
          String? licensePlate;
          if (widget.job.vehicleInfo.contains(' - ')) {
            licensePlate = widget.job.vehicleInfo.split(' - ').last.trim();
            print('🔍 Extracted license plate: $licensePlate');
            
            // Query vehicles by license plate
            final vehicleQuery = await FirebaseFirestore.instance
                .collection('vehicles')
                .where('licensePlate', isEqualTo: licensePlate)
                .limit(1)
                .get();
            
            if (vehicleQuery.docs.isNotEmpty) {
              vehicleId = vehicleQuery.docs.first.id;
              customerId = vehicleQuery.docs.first.data()['customerId'];
              print('✅ Found vehicle by license plate - Vehicle ID: $vehicleId, Customer ID: $customerId');
            }
          }
          
          // If we couldn't find by license plate, try to find by matching the full display name
          if (vehicleId == null) {
            print('🔍 Trying full display name search...');
            final allVehicles = await FirebaseFirestore.instance
                .collection('vehicles')
                .get();
            
            for (final doc in allVehicles.docs) {
              final data = doc.data();
              final displayName = '${data['year']} ${data['make']} ${data['model']} - ${data['licensePlate']}';
              if (displayName == widget.job.vehicleInfo) {
                vehicleId = doc.id;
                customerId = data['customerId'];
                print('✅ Found vehicle by display name match - Vehicle ID: $vehicleId, Customer ID: $customerId');
                break;
              }
            }
          }
        } catch (e) {
          print('❌ Error looking up vehicle ID: $e');
        }
      }
      
      // If still no vehicle ID found, use the job info as fallback (for backwards compatibility)
      if (vehicleId == null) {
        print('⚠️ Could not find vehicle ID, using fallback values');
        vehicleId = widget.job.vehicleInfo;
        customerId = widget.job.customerName;
      } else {
        // Double-check that the customer ID is valid if we looked it up
        if (widget.job.customerId == null && customerId != null) {
          try {
            final customerDoc = await FirebaseFirestore.instance
                .collection('customers')
                .doc(customerId)
                .get();
            
            if (!customerDoc.exists) {
              print('⚠️ Customer ID $customerId does not exist, using fallback');
              customerId = widget.job.customerName;
            } else {
              print('✅ Customer ID $customerId verified');
            }
          } catch (e) {
            print('⚠️ Error verifying customer ID: $e');
          }
        }
        
        print('✅ Using IDs - Vehicle: $vehicleId, Customer: $customerId');
      }

      // Create a new service record
      final serviceRecord = {
        'cost': _cost,
        'customerId': customerId,
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
        'vehicleId': vehicleId,
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
      // ✅ UPDATE VEHICLE MILEAGE: Update the vehicle's current mileage with the service record mileage
      if (vehicleId.isNotEmpty && !vehicleId.startsWith('unknown')) {
        try {
          final newMileage = int.parse(_mileageController.text);
          
          // Get current vehicle data to check existing mileage
          final vehicleDoc = await FirebaseFirestore.instance
              .collection('vehicles')
              .doc(vehicleId)
              .get();
          
          if (vehicleDoc.exists) {
            final currentVehicleMileage = vehicleDoc.data()?['mileage'] ?? 0;
            
            // Update if new mileage is higher or equal (service should never decrease mileage)
            if (newMileage >= currentVehicleMileage) {
              await FirebaseFirestore.instance
                  .collection('vehicles')
                  .doc(vehicleId)
                  .update({
                    'mileage': newMileage,
                    'lastUpdated': Timestamp.fromDate(DateTime.now()),
                  });
              print('✅ Updated vehicle $vehicleId mileage from $currentVehicleMileage to $newMileage km');
            } else {
              print('⚠️ New mileage ($newMileage) is less than current mileage ($currentVehicleMileage). Skipping update.');
            }
          } else {
            print('⚠️ Vehicle document $vehicleId not found. Cannot update mileage.');
          }
        } catch (e) {
          print('⚠️ Error updating vehicle mileage: $e');
          // Don't fail the service record creation if mileage update fails
        }
      }

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
                // Update service record with next service due date
                // The job is already saved by the NewJobDialog
                await FirebaseFirestore.instance
                    .collection('service_records')
                    .doc(serviceRecordId)
                    .update({
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

        // Show final success message and return success
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
          
          // Pop with success result to notify parent
          Navigator.of(context).pop(true);
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
