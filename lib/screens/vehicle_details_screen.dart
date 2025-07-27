import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../widgets/dashboard_card.dart';
import '../models/vehicle.dart';
import '../screens/vehicle_profile_screen.dart';
import '../dialogs/add_vehicle_dialog.dart';
import '../dialogs/edit_vehicle_dialog.dart';
import 'vehicle_search_filter.dart';
import 'vehicle_analytics_screen.dart';
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
  final VehicleDataService _dataService = VehicleDataService();
  final MaintenanceNotificationService _notificationService = MaintenanceNotificationService();

  List<Vehicle> _allVehicles = [];
  List<Vehicle> _filteredVehicles = [];
  bool _hasActiveFilters = false;

  // Sample vehicle data
  final List<Vehicle> _vehicles = [
    Vehicle(
      id: '1',
      make: 'Proton',
      model: 'Saga',
      year: 2020,
      licensePlate: 'WA 1234 A',
      vin: '1HGBH41JXMN109186',
      color: 'Silver',
      mileage: 45000,
      customerId: 'c1',
      customerName: 'Ahmad bin Abdullah',
      customerPhone: '012-345-6789',
      customerEmail: 'ahmad.abdullah@email.com',
      createdAt: DateTime.now().subtract(const Duration(days: 365)),
      lastServiceDate: DateTime.now().subtract(const Duration(days: 30)),
      serviceHistory: [
        ServiceRecord(
          id: 's1',
          date: DateTime.now().subtract(const Duration(days: 30)),
          mileage: 44500,
          serviceType: 'Oil Change',
          description: 'Regular oil change and filter replacement',
          partsUsed: ['Oil Filter', 'Engine Oil'],
          laborHours: 1.0,
          totalCost: 89.99,
          mechanicName: 'Lim Wei Ming',
        ),
        ServiceRecord(
          id: 's2',
          date: DateTime.now().subtract(const Duration(days: 120)),
          mileage: 42000,
          serviceType: 'Brake Service',
          description: 'Front brake pad replacement',
          partsUsed: ['Brake Pads', 'Brake Fluid'],
          laborHours: 2.5,
          totalCost: 245.50,
          mechanicName: 'Siti Nurhaliza binti Hassan',
        ),
      ],
      notes: 'Customer prefers synthetic oil',
    ),
    Vehicle(
      id: '2',
      make: 'Perodua',
      model: 'Myvi',
      year: 2019,
      licensePlate: 'KL 5678 B',
      vin: '4T1BF1FK5KU123456',
      color: 'White',
      mileage: 62000,
      customerId: 'c2',
      customerName: 'Tan Mei Ling',
      customerPhone: '013-987-6543',
      customerEmail: 'tan.meiling@email.com',
      createdAt: DateTime.now().subtract(const Duration(days: 200)),
      lastServiceDate: DateTime.now().subtract(const Duration(days: 95)),
      serviceHistory: [
        ServiceRecord(
          id: 's3',
          date: DateTime.now().subtract(const Duration(days: 95)),
          mileage: 60000,
          serviceType: 'Transmission Service',
          description: 'Transmission fluid change and inspection',
          partsUsed: ['Transmission Fluid', 'Filter'],
          laborHours: 1.5,
          totalCost: 189.99,
          mechanicName: 'Raj Kumar a/l Suresh',
        ),
      ],
    ),
  ];

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

  void _addVehicle(Vehicle vehicle) {
    setState(() {
      _vehicles.add(vehicle);
      _allVehicles.add(vehicle);
      _filteredVehicles.add(vehicle);
    });
  }

  void _updateVehicle(Vehicle updatedVehicle) {
    setState(() {
      final index =
          _vehicles.indexWhere((vehicle) => vehicle.id == updatedVehicle.id);
      if (index != -1) {
        _vehicles[index] = updatedVehicle;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _allVehicles = List.from(_vehicles);
    _filteredVehicles = List.from(_vehicles);
    _initializeNotifications();
  }

  void _initializeNotifications() async {
    try {
      await _notificationService.initialize();
      if (mounted) {
        await _notificationService.scheduleNotificationsForAllVehicles(_vehicles);
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
                          IconButton(
                            onPressed: _showAnalytics,
                            icon: const Icon(Icons.analytics),
                            tooltip: 'Analytics',
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.backgroundLight,
                            ),
                          ),
                          const SizedBox(width: 6),
                          PopupMenuButton<String>(
                            onSelected: _handleMenuAction,
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'export_csv',
                                child: Row(
                                  children: [
                                    const Icon(Icons.file_download, size: 18),
                                    const SizedBox(width: 8),
                                    Text('Export CSV', style: GoogleFonts.poppins()),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'export_json',
                                child: Row(
                                  children: [
                                    const Icon(Icons.code, size: 18),
                                    const SizedBox(width: 8),
                                    Text('Export JSON', style: GoogleFonts.poppins()),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'generate_report',
                                child: Row(
                                  children: [
                                    const Icon(Icons.description, size: 18),
                                    const SizedBox(width: 8),
                                    Text('Generate Report', style: GoogleFonts.poppins()),
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
                      onChanged: (value) => setState(() {}),
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
                                      color: AppColors.errorRed.withOpacity(0.1),
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
                ],
              ),
            ),

            // Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAllVehiclesTab(),
                  _buildServiceDueTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddVehicleDialog,
        backgroundColor: AppColors.primaryPink,
        foregroundColor: Colors.white,
        elevation: 8,
        child: const Icon(Icons.add, size: 28),
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
              // Action Buttons Row
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: AppColors.backgroundLight,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () => _editVehicleFromCard(vehicle),
                        icon: Icon(
                          Icons.edit,
                          size: 16,
                          color: AppColors.primaryPink,
                        ),
                        label: Text(
                          'Edit',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.primaryPink,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 20,
                      color: AppColors.backgroundLight,
                    ),
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () => _deleteVehicleFromCard(vehicle),
                        icon: Icon(
                          Icons.delete,
                          size: 16,
                          color: AppColors.errorRed,
                        ),
                        label: Text(
                          'Delete',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.errorRed,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
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
              _hasActiveFilters = filteredVehicles.length != _allVehicles.length;
            });
          },
        ),
      ),
    );
  }

  void _showAnalytics() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => VehicleAnalyticsScreen(
          vehicles: _allVehicles,
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
        onVehicleUpdated: (updatedVehicle) {
          setState(() {
            // Update the vehicle in the lists
            final allIndex = _allVehicles.indexWhere((v) => v.id == updatedVehicle.id);
            if (allIndex != -1) {
              _allVehicles[allIndex] = updatedVehicle;
            }

            // Update the filtered vehicles list as well
            final filteredIndex = _filteredVehicles.indexWhere((v) => v.id == updatedVehicle.id);
            if (filteredIndex != -1) {
              _filteredVehicles[filteredIndex] = updatedVehicle;
            }
          });
        },
      ),
    );
  }

  void _deleteVehicleFromCard(Vehicle vehicle) {
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
                    vehicle.fullDisplayName,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    'License: ${vehicle.licensePlate}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    'Owner: ${vehicle.customerName}',
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
              'This action cannot be undone.',
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
              Navigator.pop(context);
              // Implement actual delete functionality
              setState(() {
                _allVehicles.removeWhere((v) => v.id == vehicle.id);
                _filteredVehicles.removeWhere((v) => v.id == vehicle.id);
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Vehicle "${vehicle.displayName}" deleted successfully',
                    style: GoogleFonts.poppins(),
                  ),
                  backgroundColor: AppColors.successGreen,
                ),
              );
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
}