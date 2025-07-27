import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../widgets/custom_dialog.dart';
import '../models/customer.dart';

class AddCommunicationDialog extends StatefulWidget {
  final Customer customer;
  final Function(CommunicationLog) onCommunicationAdded;

  const AddCommunicationDialog({
    super.key,
    required this.customer,
    required this.onCommunicationAdded,
  });

  @override
  State<AddCommunicationDialog> createState() => _AddCommunicationDialogState();
}

class _AddCommunicationDialogState extends State<AddCommunicationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _contentController = TextEditingController();

  String _selectedType = 'call';
  String _selectedDirection = 'outbound';
  String? _selectedStaffMember;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  final List<String> _communicationTypes = [
    'call',
    'email',
    'text',
    'in-person'
  ];
  final List<String> _directions = ['inbound', 'outbound'];
  final List<String> _staffMembers = [
    'Ahmad bin Hassan',
    'Siti Nurhaliza',
    'Lim Wei Ming',
    'Raj Kumar',
    'Muhammad Faiz bin Omar',
    'Tan Mei Ling',
    'Priya d/o Raman',
  ];

  @override
  void dispose() {
    _subjectController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _addCommunication() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    final newCommunication = CommunicationLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: _selectedDate,
      type: _selectedType,
      subject: _subjectController.text,
      content: _contentController.text,
      direction: _selectedDirection,
      staffMember: _selectedStaffMember,
    );

    widget.onCommunicationAdded(newCommunication);

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Communication logged successfully!',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: AppColors.successGreen,
        ),
      );
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
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

    if (picked != null && picked != _selectedDate && mounted) {
      final TimeOfDay? timePicked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
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

      if (timePicked != null && mounted) {
        setState(() {
          _selectedDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            timePicked.hour,
            timePicked.minute,
          );
        });
      }
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'call':
        return Icons.phone;
      case 'email':
        return Icons.email;
      case 'text':
        return Icons.sms;
      case 'in-person':
        return Icons.person;
      default:
        return Icons.chat;
    }
  }

  Color _getDirectionColor(String direction) {
    return direction == 'inbound' ? AppColors.infoBlue : AppColors.primaryPink;
  }

  @override
  Widget build(BuildContext context) {
    return CustomDialog(
      title: 'Log Communication',
      width: MediaQuery.of(context).size.width * 0.92,
      height: MediaQuery.of(context).size.height * 0.75,
      content: LayoutBuilder(
        builder: (context, constraints) {
          return Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Communication Type and Direction
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Communication Type',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.textLight),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: DropdownButtonFormField<String>(
                              value: _selectedType,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                              ),
                              items: _communicationTypes.map((type) {
                                return DropdownMenuItem(
                                  value: type,
                                  child: Row(
                                    children: [
                                      Icon(
                                        _getTypeIcon(type),
                                        size: 18,
                                        color: AppColors.primaryPink,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        type.toUpperCase(),
                                        style:
                                            GoogleFonts.poppins(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedType = value!;
                                });
                              },
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
                            'Direction',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.textLight),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: DropdownButtonFormField<String>(
                              value: _selectedDirection,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                              ),
                              items: _directions.map((direction) {
                                return DropdownMenuItem(
                                  value: direction,
                                  child: Row(
                                    children: [
                                      Icon(
                                        direction == 'inbound'
                                            ? Icons.call_received
                                            : Icons.call_made,
                                        size: 18,
                                        color: _getDirectionColor(direction),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        direction.toUpperCase(),
                                        style:
                                            GoogleFonts.poppins(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedDirection = value!;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Date and Staff Member
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Date & Time',
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
                                  horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.textLight),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 18,
                                    color: AppColors.primaryPink,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    DateFormat('MMM d, y - h:mm a')
                                        .format(_selectedDate),
                                    style: GoogleFonts.poppins(fontSize: 14),
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
                            'Staff Member',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.textLight),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: DropdownButtonFormField<String>(
                              value: _selectedStaffMember,
                              hint: Text(
                                'Select staff member',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                              ),
                              items: _staffMembers.map((staff) {
                                return DropdownMenuItem(
                                  value: staff,
                                  child: Text(
                                    staff,
                                    style: GoogleFonts.poppins(fontSize: 14),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedStaffMember = value;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Subject
                CustomTextField(
                  label: 'Subject',
                  hint: 'Brief description of the communication...',
                  controller: _subjectController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a subject';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Content
                CustomTextField(
                  label: 'Details',
                  hint: 'Detailed notes about the communication...',
                  controller: _contentController,
                  maxLines: 4,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter communication details';
                    }
                    return null;
                  },
                ),
              ],
            ),
          );
        },
      ),
      actions: [
        SecondaryButton(
          text: 'Cancel',
          onPressed: () => Navigator.of(context).pop(),
        ),
        PrimaryButton(
          text: 'Log Communication',
          onPressed: _addCommunication,
          isLoading: _isLoading,
        ),
      ],
    );
  }
}
