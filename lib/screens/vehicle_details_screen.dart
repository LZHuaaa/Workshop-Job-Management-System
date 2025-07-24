import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../widgets/dashboard_card.dart';
import '../models/vehicle.dart';
import '../screens/vehicle_profile_screen.dart';
import '../dialogs/add_vehicle_dialog.dart';

class VehicleDetailsScreen extends StatefulWidget {
  const VehicleDetailsScreen({super.key});

  @override
  State<VehicleDetailsScreen> createState() => _VehicleDetailsScreenState();
}

class _VehicleDetailsScreenState extends State<VehicleDetailsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  // Sample vehicle data
  List<Vehicle> _vehicles = [
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

  List<Vehicle> get _filteredVehicles {
    if (_searchController.text.isEmpty) return _vehicles;

    final searchTerm = _searchController.text.toLowerCase();
    return _vehicles
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
              padding: const EdgeInsets.all(20),
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
                      ElevatedButton.icon(
                        onPressed: () => _showAddVehicleDialog(),
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
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
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
    );
  }

  Widget _buildAllVehiclesTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _filteredVehicles.length,
      itemBuilder: (context, index) {
        final vehicle = _filteredVehicles[index];
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
}
