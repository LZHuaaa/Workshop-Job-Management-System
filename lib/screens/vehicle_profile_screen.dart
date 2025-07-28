import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../widgets/dashboard_card.dart';
import '../models/vehicle.dart';
import '../models/service_record.dart';
import '../dialogs/add_appointment_dialog.dart';
import '../dialogs/edit_vehicle_dialog.dart';
import 'vehicle_photo_manager.dart';

class VehicleProfileScreen extends StatefulWidget {
  final Vehicle vehicle;
  final Function(Vehicle) onVehicleUpdated;

  const VehicleProfileScreen({
    super.key,
    required this.vehicle,
    required this.onVehicleUpdated,
  });

  @override
  State<VehicleProfileScreen> createState() => _VehicleProfileScreenState();
}

class _VehicleProfileScreenState extends State<VehicleProfileScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late Vehicle _currentVehicle;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _currentVehicle = widget.vehicle;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _scheduleService() {
    showDialog(
      context: context,
      builder: (context) => AddAppointmentDialog(
        selectedDate: DateTime.now(),
        onAppointmentCreated: (appointment) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Service scheduled for ${_currentVehicle.displayName}',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: AppColors.successGreen,
            ),
          );
        },
      ),
    );
  }

  void _managePhotos() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => VehiclePhotoManager(
          vehicle: _currentVehicle,
          onPhotosUpdated: (photos) {
            setState(() {
              _currentVehicle = _currentVehicle.copyWith(photos: photos);
            });
            widget.onVehicleUpdated(_currentVehicle);
          },
        ),
      ),
    );
  }

  void _editVehicle() {
    showDialog(
      context: context,
      builder: (context) => EditVehicleDialog(
        vehicle: _currentVehicle,
        onVehicleUpdated: (updatedVehicle) {
          setState(() {
            _currentVehicle = updatedVehicle;
          });
          widget.onVehicleUpdated(updatedVehicle);
        },
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'delete':
        _showDeleteConfirmation();
        break;
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white, // Explicit white background
        surfaceTintColor: Colors.white, // Ensure white background
        title: Row(
          children: [
            Icon(Icons.warning, color: AppColors.errorRed),
            const SizedBox(width: 8),
            Text(
              'Delete Vehicle',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: AppColors.errorRed,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete this vehicle?',
              style: GoogleFonts.poppins(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentVehicle.fullDisplayName,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    'License: ${_currentVehicle.licensePlate}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    'Owner: ${_currentVehicle.customerName}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This action cannot be undone. All service history and photos will be permanently deleted.',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.errorRed,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _deleteVehicle();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteVehicle() {
    // TODO: Implement actual delete functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Vehicle "${_currentVehicle.displayName}" deleted successfully',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: AppColors.successGreen,
      ),
    );

    // Navigate back to previous screen
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          _currentVehicle.displayName,
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
        actions: [
          IconButton(
            icon: Icon(Icons.photo_library, color: AppColors.primaryPink),
            onPressed: _managePhotos,
            tooltip: 'Manage Photos',
          ),
          IconButton(
            icon: Icon(Icons.schedule, color: AppColors.primaryPink),
            onPressed: _scheduleService,
            tooltip: 'Schedule Service',
          ),
          IconButton(
            icon: Icon(Icons.edit, color: AppColors.primaryPink),
            onPressed: _editVehicle,
            tooltip: 'Edit Vehicle',
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            icon: Icon(Icons.more_vert, color: AppColors.primaryPink),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: AppColors.errorRed, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Delete Vehicle',
                      style: GoogleFonts.poppins(
                        color: AppColors.errorRed,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Vehicle Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.directions_car,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currentVehicle.fullDisplayName,
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _currentVehicle.customerName,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_currentVehicle.needsService)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.warningOrange,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'SERVICE DUE',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildHeaderStat(
                        'Mileage',
                        '${NumberFormat('#,###').format(_currentVehicle.mileage)} mi',
                        Icons.speed,
                      ),
                    ),
                    Expanded(
                      child: _buildHeaderStat(
                        'Last Service',
                        _currentVehicle.lastServiceDate != null
                            ? '${_currentVehicle.daysSinceLastService} days ago'
                            : 'Never',
                        Icons.build,
                      ),
                    ),
                    Expanded(
                      child: _buildHeaderStat(
                        'Services',
                        '${_currentVehicle.serviceHistory.length}',
                        Icons.history,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Tab Bar
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primaryPink,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primaryPink,
              labelStyle: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              tabs: const [
                Tab(text: 'Details'),
                Tab(text: 'Service History'),
                Tab(text: 'Photos'),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDetailsTab(),
                _buildServiceHistoryTab(),
                _buildPhotosTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white.withOpacity(0.8),
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          DashboardCard(
            title: 'Vehicle Specifications',
            child: Column(
              children: [
                _buildDetailRow('Make', _currentVehicle.make),
                _buildDetailRow('Model', _currentVehicle.model),
                _buildDetailRow('Year', _currentVehicle.year.toString()),
                _buildDetailRow('Color', _currentVehicle.color),
                _buildDetailRow('VIN', _currentVehicle.vin),
                _buildDetailRow('License Plate', _currentVehicle.licensePlate),
                _buildDetailRow('Current Mileage',
                    '${NumberFormat('#,###').format(_currentVehicle.mileage)} miles'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          DashboardCard(
            title: 'Customer Information',
            child: Column(
              children: [
                _buildDetailRow('Name', _currentVehicle.customerName),
                _buildDetailRow('Phone', _currentVehicle.customerPhone),
                _buildDetailRow('Email', _currentVehicle.customerEmail),
                _buildDetailRow('Customer Since',
                    DateFormat('MMM d, y').format(_currentVehicle.createdAt)),
              ],
            ),
          ),
          if (_currentVehicle.notes != null) ...[
            const SizedBox(height: 20),
            DashboardCard(
              title: 'Notes',
              child: Text(
                _currentVehicle.notes!,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.textDark,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildServiceHistoryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: _currentVehicle.serviceHistory.isEmpty
            ? [
                Container(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Icon(
                        Icons.build_circle_outlined,
                        size: 64,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Service History',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        'This vehicle has no recorded services yet',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ]
            : _currentVehicle.serviceHistory
                .map((service) => Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: _buildServiceCard(service),
                    ))
                .toList(),
      ),
    );
  }

  Widget _buildPhotosTab() {
    return const Center(
      child: Text('Photos functionality coming soon!'),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(ServiceRecord service) {
    return DashboardCard(
      title: service.serviceType,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  DateFormat('MMM d, y').format(service.serviceDate),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primaryPink,
                  ),
                ),
              ),
              Text(
                'RM${service.cost.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            service.description,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Mechanic: ${service.mechanicName} • ${service.mileage.toString()} miles',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          if (service.partsReplaced.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: service.partsReplaced
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
        ],
      ),
    );
  }
}
