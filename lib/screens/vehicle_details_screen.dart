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

  List<Vehicle> _allVehicles = [];
  List<Vehicle> _filteredVehicles = [];
  bool _hasActiveFilters = false;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isUpdating = false;



  List<Vehicle> get _currentFilteredVehicles {
    if (_searchController.text.isEmpty) return _filteredVehicles;

    final searchTerm = _searchController.text.toLowerCase();
    return _filteredVehicles
        .where((vehicle) =>
            vehicle.displayName.toLowerCase().contains(searchTerm) ||
            vehicle.licensePlate.toLowerCase().contains(searchTerm) ||
            vehicle.customerName.toLowerCase().contains(searchTerm) ||
            vehicle.vin.toLowerCase().contains(searchTerm))
        .toList();
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

  // Load vehicles from Firebase
  Future<void> _loadVehicles() async {
    try {
      if (!mounted) return;

      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final vehicles = await _vehicleService.getAllVehicles();

      if (!mounted) return;

      setState(() {
        _allVehicles = vehicles;
        _filteredVehicles = vehicles;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load vehicles: ${e.toString()}';
        });
      }
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
                                  'Filter & Sort',
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
        _filteredVehicles.where((v) => v.needsService).toList();

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
                        ),
                        Text(
                          vehicle.licensePlate,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (showServiceAlert || vehicle.needsService)
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
                      vehicle.customerName,
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
                      vehicle.lastServiceDate != null
                          ? DateFormat('MMM d, y')
                              .format(vehicle.lastServiceDate!)
                          : 'Never',
                    ),
                  ),
                ],
              ),
              if (vehicle.serviceHistory.isNotEmpty) ...[
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
                        '${vehicle.serviceHistory.length} service record${vehicle.serviceHistory.length != 1 ? 's' : ''}',
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
        Column(
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
            ),
          ],
        ),
      ],
    );
  }

  void _showVehicleDetails(Vehicle vehicle) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => VehicleProfileScreen(
          vehicle: vehicle,
          onVehicleUpdated: _updateVehicle,
        ),
      ),
    );
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
                    vehicle.customerName,
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
    await _dataService.shareExportedFile(filePath, 'Report');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Vehicle report generated',
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
          Navigator.of(context).pop(); // Close dialog first
          await _updateVehicle(updatedVehicle); // Then update
        },
      ),
    );
  }

  void _deleteVehicleFromCard(Vehicle vehicle) {
    _deleteVehicle(vehicle);
  }
}
