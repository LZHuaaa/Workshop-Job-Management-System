import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../models/vehicle.dart';

class VehicleSearchFilter extends StatefulWidget {
  final List<Vehicle> vehicles;
  final Function(List<Vehicle>) onFilterApplied;

  const VehicleSearchFilter({
    super.key,
    required this.vehicles,
    required this.onFilterApplied,
  });

  @override
  State<VehicleSearchFilter> createState() => _VehicleSearchFilterState();
}

class _VehicleSearchFilterState extends State<VehicleSearchFilter> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _vinController = TextEditingController();
  final TextEditingController _licensePlateController = TextEditingController();
  
  String? _selectedMake;
  String? _selectedModel;
  int? _selectedYear;
  String? _selectedColor;
  bool _serviceOverdue = false;
  bool _hasPhotos = false;
  
  List<String> _availableMakes = [];
  List<String> _availableModels = [];
  List<int> _availableYears = [];
  List<String> _availableColors = [];

  @override
  void initState() {
    super.initState();
    _extractFilterOptions();
  }

  void _extractFilterOptions() {
    final makes = widget.vehicles.map((v) => v.make).toSet().toList();
    final models = widget.vehicles.map((v) => v.model).toSet().toList();
    final years = widget.vehicles.map((v) => v.year).toSet().toList();
    final colors = widget.vehicles.map((v) => v.color).toSet().toList();
    
    setState(() {
      _availableMakes = makes..sort();
      _availableModels = models..sort();
      _availableYears = years..sort((a, b) => b.compareTo(a)); // Newest first
      _availableColors = colors..sort();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Search & Filter Vehicles',
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
          TextButton(
            onPressed: _clearAllFilters,
            child: Text(
              'Clear All',
              style: GoogleFonts.poppins(
                color: AppColors.primaryPink,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSearchSection(),
                  const SizedBox(height: 24),
                  _buildVehicleSpecsSection(),
                  const SizedBox(height: 24),
                  _buildIdentificationSection(),
                  const SizedBox(height: 24),
                  _buildStatusSection(),
                ],
              ),
            ),
          ),
          _buildBottomActions(),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'General Search',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 12),
        Container(
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
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by customer name, license plate, or VIN...',
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
            onChanged: (value) => _applyFilters(),
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleSpecsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vehicle Specifications',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 12),
        Container(
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
            children: [
              // Make and Model dropdowns in separate rows to prevent overflow
              _buildDropdown(
                'Make',
                _selectedMake,
                _availableMakes,
                (value) => setState(() {
                  _selectedMake = value;
                  _applyFilters();
                }),
              ),
              const SizedBox(height: 16),
              _buildDropdown(
                'Model',
                _selectedModel,
                _availableModels,
                (value) => setState(() {
                  _selectedModel = value;
                  _applyFilters();
                }),
              ),
              const SizedBox(height: 16),
              _buildYearDropdown(),
              const SizedBox(height: 16),
              _buildDropdown(
                'Color',
                _selectedColor,
                _availableColors,
                (value) => setState(() {
                  _selectedColor = value;
                  _applyFilters();
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIdentificationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vehicle Identification',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 12),
        Container(
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
            children: [
              TextField(
                controller: _vinController,
                decoration: InputDecoration(
                  labelText: 'VIN',
                  hintText: 'Enter VIN to search',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.confirmation_number),
                ),
                textCapitalization: TextCapitalization.characters,
                onChanged: (value) => _applyFilters(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _licensePlateController,
                decoration: InputDecoration(
                  labelText: 'License Plate',
                  hintText: 'Enter license plate',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.local_taxi),
                ),
                textCapitalization: TextCapitalization.characters,
                onChanged: (value) => _applyFilters(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vehicle Status',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 12),
        Container(
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
            children: [
              CheckboxListTile(
                title: Text(
                  'Service Overdue',
                  style: GoogleFonts.poppins(),
                ),
                subtitle: Text(
                  'Show vehicles that need service',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                value: _serviceOverdue,
                onChanged: (value) {
                  setState(() {
                    _serviceOverdue = value ?? false;
                    _applyFilters();
                  });
                },
                activeColor: AppColors.primaryPink,
                contentPadding: EdgeInsets.zero,
              ),
              CheckboxListTile(
                title: Text(
                  'Has Photos',
                  style: GoogleFonts.poppins(),
                ),
                subtitle: Text(
                  'Show vehicles with photos only',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                value: _hasPhotos,
                onChanged: (value) {
                  setState(() {
                    _hasPhotos = value ?? false;
                    _applyFilters();
                  });
                },
                activeColor: AppColors.primaryPink,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(
    String label,
    String? value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      items: [
        DropdownMenuItem<String>(
          value: null,
          child: Text(
            'Any $label',
            style: GoogleFonts.poppins(color: AppColors.textSecondary),
          ),
        ),
        ...items.map((item) => DropdownMenuItem<String>(
              value: item,
              child: Text(item, style: GoogleFonts.poppins()),
            )),
      ],
      onChanged: onChanged,
    );
  }

  Widget _buildYearDropdown() {
    return DropdownButtonFormField<int>(
      value: _selectedYear,
      decoration: InputDecoration(
        labelText: 'Year',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      items: [
        DropdownMenuItem<int>(
          value: null,
          child: Text(
            'Any Year',
            style: GoogleFonts.poppins(color: AppColors.textSecondary),
          ),
        ),
        ..._availableYears.map((year) => DropdownMenuItem<int>(
              value: year,
              child: Text(year.toString(), style: GoogleFonts.poppins()),
            )),
      ],
      onChanged: (value) => setState(() {
        _selectedYear = value;
        _applyFilters();
      }),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _clearAllFilters,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.primaryPink),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                'Clear Filters',
                style: GoogleFonts.poppins(
                  color: AppColors.primaryPink,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPink,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                'Apply Filters',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _applyFilters() {
    List<Vehicle> filteredVehicles = widget.vehicles.where((vehicle) {
      // General search
      if (_searchController.text.isNotEmpty) {
        final searchTerm = _searchController.text.toLowerCase();
        if (!(vehicle.customerName?.toLowerCase().contains(searchTerm) ?? false) &&
            !vehicle.licensePlate.toLowerCase().contains(searchTerm) &&
            !vehicle.vin.toLowerCase().contains(searchTerm) &&
            !vehicle.displayName.toLowerCase().contains(searchTerm)) {
          return false;
        }
      }

      // Make filter
      if (_selectedMake != null && vehicle.make != _selectedMake) {
        return false;
      }

      // Model filter
      if (_selectedModel != null && vehicle.model != _selectedModel) {
        return false;
      }

      // Year filter
      if (_selectedYear != null && vehicle.year != _selectedYear) {
        return false;
      }

      // Color filter
      if (_selectedColor != null && vehicle.color != _selectedColor) {
        return false;
      }

      // VIN filter
      if (_vinController.text.isNotEmpty) {
        if (!vehicle.vin.toLowerCase().contains(_vinController.text.toLowerCase())) {
          return false;
        }
      }

      // License plate filter
      if (_licensePlateController.text.isNotEmpty) {
        if (!vehicle.licensePlate.toLowerCase().contains(_licensePlateController.text.toLowerCase())) {
          return false;
        }
      }

      // Service overdue filter
      if (_serviceOverdue && !vehicle.needsService) {
        return false;
      }

      // Has photos filter
      if (_hasPhotos && vehicle.photos.isEmpty) {
        return false;
      }

      return true;
    }).toList();

    widget.onFilterApplied(filteredVehicles);
  }

  void _clearAllFilters() {
    setState(() {
      _searchController.clear();
      _vinController.clear();
      _licensePlateController.clear();
      _selectedMake = null;
      _selectedModel = null;
      _selectedYear = null;
      _selectedColor = null;
      _serviceOverdue = false;
      _hasPhotos = false;
    });
    widget.onFilterApplied(widget.vehicles);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _vinController.dispose();
    _licensePlateController.dispose();
    super.dispose();
  }
}
