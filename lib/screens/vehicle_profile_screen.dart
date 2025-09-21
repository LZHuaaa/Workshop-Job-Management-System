import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../dialogs/edit_vehicle_dialog.dart';
import '../dialogs/new_job_dialog.dart';
import '../models/service_record.dart';
import '../models/vehicle.dart';
import '../services/service_record_service.dart';
import '../services/vehicle_photo_service.dart';
import '../services/vehicle_service.dart';
import '../theme/app_colors.dart';
import '../widgets/dashboard_card.dart';
import 'enhanced_vehicle_photo_manager.dart';
import 'service_record_details_screen.dart';

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
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  late Vehicle _currentVehicle;
  List<VehiclePhoto> _photos = [];
  bool _isLoadingPhotos = false;
  List<ServiceRecord> _serviceRecords = [];
  bool _isLoadingServiceRecords = false;
  final ServiceRecordService _serviceRecordService = ServiceRecordService();
  final VehicleService _vehicleService = VehicleService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _currentVehicle = widget.vehicle;
    WidgetsBinding.instance.addObserver(this);
    _loadPhotos();
    _loadServiceRecords();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Refresh service records when app comes back to foreground
    if (state == AppLifecycleState.resumed) {
      _loadServiceRecords();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    super.dispose();
  }

  void _loadPhotos() async {
    setState(() {
      _isLoadingPhotos = true;
    });

    try {
      final photos = await VehiclePhotoService.getVehiclePhotos(_currentVehicle.id);
      if (mounted) {
        setState(() {
          _photos = photos;
          _isLoadingPhotos = false;
        });
      }
    } catch (e) {
      print('Error loading photos: $e');
      if (mounted) {
        setState(() {
          _isLoadingPhotos = false;
        });
      }
    }
  }

  void _loadServiceRecords() async {
    setState(() {
      _isLoadingServiceRecords = true;
    });

    try {
      print('Loading service records for vehicle: ${_currentVehicle.id}');
      final serviceRecords = await _serviceRecordService.getServiceRecordsByVehicle(_currentVehicle.id);
      print('Found ${serviceRecords.length} service records');
      
      if (mounted) {
        setState(() {
          _serviceRecords = serviceRecords;
          _isLoadingServiceRecords = false;
        });
      }
    } catch (e) {
      print('Error loading service records: $e');
      if (mounted) {
        setState(() {
          _isLoadingServiceRecords = false;
        });
      }
    }
  }

  // Method to refresh service records (can be called externally)
  void refreshServiceRecords() {
    _loadServiceRecords();
  }

  void _scheduleService() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => NewJobDialog(
        vehicleInfo: _currentVehicle.fullDisplayName,
        customerName: _currentVehicle.customerName,
        phoneNumber: _currentVehicle.customerPhone,
        vehicleId: widget.vehicle.id, // Pass the actual vehicle ID
        customerId: _currentVehicle.customerId, // Pass the actual customer ID
        onJobCreated: (appointment) {
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
    
    // Refresh service records if a job was created or completed
    if (result == true) {
      _loadServiceRecords();
    }
  }

  void _managePhotos() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EnhancedVehiclePhotoManager(
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

    // Refresh photos when returning from photo manager
    _loadPhotos();
  }

  void _editVehicle() {
    showDialog(
      context: context,
      builder: (context) => EditVehicleDialog(
        vehicle: _currentVehicle,
        onVehicleUpdated: (updatedVehicle) async {
          // Update local state
          setState(() {
            _currentVehicle = updatedVehicle;
          });
          // Call parent callback
          await widget.onVehicleUpdated(updatedVehicle);
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

  void _deleteVehicle() async {
    try {
      // Show loading state
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Deleting vehicle...',
                style: GoogleFonts.poppins(),
              ),
            ],
          ),
          backgroundColor: AppColors.primaryPink,
          duration: const Duration(seconds: 30), // Long duration since we'll dismiss it manually
        ),
      );

      // Attempt to delete the vehicle
      await _vehicleService.deleteVehicle(_currentVehicle.id);

      // Dismiss the loading snackbar
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Vehicle "${_currentVehicle.displayName}" deleted successfully',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: AppColors.successGreen,
        ),
      );

      // Navigate back and refresh the parent
      Navigator.pop(context, true); // Return true to indicate deletion
    } catch (e) {
      // Dismiss the loading snackbar
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      String errorMessage = 'Failed to delete vehicle';
      if (e.toString().contains('service records')) {
        errorMessage = 'Cannot delete vehicle with existing service records. Please remove all service records first.';
      } else if (e.toString().contains('not found')) {
        errorMessage = 'Vehicle no longer exists';
      } else {
        errorMessage = 'Failed to delete vehicle: ${e.toString()}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errorMessage,
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: AppColors.errorRed,
          duration: const Duration(seconds: 5),
        ),
      );
    }
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
                            _currentVehicle.customerName ?? 'Unknown Customer',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_currentVehicle.needsServiceWithRecords(_serviceRecords))
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
                        '${NumberFormat('#,###').format(_currentVehicle.mileage)} km',
                        Icons.speed,
                      ),
                    ),
                    Expanded(
                      child: _buildHeaderStat(
                        'Last Service',
                        _getLastServiceDisplayText(),
                        Icons.build,
                      ),
                    ),
                    Expanded(
                      child: _buildHeaderStat(
                        'Services',
                        '${_serviceRecords.length}',
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

  /// Calculate last service display text from actual service records
  String _getLastServiceDisplayText() {
    if (_serviceRecords.isEmpty) {
      return 'Never';
    }

    // Service records are already sorted by date descending from the service
    final mostRecentService = _serviceRecords.first;
    final daysSinceService = DateTime.now().difference(mostRecentService.serviceDate).inDays;
    
    if (daysSinceService == 0) {
      return 'Today';
    } else if (daysSinceService == 1) {
      return '1 day ago';
    } else {
      return '$daysSinceService days ago';
    }
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
                    '${NumberFormat('#,###').format(_currentVehicle.mileage)} km'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          DashboardCard(
            title: 'Customer Information',
            child: Column(
              children: [
                _buildDetailRow('Name', _currentVehicle.customerName ?? 'Unknown'),
                _buildDetailRow('Phone', _currentVehicle.customerPhone ?? 'Not provided'),
                _buildDetailRow('Email', _currentVehicle.customerEmail ?? 'Not provided'),
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
    if (_isLoadingServiceRecords) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with service count
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Service History',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              if (_serviceRecords.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPink.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primaryPink.withOpacity(0.3)),
                  ),
                  child: Text(
                    '${_serviceRecords.length} record${_serviceRecords.length != 1 ? 's' : ''}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryPink,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Service records or empty state
          ..._serviceRecords.isEmpty
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
                        const SizedBox(height: 8),
                        Text(
                          'This vehicle has no recorded services yet',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _scheduleService,
                          icon: const Icon(Icons.add),
                          label: const Text('Schedule Service'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryPink,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ]
              : _serviceRecords
                  .map((service) => Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: _buildServiceCard(service),
                      ))
                  .toList(),
        ],
      ),
    );
  }

  Widget _buildPhotosTab() {
    if (_isLoadingPhotos) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_photos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No photos yet',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add photos to see them organized by category',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _managePhotos,
              icon: const Icon(Icons.add_a_photo),
              label: const Text('Add Photos'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPink,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    // Group photos by category
    final photosByCategory = <PhotoCategory, List<VehiclePhoto>>{};
    for (final category in PhotoCategory.values) {
      photosByCategory[category] = _photos.where((p) => p.category == category).toList();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with manage photos button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Vehicle Photos',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _managePhotos,
                icon: const Icon(Icons.photo_library, size: 18),
                label: const Text('Manage'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPink,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Photo categories
          ...PhotoCategory.values.map((category) {
            final categoryPhotos = photosByCategory[category] ?? [];
            if (categoryPhotos.isEmpty) return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category header
                Row(
                  children: [
                    Icon(category.icon, color: category.color, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      category.label,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: category.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: category.color.withOpacity(0.3)),
                      ),
                      child: Text(
                        categoryPhotos.length.toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: category.color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Photo grid for this category
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1,
                  ),
                  itemCount: categoryPhotos.length,
                  itemBuilder: (context, index) {
                    final photo = categoryPhotos[index];
                    return _buildPhotoThumbnail(photo, category);
                  },
                ),
                const SizedBox(height: 24),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildPhotoThumbnail(VehiclePhoto photo, PhotoCategory category) {
    return GestureDetector(
      onTap: () => _viewPhotoInManager(photo),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: category.color.withOpacity(0.3)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Handle both network and local file URLs
              photo.url.startsWith('http')
                  ? Image.network(
                      photo.url,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: AppColors.backgroundLight,
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                              strokeWidth: 2,
                              color: category.color,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        print('❌ Network image error for ${photo.url}: $error');
                        return Container(
                          color: AppColors.backgroundLight,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.broken_image,
                                color: AppColors.textSecondary,
                                size: 24,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Failed to load',
                                style: GoogleFonts.poppins(
                                  fontSize: 8,
                                  color: AppColors.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      },
                    )
                  : Image.file(
                      File(photo.url),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        print('❌ Local file error for ${photo.url}: $error');
                        return Container(
                          color: AppColors.backgroundLight,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.broken_image,
                                color: AppColors.textSecondary,
                                size: 24,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'File not found',
                                style: GoogleFonts.poppins(
                                  fontSize: 8,
                                  color: AppColors.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      },
                    ),

              // Category indicator
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: category.color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    category.icon,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),

              // Annotation indicator
              if (photo.annotation != null && photo.annotation!.isNotEmpty)
                Positioned(
                  bottom: 4,
                  left: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.note,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _viewPhotoInManager(VehiclePhoto photo) {
    // Navigate to the enhanced photo manager and switch to the photo's category
    _managePhotos();
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
    return GestureDetector(
      onTap: () => _showServiceRecordDetails(service),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: DashboardCard(
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
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.textSecondary,
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
            'Mechanic: ${service.mechanicName} • ${service.mileage.toString()} km',
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
    ),
  ),
);
  }

  void _showServiceRecordDetails(ServiceRecord serviceRecord) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ServiceRecordDetailsScreen(
          serviceRecord: serviceRecord,
        ),
      ),
    );
  }
}
