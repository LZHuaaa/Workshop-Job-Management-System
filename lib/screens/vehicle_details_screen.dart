import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../widgets/dashboard_card.dart';
import '../models/vehicle.dart';
import '../models/service_record.dart';
import '../screens/vehicle_profile_screen.dart';
import '../dialogs/add_vehicle_dialog.dart';
import '../dialogs/edit_vehicle_dialog.dart';
import 'vehicle_search_filter.dart';
import 'vehicle_analytics_screen.dart';
import '../services/vehicle_service.dart';
import '../services/vehicle_data_service.dart';
import '../services/maintenance_notification_service.dart';
import '../services/service_record_service.dart';

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

  // Check if vehicle needs service based on last service date from service records
  bool _needsService(Vehicle vehicle) {
    final lastServiceDate = _vehicleLastServiceDates[vehicle.id];
    if (lastServiceDate == null) {
      // For new vehicles, give them a grace period of 30 days from creation date
      // before marking them as needing service
      final daysSinceCreation = DateTime.now().difference(vehicle.createdAt).inDays;
      return daysSinceCreation > 30; // Grace period for new vehicles
    }
    
    final daysSinceService = DateTime.now().difference(lastServiceDate).inDays;
    return daysSinceService > 90; // Needs service every 3 months
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
      
    } catch (e) {
      print('❌ Error loading service data: $e');
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
    _isUpdating = false; // Cancel any ongoing operations
    _searchController.removeListener(_onSearchChanged);
    _tabController.dispose();
    _searchController.dispose();
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
                            onSelected: _handleMenuAction,
                            itemBuilder: (context) => [
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
                            ],
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
                      '${NumberFormat('#,###').format(vehicle.mileage)} mi',
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
          case 'Customer':
            final aCustomer = a.customerName ?? '';
            final bCustomer = b.customerName ?? '';
            comparison = aCustomer.compareTo(bCustomer);
            break;
        }

        return _sortAscending ? comparison : -comparison;
      });
    });
  }

  void _handleMenuAction(String action) async {
    try {
      switch (action) {
        case 'export_csv':
          await _exportToCSV();
          break;
        case 'export_json':
          await _exportToJSON();
          break;
        case 'generate_report':
          await _generateReport();
          break;
      }
    } catch (e) {
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
    final filePath = await _dataService.exportVehiclesToCSV(_allVehicles);
    await _dataService.shareExportedFile(filePath, 'CSV');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Vehicle data exported to CSV',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: AppColors.successGreen,
        ),
      );
    }
  }

  Future<void> _exportToJSON() async {
    final filePath = await _dataService.exportVehiclesToJSON(_allVehicles);
    await _dataService.shareExportedFile(filePath, 'JSON');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Vehicle data exported to JSON',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: AppColors.successGreen,
        ),
      );
    }
  }

  Future<void> _generateReport() async {
    final filePath = await _dataService.generateVehicleReport(_allVehicles);
    await _dataService.shareExportedFile(filePath, 'PDF Report');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Vehicle PDF report generated',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: AppColors.successGreen,
        ),
      );
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
          _selectedSort = 'Customer';
          break;
      }
      
      _sortAscending = sortOrder == SortOrder.ascending;
      
      // Apply sorting using existing method
      _applySorting();
    });
  }
}
