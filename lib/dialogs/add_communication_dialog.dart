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
    'Ahmad',
    'Siti',
    'Lim Wei Ming',
    'Raj',
    'Faiz',
    'Mei Ling',
    'Priya',
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
      width: MediaQuery.of(context).size.width * 0.9,
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type and Direction in compact row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Type',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.textLight),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedType,
                              isExpanded: true,
                              items: _communicationTypes.map((type) {
                                return DropdownMenuItem(
                                  value: type,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _getTypeIcon(type),
                                        size: 14,
                                        color: AppColors.primaryPink,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        type.toUpperCase(),
                                        style:
                                            GoogleFonts.poppins(fontSize: 11),
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
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Direction',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.textLight),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedDirection,
                              isExpanded: true,
                              items: _directions.map((direction) {
                                return DropdownMenuItem(
                                  value: direction,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        direction == 'inbound'
                                            ? Icons.call_received
                                            : Icons.call_made,
                                        size: 14,
                                        color: _getDirectionColor(direction),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        direction.toUpperCase(),
                                        style:
                                            GoogleFonts.poppins(fontSize: 11),
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
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Date and Staff in compact row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Date',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: _selectDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.textLight),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 14,
                                  color: AppColors.primaryPink,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    DateFormat('MMM d').format(_selectedDate),
                                    style: GoogleFonts.poppins(fontSize: 11),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Staff',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.textLight),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedStaffMember,
                              isExpanded: true,
                              hint: Text(
                                'Select',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              items: _staffMembers.map((staff) {
                                return DropdownMenuItem(
                                  value: staff,
                                  child: Text(
                                    staff,
                                    style: GoogleFonts.poppins(fontSize: 11),
                                    overflow: TextOverflow.ellipsis,
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
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Subject
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Subject',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: _subjectController,
                    style: GoogleFonts.poppins(fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'Brief description...',
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppColors.textLight),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a subject';
                      }
                      return null;
                    },
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Details
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Details',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: _contentController,
                    maxLines: 3,
                    style: GoogleFonts.poppins(fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'Communication details...',
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppColors.textLight),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter details';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
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
