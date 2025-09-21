import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

import '../dialogs/add_vehicle_dialog.dart';
import '../dialogs/edit_vehicle_dialog.dart';
import '../models/service_record.dart';
import '../models/vehicle.dart';
import '../screens/vehicle_profile_screen.dart';
import '../services/maintenance_notification_service.dart';
import '../services/service_record_service.dart';
import '../services/vehicle_data_service.dart';
import '../services/vehicle_service.dart';
import '../theme/app_colors.dart';
import 'vehicle_analytics_screen.dart';
import 'vehicle_search_filter.dart';

class VehicleDetailsScreen extends StatefulWidget {
  const VehicleDetailsScreen({super.key});

  @override
  State<VehicleDetailsScreen> createState() => _VehicleDetailsScreenState();
}

class _VehicleDetailsScreenState extends State<VehicleDetailsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final VehicleService _vehicleService = VehicleService();
  final VehicleDataService _dataService = VehicleDataService(); // For export functionality
  final MaintenanceNotificationService _notificationService =
      MaintenanceNotificationService();
  final ServiceRecordService _serviceRecordService = ServiceRecordService();

  List<Vehicle> _allVehicles = [];
  List<Vehicle> _filteredVehicles = [];
  bool _hasActiveFilters = false;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isUpdating = false;
  Map<String, List<ServiceRecord>> _vehicleServiceRecords = {};
  Map<String, int> _vehicleServiceCounts = {};
  Map<String, DateTime?> _vehicleLastServiceDates = {};
  bool _serviceDataLoaded = false; // Track if service data has been loaded
  
  // Quick sort state
  String _selectedSort = 'None';
  bool _sortAscending = true;
  SortOption _currentSortOption = SortOption.alphabetical;
  SortOrder _currentSortOrder = SortOrder.ascending;
  
  final List<String> _sortOptions = [
    'None',
    'Year',
    'Mileage',
    'Service Date',
    'Service Count',
    'Customer Name',
  ];

  List<Vehicle> get _currentFilteredVehicles {
    if (_searchController.text.isEmpty) return _filteredVehicles;

    final searchTerm = _searchController.text.toLowerCase();
    return _filteredVehicles
        .where((vehicle) =>
            vehicle.displayName.toLowerCase().contains(searchTerm) ||
            vehicle.licensePlate.toLowerCase().contains(searchTerm) ||
            (vehicle.customerName?.toLowerCase().contains(searchTerm) ?? false) ||
            vehicle.vin.toLowerCase().contains(searchTerm))
        .toList();
  }

  // Enhanced service due logic using nextServiceDue dates from service records
  bool _needsService(Vehicle vehicle) {
    final serviceRecords = _vehicleServiceRecords[vehicle.id] ?? [];
    
    // Use the enhanced logic from Vehicle model that considers nextServiceDue dates
    return vehicle.needsServiceWithRecords(serviceRecords);
  }



  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadVehicles();
    _initializeNotifications();

    // Add real-time search listener
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    // Trigger rebuild when search text changes
    if (mounted) {
      setState(() {
        // The _currentFilteredVehicles getter will automatically filter based on search text
      });
    }
  }

  // Load vehicles from Firebase - OPTIMIZED
  Future<void> _loadVehicles() async {
    if (_isUpdating) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('🔄 Loading vehicles...');
      
      // Load vehicles first
      final vehicles = await _vehicleService.getAllVehicles();
      print('📊 Loaded ${vehicles.length} vehicles');

      if (!mounted) return;

      setState(() {
        _allVehicles = vehicles;
        _filteredVehicles = List.from(vehicles);
        _isLoading = false;
      });

      // Apply current sorting
      _applySorting();

      // Load service data in background - don't block UI
      if (!_serviceDataLoaded) {
        _loadServiceDataInBackground();
      }
      
    } catch (e) {
      print('❌ Error loading vehicles: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load vehicles: $e';
          _isLoading = false;
        });
      }
    }
  }

  // Load service records for all vehicles - OPTIMIZED BACKGROUND LOADING
  Future<void> _loadServiceDataInBackground() async {
    try {
      print('🔄 Loading service data in background...');
      
      // Get all service records at once
      final allServiceRecords = await _serviceRecordService.getAllServiceRecords();
      print('📊 Loaded ${allServiceRecords.length} service records');
      
      // Test: Print first few service dates to debug date parsing
      if (allServiceRecords.isNotEmpty) {
        print('🧪 Sample service dates:');
        for (final record in allServiceRecords.take(3)) {
          print('   Record ${record.id}: ${record.serviceDate} (${record.serviceType})');
        }
      }

      // Group by vehicle ID
      final serviceRecordsByVehicle = <String, List<ServiceRecord>>{};
      final serviceCountsByVehicle = <String, int>{};
      final lastServiceDatesByVehicle = <String, DateTime?>{};

      for (final record in allServiceRecords) {
        final vehicleId = record.vehicleId;
        
        // Group records
        serviceRecordsByVehicle.putIfAbsent(vehicleId, () => []).add(record);
        
        // Count records
        serviceCountsByVehicle[vehicleId] = (serviceCountsByVehicle[vehicleId] ?? 0) + 1;
        
        // Track most recent service date
        final currentLastDate = lastServiceDatesByVehicle[vehicleId];
        if (currentLastDate == null || record.serviceDate.isAfter(currentLastDate)) {
          lastServiceDatesByVehicle[vehicleId] = record.serviceDate;
        }
      }

      if (!mounted) return;

      setState(() {
        _vehicleServiceRecords = serviceRecordsByVehicle;
        _vehicleServiceCounts = serviceCountsByVehicle;
        _vehicleLastServiceDates = lastServiceDatesByVehicle;
        _serviceDataLoaded = true; // Mark as loaded
      });

      print('✅ Service data loaded successfully');
      print('   - Service records by vehicle: ${serviceRecordsByVehicle.keys.length} vehicles');
      print('   - Last service dates: ${lastServiceDatesByVehicle.keys.length} vehicles');
      
      // Diagnostic: Print vehicles with no service dates
      final vehiclesWithoutServiceDates = _allVehicles
          .where((v) => !lastServiceDatesByVehicle.containsKey(v.id))
          .length;
      if (vehiclesWithoutServiceDates > 0) {
        print('ℹ️ Vehicles without service dates: $vehiclesWithoutServiceDates');
      }
      
    } catch (e, stackTrace) {
      print('❌ Error loading service data: $e');
      print('Stack trace: $stackTrace');
      
      // Specifically handle date parsing errors
      if (e.toString().contains('Invalid date format') || e.toString().contains('FormatException')) {
        print('🔧 Date parsing error detected. This should be fixed with the new date handling.');
      }
      
      // Don't show error for background loading
    }
  }

  // Add vehicle to Firebase
  Future<void> _addVehicle(Vehicle vehicle) async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      await _vehicleService.createVehicle(vehicle);
      await _loadVehicles(); // Reload vehicles from Firebase

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Vehicle added successfully!',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to add vehicle: ${e.toString()}';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to add vehicle: ${e.toString()}',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Update vehicle in Firebase
  Future<void> _updateVehicle(Vehicle vehicle) async {
    if (_isUpdating || !mounted) return;

    try {
      _isUpdating = true;

      print('Updating vehicle: ${vehicle.id} - ${vehicle.displayName}');
      print('Vehicle data: ${vehicle.toMap()}');

      await _vehicleService.updateVehicle(vehicle);
      print('Vehicle updated successfully in Firebase');

      if (mounted) {
        // Update the local list manually instead of reloading everything
        final index = _allVehicles.indexWhere((v) => v.id == vehicle.id);
        if (index != -1) {
          setState(() {
            _allVehicles[index] = vehicle;
            _filteredVehicles = List.from(_allVehicles);
            _isLoading = false;
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Vehicle updated successfully!',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error updating vehicle: $e');

      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to update vehicle: ${e.toString()}';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to update vehicle: ${e.toString()}',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      _isUpdating = false;
    }
  }

  // Delete vehicle from Firebase
  Future<void> _deleteVehicle(Vehicle vehicle) async {
    // Show confirmation dialog
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text(
          'Delete Vehicle',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to delete ${vehicle.displayName}? This action cannot be undone.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      try {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });

        await _vehicleService.deleteVehicle(vehicle.id);
        await _loadVehicles(); // Reload vehicles from Firebase

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Vehicle deleted successfully!',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to delete vehicle: ${e.toString()}';
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to delete vehicle: ${e.toString()}',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _initializeNotifications() async {
    try {
      await _notificationService.initialize();
      if (mounted) {
        await _notificationService
            .scheduleNotificationsForAllVehicles(_allVehicles);
      }
    } catch (e) {
      // Handle initialization errors gracefully
      if (mounted) {
        print('Notification service initialization failed: $e');
      }
    }
  }

  @override
  void dispose() {
    // Cancel any ongoing operations
    _isUpdating = false;
    
    // Clean up listeners
    _searchController.removeListener(_onSearchChanged);
    
    // Dispose controllers
    _tabController.dispose();
    _searchController.dispose();
    
    // Clear data structures to help with garbage collection
    _allVehicles.clear();
    _filteredVehicles.clear();
    _vehicleServiceRecords.clear();
    _vehicleServiceCounts.clear();
    _vehicleLastServiceDates.clear();
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
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
                        'Vehicles',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      Row(
                        children: [
                          // Add Vehicle Button
                          ElevatedButton.icon(
                            onPressed: _showAddVehicleDialog,
                            icon: const Icon(Icons.add, size: 18),
                            label: Text(
                              'Add Vehicle',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryPink,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          PopupMenuButton<String>(
                            onSelected: (String action) {
                              // Add mounted check before handling action
                              if (mounted) {
                                _handleMenuAction(action);
                              }
                            },
                            itemBuilder: (BuildContext context) {
                              // Ensure we're still mounted when building items
                              if (!mounted) return <PopupMenuEntry<String>>[];
                              
                              return [
                                PopupMenuItem(
                                  value: 'export_csv',
                                  child: Row(
                                    children: [
                                      const Icon(Icons.file_download, size: 18),
                                      const SizedBox(width: 8),
                                      Text('Export CSV',
                                          style: GoogleFonts.poppins()),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'export_json',
                                  child: Row(
                                    children: [
                                      const Icon(Icons.code, size: 18),
                                      const SizedBox(width: 8),
                                      Text('Export JSON',
                                          style: GoogleFonts.poppins()),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'generate_report',
                                  child: Row(
                                    children: [
                                      const Icon(Icons.description, size: 18),
                                      const SizedBox(width: 8),
                                      Text('Generate Report',
                                          style: GoogleFonts.poppins()),
                                    ],
                                  ),
                                ),
                              ];
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.backgroundLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.more_vert),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText:
                            'Search vehicles, customers, or license plates...',
                        hintStyle: GoogleFonts.poppins(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: AppColors.textSecondary,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Filter & Sort Section
                  GestureDetector(
                    onTap: _showSearchFilter,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _hasActiveFilters
                              ? AppColors.primaryPink.withOpacity(0.3)
                              : AppColors.backgroundLight,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _hasActiveFilters
                                  ? AppColors.primaryPink.withOpacity(0.1)
                                  : AppColors.backgroundLight.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _hasActiveFilters ? Icons.filter_alt : Icons.tune,
                              size: 20,
                              color: _hasActiveFilters
                                  ? AppColors.primaryPink
                                  : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Filtering',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _hasActiveFilters
                                      ? 'Showing ${_filteredVehicles.length} of ${_allVehicles.length} vehicles'
                                      : 'Filter by make, year, service status',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: _hasActiveFilters
                                        ? AppColors.primaryPink
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_hasActiveFilters) ...[
                                GestureDetector(
                                  onTap: _clearFilters,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color:
                                          AppColors.errorRed.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Icon(
                                      Icons.clear,
                                      size: 16,
                                      color: AppColors.errorRed,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Icon(
                                Icons.chevron_right,
                                size: 20,
                                color: AppColors.textSecondary,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Quick Sort Buttons
            if (_allVehicles.isNotEmpty) _buildQuickSortButtons(),

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
                  Tab(text: 'All Vehicles'),
                  Tab(text: 'Service Due'),
                  Tab(text: 'Analytics'),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : _errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 64,
                                color: Colors.red,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Error loading vehicles',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _errorMessage!,
                                style: GoogleFonts.poppins(
                                  color: Colors.red,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadVehicles,
                                child: Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildAllVehiclesTab(),
                            _buildServiceDueTab(),
                            _buildAnalyticsTab(),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllVehiclesTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _currentFilteredVehicles.length,
      itemBuilder: (context, index) {
        final vehicle = _currentFilteredVehicles[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildVehicleCard(vehicle),
        );
      },
    );
  }

  Widget _buildServiceDueTab() {
    final serviceDueVehicles =
        _filteredVehicles.where((v) => _needsService(v)).toList();

    if (serviceDueVehicles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: AppColors.successGreen,
            ),
            const SizedBox(height: 16),
            Text(
              'All vehicles are up to date!',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            Text(
              'No vehicles require immediate service',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: serviceDueVehicles.length,
      itemBuilder: (context, index) {
        final vehicle = serviceDueVehicles[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildVehicleCard(vehicle, showServiceAlert: true),
        );
      },
    );
  }

  Widget _buildVehicleCard(Vehicle vehicle, {bool showServiceAlert = false}) {
    return GestureDetector(
      onTap: () => _showVehicleDetails(vehicle),
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
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.primaryPink.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.directions_car,
                      color: AppColors.primaryPink,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vehicle.displayName,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        Text(
                          vehicle.licensePlate,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                  if (showServiceAlert || _needsService(vehicle))
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
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
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      Icons.person,
                      'Owner',
                      vehicle.customerName ?? 'Unknown',
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      Icons.speed,
                      'Mileage',
                      '${NumberFormat('#,###').format(vehicle.mileage)} km',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      Icons.palette,
                      'Color',
                      vehicle.color,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      Icons.calendar_today,
                      'Last Service',
                      _vehicleLastServiceDates[vehicle.id] != null
                          ? DateFormat('MMM d, y')
                              .format(_vehicleLastServiceDates[vehicle.id]!)
                          : 'Never',
                    ),
                  ),
                ],
              ),
              if (_vehicleServiceCounts[vehicle.id] != null && _vehicleServiceCounts[vehicle.id]! > 0) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.softPink,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.history,
                        size: 16,
                        color: AppColors.primaryPink,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_vehicleServiceCounts[vehicle.id]} service record${_vehicleServiceCounts[vehicle.id] != 1 ? 's' : ''}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.primaryPink,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 12,
                        color: AppColors.primaryPink,
                      ),
                    ],
                  ),
                ),
              ],
              // Action Buttons Row - Matching Customer Page Style
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: AppColors.backgroundLight,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () => _editVehicleFromCard(vehicle),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryPink.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.edit,
                          size: 16,
                          color: AppColors.primaryPink,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _deleteVehicleFromCard(vehicle),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.errorRed.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.delete,
                          size: 16,
                          color: AppColors.errorRed,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDark,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showVehicleDetails(Vehicle vehicle) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => VehicleProfileScreen(
          vehicle: vehicle,
          onVehicleUpdated: _updateVehicle,
        ),
      ),
    );

    // If vehicle was deleted, refresh the list
    if (result == true) {
      await _loadVehicles();
    }
  }

  Widget _buildAnalyticsTab() {
    return VehicleAnalyticsScreen(vehicles: _allVehicles);
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMakeDistribution() {
    if (_allVehicles.isEmpty) {
      return [
        Text(
          'No vehicles to analyze',
          style: GoogleFonts.poppins(color: AppColors.textSecondary),
        ),
      ];
    }

    final makeCount = <String, int>{};
    for (final vehicle in _allVehicles) {
      makeCount[vehicle.make] = (makeCount[vehicle.make] ?? 0) + 1;
    }

    final sortedMakes = makeCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedMakes.take(5).map((entry) {
      final percentage = (entry.value / _allVehicles.length * 100).toStringAsFixed(1);
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                entry.key,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: entry.value / _allVehicles.length,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.primaryPink,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${entry.value} ($percentage%)',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  List<Widget> _buildRecentVehicles() {
    if (_allVehicles.isEmpty) {
      return [
        Text(
          'No recent vehicles',
          style: GoogleFonts.poppins(color: AppColors.textSecondary),
        ),
      ];
    }

    final recentVehicles = _allVehicles.take(5).toList();

    return recentVehicles.map((vehicle) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryPink.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.directions_car,
                color: AppColors.primaryPink,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vehicle.displayName,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    vehicle.customerName ?? 'Unknown',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              DateFormat('MMM dd').format(vehicle.createdAt),
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  void _showAddVehicleDialog() {
    showDialog(
      context: context,
      builder: (context) => AddVehicleDialog(
        onVehicleAdded: _addVehicle,
      ),
    );
  }

  void _showSearchFilter() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => VehicleSearchFilter(
          vehicles: _allVehicles,
          vehicleServiceCounts: _vehicleServiceCounts,
          vehicleLastServiceDates: _vehicleLastServiceDates,
          onFilterApplied: (filteredVehicles) {
            setState(() {
              _filteredVehicles = filteredVehicles;
              _hasActiveFilters =
                  filteredVehicles.length != _allVehicles.length;
            });
          },
        ),
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _filteredVehicles = List.from(_allVehicles);
      _hasActiveFilters = false;
      _searchController.clear();
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Filters cleared',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: AppColors.successGreen,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _applySorting() {
    if (_filteredVehicles.isEmpty || _selectedSort == 'None') return;

    setState(() {
      _filteredVehicles.sort((a, b) {
        int comparison = 0;

        switch (_selectedSort) {
          case 'Name':
            comparison = a.displayName.compareTo(b.displayName);
            break;
          case 'Year':
            comparison = a.year.compareTo(b.year);
            break;
          case 'Mileage':
            comparison = a.mileage.compareTo(b.mileage);
            break;
          case 'Service Date':
            final aDate = _vehicleLastServiceDates[a.id] ?? DateTime(1900);
            final bDate = _vehicleLastServiceDates[b.id] ?? DateTime(1900);
            comparison = aDate.compareTo(bDate);
            break;
          case 'Service Count':
            final aCount = _vehicleServiceCounts[a.id] ?? 0;
            final bCount = _vehicleServiceCounts[b.id] ?? 0;
            comparison = aCount.compareTo(bCount);
            break;
          case 'Customer Name':
            // Sort by last name first, then first name (standard business practice)
            final aCustomer = a.customerName ?? '';
            final bCustomer = b.customerName ?? '';
            
            // Extract last name for proper sorting
            final aLastName = _extractLastName(aCustomer);
            final bLastName = _extractLastName(bCustomer);
            
            // Compare last names first
            comparison = aLastName.compareTo(bLastName);
            
            // If last names are the same, compare first names
            if (comparison == 0) {
              final aFirstName = _extractFirstName(aCustomer);
              final bFirstName = _extractFirstName(bCustomer);
              comparison = aFirstName.compareTo(bFirstName);
            }
            break;
        }

        return _sortAscending ? comparison : -comparison;
      });
    });
  }

  void _handleMenuAction(String action) async {
    // Early exit if widget is disposed
    if (!mounted) return;
    
    try {
      switch (action) {
        case 'export_csv':
          if (mounted) await _exportToCSV();
          break;
        case 'export_json':
          if (mounted) await _exportToJSON();
          break;
        case 'generate_report':
          if (mounted) await _generateReport();
          break;
      }
    } catch (e) {
      print('❌ Error in menu action $action: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _exportToCSV() async {
    try {
      // Handle permissions for different Android versions
      bool hasPermission = await _requestStoragePermission();
      if (!hasPermission) return;

      // Generate CSV content using existing service
      final filePath = await _dataService.exportVehiclesToCSV(_allVehicles);
      
      // Get the CSV file content
      final csvFile = File(filePath);
      final csvContent = await csvFile.readAsString();
      
      // Save to Downloads folder
      final downloadPath = await _saveToDownloads(
        csvContent, 
        'Vehicles_Export_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv',
        'CSV'
      );
      
      if (downloadPath != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '✅ Vehicle data exported to CSV successfully!',
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'File: ${downloadPath.split('/').last}',
                  style: GoogleFonts.poppins(fontSize: 12),
                ),
                Text(
                  'Location: Downloads',
                  style: GoogleFonts.poppins(fontSize: 12),
                ),
                const SizedBox(height: 8),
                Text(
                  '📁 Open: File Manager > Downloads folder',
                  style: GoogleFonts.poppins(fontSize: 11, fontStyle: FontStyle.italic),
                ),
              ],
            ),
            backgroundColor: AppColors.successGreen,
            duration: const Duration(seconds: 6),
          ),
        );
      }
      
      // Clean up temporary file
      try {
        await csvFile.delete();
      } catch (e) {
        print('Could not delete temporary file: $e');
      }
      
    } catch (e) {
      print('❌ Error exporting CSV: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to export CSV: ${e.toString()}',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _exportToJSON() async {
    try {
      // Handle permissions for different Android versions
      bool hasPermission = await _requestStoragePermission();
      if (!hasPermission) return;

      // Generate JSON content using existing service
      final filePath = await _dataService.exportVehiclesToJSON(_allVehicles);
      
      // Get the JSON file content
      final jsonFile = File(filePath);
      final jsonContent = await jsonFile.readAsString();
      
      // Save to Downloads folder
      final downloadPath = await _saveToDownloads(
        jsonContent, 
        'Vehicles_Export_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.json',
        'JSON'
      );
      
      if (downloadPath != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '✅ Vehicle data exported to JSON successfully!',
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'File: ${downloadPath.split('/').last}',
                  style: GoogleFonts.poppins(fontSize: 12),
                ),
                Text(
                  'Location: Downloads',
                  style: GoogleFonts.poppins(fontSize: 12),
                ),
                const SizedBox(height: 8),
                Text(
                  '📁 Open: File Manager > Downloads folder',
                  style: GoogleFonts.poppins(fontSize: 11, fontStyle: FontStyle.italic),
                ),
              ],
            ),
            backgroundColor: AppColors.successGreen,
            duration: const Duration(seconds: 6),
          ),
        );
      }
      
      // Clean up temporary file
      try {
        await jsonFile.delete();
      } catch (e) {
        print('Could not delete temporary file: $e');
      }
      
    } catch (e) {
      print('❌ Error exporting JSON: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to export JSON: ${e.toString()}',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _generateReport() async {
    try {
      // Handle permissions for different Android versions
      bool hasPermission = await _requestStoragePermission();
      if (!hasPermission) return;

      // Generate PDF report using existing service
      final filePath = await _dataService.generateVehicleReport(_allVehicles);
      
      // Get the PDF file content as bytes
      final pdfFile = File(filePath);
      final pdfBytes = await pdfFile.readAsBytes();
      
      // Save to Downloads folder
      final downloadPath = await _saveBytesToDownloads(
        pdfBytes, 
        'Vehicle_Report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf',
        'PDF Report'
      );
      
      if (downloadPath != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '✅ Vehicle PDF report generated successfully!',
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'File: ${downloadPath.split('/').last}',
                  style: GoogleFonts.poppins(fontSize: 12),
                ),
                Text(
                  'Location: Downloads',
                  style: GoogleFonts.poppins(fontSize: 12),
                ),
                const SizedBox(height: 8),
                Text(
                  '📁 Open: File Manager > Downloads folder',
                  style: GoogleFonts.poppins(fontSize: 11, fontStyle: FontStyle.italic),
                ),
              ],
            ),
            backgroundColor: AppColors.successGreen,
            duration: const Duration(seconds: 6),
          ),
        );
      }
      
      // Clean up temporary file
      try {
        await pdfFile.delete();
      } catch (e) {
        print('Could not delete temporary file: $e');
      }
      
    } catch (e) {
      print('❌ Error generating report: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to generate report: ${e.toString()}',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  void _editVehicleFromCard(Vehicle vehicle) {
    showDialog(
      context: context,
      builder: (context) => EditVehicleDialog(
        vehicle: vehicle,
        onVehicleUpdated: (updatedVehicle) async {
          // Don't pop here - let the dialog handle its own navigation
          await _updateVehicle(updatedVehicle); // Just update
        },
      ),
    );
  }

  void _deleteVehicleFromCard(Vehicle vehicle) {
    _deleteVehicle(vehicle);
  }

    // Quick Sort UI
  Widget _buildQuickSortButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedSort,
              decoration: InputDecoration(
                labelText: 'Sort by',
                labelStyle: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: AppColors.textSecondary.withOpacity(0.3),
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: _sortOptions.map((sort) {
                return DropdownMenuItem(
                  value: sort,
                  child: Text(
                    sort,
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedSort = value!;
                  _applySorting();
                });
              },
            ),
          ),
          const SizedBox(width: 8),
          // Sort direction button
          IconButton(
            icon: Icon(
              _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
              color: AppColors.primaryPink,
            ),
            onPressed: () {
              setState(() {
                _sortAscending = !_sortAscending;
                _applySorting();
              });
            },
            tooltip: _sortAscending ? 'Sort Ascending' : 'Sort Descending',
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSortButton(
    String label,
    SortOption sortOption,
    SortOrder sortOrder,
    IconData icon,
  ) {
    final isActive = _currentSortOption == sortOption && _currentSortOrder == sortOrder;
    
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => _applyQuickSort(sortOption, sortOrder),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primaryPink : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive ? AppColors.primaryPink : AppColors.backgroundLight,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: isActive ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isActive ? Colors.white : AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _applyQuickSort(SortOption sortOption, SortOrder sortOrder) {
    setState(() {
      _currentSortOption = sortOption;
      _currentSortOrder = sortOrder;
      
      // Update the selected sort for compatibility with existing sorting
      switch (sortOption) {
        case SortOption.alphabetical:
          _selectedSort = 'Name';
          break;
        case SortOption.year:
          _selectedSort = 'Year';
          break;
        case SortOption.mileage:
          _selectedSort = 'Mileage';
          break;
        case SortOption.serviceDate:
          _selectedSort = 'Service Date';
          break;
        case SortOption.serviceCount:
          _selectedSort = 'Service Count';
          break;
        case SortOption.customerName:
          _selectedSort = 'Customer Name';
          break;
      }
      
      _sortAscending = sortOrder == SortOrder.ascending;
      
      // Apply sorting using existing method
      _applySorting();
    });
  }

  // Helper method to extract first name from full name
  String _extractFirstName(String fullName) {
    if (fullName.isEmpty) return '';
    
    // Handle special placeholder names
    if (fullName == 'Unassigned Customer' || fullName.startsWith('Missing Customer')) {
      return fullName; // Return as-is for placeholder names
    }
    
    final parts = fullName.trim().split(' ');
    return parts.isNotEmpty ? parts.first : '';
  }

  // Helper method to extract last name from full name
  String _extractLastName(String fullName) {
    if (fullName.isEmpty) return '';
    
    // Handle special placeholder names
    if (fullName == 'Unassigned Customer' || fullName.startsWith('Missing Customer')) {
      return fullName; // Return as-is for placeholder names
    }
    
    final parts = fullName.trim().split(' ');
    if (parts.length <= 1) {
      return fullName; // If only one name, use it as the last name for sorting
    }
    
    // For standard Western names: "First Last" -> "Last"
    // For multi-part names: "First Middle Last" -> "Last"
    // Return the last part as the last name (most common convention)
    return parts.last;
  }

  // Request storage permission based on Android version
  Future<bool> _requestStoragePermission() async {
    if (!Platform.isAndroid) return true;

    try {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      
      if (androidInfo.version.sdkInt >= 30) {
        // Android 11+ (API 30+) - Use manage external storage permission
        var status = await Permission.manageExternalStorage.status;
        if (!status.isGranted) {
          status = await Permission.manageExternalStorage.request();
        }
        
        if (!status.isGranted && mounted) {
          _showPermissionDialog();
          return false;
        }
        return status.isGranted;
      } else {
        // Android 10 and below - Use regular storage permission
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          status = await Permission.storage.request();
        }
        
        if (!status.isGranted && mounted) {
          _showPermissionDialog();
          return false;
        }
        return status.isGranted;
      }
    } catch (e) {
      print('❌ Error requesting storage permission: $e');
      return false;
    }
  }

  void _showPermissionDialog() {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Storage permission is required to save files to Downloads folder',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: AppColors.errorRed,
        action: SnackBarAction(
          label: 'Settings',
          textColor: Colors.white,
          onPressed: () {
            openAppSettings();
          },
        ),
        duration: const Duration(seconds: 6),
      ),
    );
  }

  // Save string content to Downloads folder
  Future<String?> _saveToDownloads(String content, String fileName, String fileType) async {
    try {
      // Get Downloads directory
      Directory? directory;
      String directoryName = "Downloads";
      
      if (Platform.isAndroid) {
        // Try multiple possible Download directory paths
        final List<String> downloadPaths = [
          '/storage/emulated/0/Download',
          '/storage/emulated/0/Downloads',
          '/sdcard/Download',
          '/sdcard/Downloads',
        ];
        
        for (String path in downloadPaths) {
          final testDir = Directory(path);
          if (await testDir.exists()) {
            directory = testDir;
            directoryName = path.split('/').last;
            break;
          }
        }
        
        // If no Downloads folder found, create one in external storage
        if (directory == null) {
          final externalDir = await getExternalStorageDirectory();
          if (externalDir != null) {
            directory = Directory('${externalDir.path}/Download');
            await directory.create(recursive: true);
            directoryName = "Android/data/Download";
          }
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
        directoryName = "Documents";
      }

      if (directory == null) {
        throw Exception('Could not access storage directory');
      }

      final file = File('${directory.path}/$fileName');
      
      // Write content to file
      await file.writeAsString(content);
      
      print('📄 $fileType saved successfully:');
      print('   File name: $fileName');
      print('   Full path: ${file.path}');
      print('   File exists: ${await file.exists()}');
      print('   File size: ${await file.length()} bytes');

      return file.path;
    } catch (e) {
      print('❌ Error saving $fileType to Downloads: $e');
      return null;
    }
  }

  // Save bytes content to Downloads folder (for PDFs)
  Future<String?> _saveBytesToDownloads(List<int> bytes, String fileName, String fileType) async {
    try {
      // Get Downloads directory
      Directory? directory;
      String directoryName = "Downloads";
      
      if (Platform.isAndroid) {
        // Try multiple possible Download directory paths
        final List<String> downloadPaths = [
          '/storage/emulated/0/Download',
          '/storage/emulated/0/Downloads',
          '/sdcard/Download',
          '/sdcard/Downloads',
        ];
        
        for (String path in downloadPaths) {
          final testDir = Directory(path);
          if (await testDir.exists()) {
            directory = testDir;
            directoryName = path.split('/').last;
            break;
          }
        }
        
        // If no Downloads folder found, create one in external storage
        if (directory == null) {
          final externalDir = await getExternalStorageDirectory();
          if (externalDir != null) {
            directory = Directory('${externalDir.path}/Download');
            await directory.create(recursive: true);
            directoryName = "Android/data/Download";
          }
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
        directoryName = "Documents";
      }

      if (directory == null) {
        throw Exception('Could not access storage directory');
      }

      final file = File('${directory.path}/$fileName');
      
      // Write bytes to file
      await file.writeAsBytes(bytes);
      
      print('📄 $fileType saved successfully:');
      print('   File name: $fileName');
      print('   Full path: ${file.path}');
      print('   File exists: ${await file.exists()}');
      print('   File size: ${await file.length()} bytes');

      return file.path;
    } catch (e) {
      print('❌ Error saving $fileType to Downloads: $e');
      return null;
    }
  }
}
