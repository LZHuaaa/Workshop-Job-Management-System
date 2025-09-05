import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_colors.dart';
import '../models/vehicle.dart';
import '../models/service_record.dart';
import '../services/service_record_service.dart';
import '../widgets/dashboard_card.dart';

class VehicleAnalyticsScreen extends StatefulWidget {
  final List<Vehicle> vehicles;

  const VehicleAnalyticsScreen({
    super.key,
    required this.vehicles,
  });

  @override
  State<VehicleAnalyticsScreen> createState() => _VehicleAnalyticsScreenState();
}

class _VehicleAnalyticsScreenState extends State<VehicleAnalyticsScreen> {
  List<ServiceRecord> _allServiceRecords = [];
  bool _isLoadingServiceRecords = false;
  final ServiceRecordService _serviceRecordService = ServiceRecordService();

  @override
  void initState() {
    super.initState();
    _loadServiceRecords();
  }

  Future<void> _loadServiceRecords() async {
    if (widget.vehicles.isEmpty) return;

    setState(() {
      _isLoadingServiceRecords = true;
    });

    try {
      // Load service records in batches to improve performance
      List<ServiceRecord> allRecords = [];
      const batchSize = 5; // Process 5 vehicles at a time
      
      for (int i = 0; i < widget.vehicles.length; i += batchSize) {
        final batch = widget.vehicles.skip(i).take(batchSize);
        final futures = batch.map((vehicle) => 
          _serviceRecordService.getServiceRecordsByVehicle(vehicle.id)
        ).toList();
        
        final batchResults = await Future.wait(futures);
        for (final vehicleRecords in batchResults) {
          allRecords.addAll(vehicleRecords);
        }

        // Update UI after each batch to show progress
        if (mounted) {
          setState(() {
            _allServiceRecords = allRecords;
          });
        }
      }

      if (mounted) {
        setState(() {
          _allServiceRecords = allRecords;
          _isLoadingServiceRecords = false;
        });
      }
    } catch (e) {
      print('Error loading service records for analytics: $e');
      if (mounted) {
        setState(() {
          _isLoadingServiceRecords = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingServiceRecords && widget.vehicles.isNotEmpty) {
      return Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: AppColors.primaryPink,
              ),
              const SizedBox(height: 16),
              Text(
                'Loading Analytics...',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Processing ${widget.vehicles.length} vehicles and service records',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return _buildAnalyticsContent();
  }

  Widget _buildAnalyticsContent() {
    if (_isLoadingServiceRecords) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primaryPink),
            const SizedBox(height: 16),
            Text(
              'Loading service data for enhanced analytics...',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    final totalVehicles = widget.vehicles.length;
    final serviceDueCount = widget.vehicles.where((v) => v.needsService).length;
    final averageAge = _calculateAverageAge();
    final averageMileage = _calculateAverageMileage();
    final totalFleetValue = _calculateEstimatedFleetValue();
    final totalServiceRevenue = _calculateTotalServiceRevenue();
    final averageServiceCost = _calculateAverageServiceCost();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Key Metrics Cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Total Vehicles',
                  totalVehicles.toString(),
                  Icons.directions_car,
                  AppColors.primaryPink,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'Service Due',
                  serviceDueCount.toString(),
                  Icons.warning,
                  AppColors.warningOrange,
                ),
              ),
            ],
          ),
        
          const SizedBox(height: 16),
          if (!_isLoadingServiceRecords && _allServiceRecords.isNotEmpty) ...[
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Service Revenue',
                    'RM ${(totalServiceRevenue / 1000).toStringAsFixed(1)}k',
                    Icons.trending_up,
                    AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryCard(
                    'Avg Service Cost',
                    'RM ${averageServiceCost.toStringAsFixed(0)}',
                    Icons.build,
                    AppColors.successGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Vehicle Age Analysis
          DashboardCard(
            title: 'Fleet Age Analysis',
            subtitle: 'Age distribution helps predict maintenance needs',
            child: SizedBox(
              height: 200,
              child: _buildAgeDistributionChart(),
            ),
          ),
          const SizedBox(height: 24),

          // Maintenance Priority Dashboard
          DashboardCard(
            title: 'Maintenance Priority Dashboard',
            subtitle: 'Vehicles requiring immediate attention vs. up-to-date',
            child: SizedBox(
              height: 200,
              child: _isLoadingServiceRecords 
                ? const Center(child: CircularProgressIndicator())
                : _buildServiceStatusChart(),
            ),
          ),
          const SizedBox(height: 24),

          // Monthly Vehicle Registration Trend
          DashboardCard(
            title: 'Vehicle Registration Trend',
            subtitle: 'When vehicles were added to your fleet',
            child: SizedBox(
              height: 200,
              child: _buildRegistrationTrendChart(),
            ),
          ),
          const SizedBox(height: 24),

          // Mileage Analysis
          DashboardCard(
            title: 'Fleet Mileage Analysis',
            subtitle: 'Mileage distribution helps plan service intervals',
            child: SizedBox(
              height: 200,
              child: _buildMileageDistributionChart(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    final totalVehicles = widget.vehicles.length;
    final serviceDueCount = widget.vehicles.where((v) => v.needsService).length;
    final averageAge = _calculateAverageAge();
    final averageMileage = _calculateAverageMileage();
    final newestVehicle = _getNewestVehicle();
    final oldestVehicle = _getOldestVehicle();
    final totalFleetValue = _calculateEstimatedFleetValue();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Total Vehicles',
                  totalVehicles.toString(),
                  Icons.directions_car,
                  AppColors.primaryPink,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'Service Due',
                  serviceDueCount.toString(),
                  Icons.warning,
                  AppColors.warningOrange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Avg. Age',
                  '${averageAge.toStringAsFixed(1)} years',
                  Icons.access_time,
                  AppColors.successGreen,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'Fleet Value',
                  'RM ${(totalFleetValue / 1000).toStringAsFixed(0)}k',
                  Icons.attach_money,
                  AppColors.primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // New Analytics Row 3
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Avg Mileage',
                  '${(averageMileage / 1000).toStringAsFixed(0)}k mi',
                  Icons.speed,
                  AppColors.accentPink,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'Fleet Value',
                  'RM ${(totalFleetValue / 1000).toStringAsFixed(0)}k',
                  Icons.attach_money,
                  AppColors.successGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // New Analytics Row 4
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Newest',
                  newestVehicle,
                  Icons.new_releases,
                  AppColors.primaryPink,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'Oldest',
                  oldestVehicle,
                  Icons.history,
                  AppColors.warningOrange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Vehicle Age Distribution
          DashboardCard(
            title: 'Vehicle Age Distribution',
            child: SizedBox(
              height: 200,
              child: _buildAgeDistributionChart(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceTrendsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          DashboardCard(
            title: 'Service History Trends',
            child: SizedBox(
              height: 250,
              child: _buildServiceTrendsChart(),
            ),
          ),
          const SizedBox(height: 24),
          DashboardCard(
            title: 'Service Types Distribution',
            child: SizedBox(
              height: 200,
              child: _buildServiceTypesChart(),
            ),
          ),
          const SizedBox(height: 24),
          DashboardCard(
            title: 'Service Status Distribution',
            child: SizedBox(
              height: 200,
              child: _buildServiceStatusChart(),
            ),
          ),
          const SizedBox(height: 24),
          DashboardCard(
            title: 'Maintenance Cost by Make',
            child: SizedBox(
              height: 250,
              child: _buildMaintenanceCostChart(),
            ),
          ),
          const SizedBox(height: 24),
          DashboardCard(
            title: 'Average Service Costs',
            child: _buildServiceCostAnalysis(),
          ),
        ],
      ),
    );
  }

  Widget _buildFleetStatusTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          DashboardCard(
            title: 'Fleet Health Overview',
            child: _buildFleetHealthOverview(),
          ),
          const SizedBox(height: 24),
          DashboardCard(
            title: 'Vehicles by Year',
            child: SizedBox(
              height: 200,
              child: _buildVehiclesByYearChart(),
            ),
          ),
          const SizedBox(height: 24),
          DashboardCard(
            title: 'Mileage Distribution',
            child: SizedBox(
              height: 200,
              child: _buildMileageDistributionChart(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
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
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
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
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAgeDistributionChart() {
    final ageData = _getAgeDistribution();
    
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: ageData.values.reduce((a, b) => a > b ? a : b).toDouble() + 1,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final ranges = ageData.keys.toList();
                if (value.toInt() < ranges.length) {
                  return Text(
                    ranges[value.toInt()],
                    style: GoogleFonts.poppins(fontSize: 10),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: GoogleFonts.poppins(fontSize: 10),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: ageData.entries.map((entry) {
          final index = ageData.keys.toList().indexOf(entry.key);
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: entry.value.toDouble(),
                color: AppColors.primaryPink,
                width: 20,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildServiceTrendsChart() {
    // Placeholder for service trends - would need actual service data
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
                if (value.toInt() < months.length) {
                  return Text(
                    months[value.toInt()],
                    style: GoogleFonts.poppins(fontSize: 10),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: GoogleFonts.poppins(fontSize: 10),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: [
              const FlSpot(0, 3),
              const FlSpot(1, 5),
              const FlSpot(2, 4),
              const FlSpot(3, 7),
              const FlSpot(4, 6),
              const FlSpot(5, 8),
            ],
            isCurved: true,
            color: AppColors.primaryPink,
            barWidth: 3,
            dotData: const FlDotData(show: true),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceTypesChart() {
    // Placeholder for service types distribution
    return const Center(
      child: Text('Service Types Chart\n(Requires service history data)'),
    );
  }

  Widget _buildServiceStatusChart() {
    final statusData = _getServiceStatusDistribution();

    return PieChart(
      PieChartData(
        sections: statusData.entries.map((entry) {
          final index = statusData.keys.toList().indexOf(entry.key);
          final colors = [
            AppColors.successGreen,
            AppColors.warningOrange,
            AppColors.errorRed,
          ];

          return PieChartSectionData(
            color: colors[index % colors.length],
            value: entry.value.toDouble(),
            title: '${entry.value}',
            radius: 60,
            titleStyle: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }).toList(),
        sectionsSpace: 2,
        centerSpaceRadius: 40,
      ),
    );
  }

  Widget _buildMaintenanceCostChart() {
    final costData = _getMaintenanceCostByMake();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: costData.values.isNotEmpty
            ? costData.values.reduce((a, b) => a > b ? a : b) + 1000
            : 5000,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                final makes = costData.keys.toList();
                if (value.toInt() < makes.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      makes[value.toInt()],
                      style: GoogleFonts.poppins(fontSize: 10),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                return Text(
                  'RM${(value / 1000).toStringAsFixed(0)}k',
                  style: GoogleFonts.poppins(fontSize: 10),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: costData.entries.map((entry) {
          final index = costData.keys.toList().indexOf(entry.key);
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: entry.value,
                color: AppColors.primaryPink,
                width: 20,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildServiceCostAnalysis() {
    return Column(
      children: [
        _buildCostRow('Average Service Cost', 'RM 250.00'),
        _buildCostRow('Highest Service Cost', 'RM 850.00'),
        _buildCostRow('Lowest Service Cost', 'RM 89.99'),
        _buildCostRow('Total Service Revenue', 'RM 12,450.00'),
      ],
    );
  }

  Widget _buildCostRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.textDark,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryPink,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFleetHealthOverview() {
    final totalVehicles = widget.vehicles.length;
    final serviceDue = widget.vehicles.where((v) => v.needsService).length;
    final upToDate = totalVehicles - serviceDue;
    
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildHealthIndicator(
                'Up to Date',
                upToDate,
                totalVehicles,
                AppColors.successGreen,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildHealthIndicator(
                'Service Due',
                serviceDue,
                totalVehicles,
                AppColors.warningOrange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        LinearProgressIndicator(
          value: upToDate / totalVehicles,
          backgroundColor: AppColors.warningOrange.withOpacity(0.3),
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.successGreen),
          minHeight: 8,
        ),
        const SizedBox(height: 8),
        Text(
          '${((upToDate / totalVehicles) * 100).toStringAsFixed(1)}% of fleet is up to date',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildHealthIndicator(String label, int count, int total, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          '${((count / total) * 100).toStringAsFixed(1)}%',
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildVehiclesByYearChart() {
    final yearData = _getVehiclesByYear();
    
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: yearData.values.reduce((a, b) => a > b ? a : b).toDouble() + 1,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final years = yearData.keys.toList()..sort();
                if (value.toInt() < years.length) {
                  return Text(
                    years[value.toInt()].toString(),
                    style: GoogleFonts.poppins(fontSize: 10),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: GoogleFonts.poppins(fontSize: 10),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: yearData.entries.map((entry) {
          final years = yearData.keys.toList()..sort();
          final index = years.indexOf(entry.key);
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: entry.value.toDouble(),
                color: AppColors.accentPink,
                width: 20,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMileageDistributionChart() {
    final mileageData = _getMileageDistribution();
    
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: mileageData.values.reduce((a, b) => a > b ? a : b).toDouble() + 1,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final ranges = mileageData.keys.toList();
                if (value.toInt() < ranges.length) {
                  return Text(
                    ranges[value.toInt()],
                    style: GoogleFonts.poppins(fontSize: 8),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: GoogleFonts.poppins(fontSize: 10),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: mileageData.entries.map((entry) {
          final index = mileageData.keys.toList().indexOf(entry.key);
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: entry.value.toDouble(),
                color: AppColors.successGreen,
                width: 20,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // Helper methods for data calculation
  double _calculateAverageAge() {
    if (widget.vehicles.isEmpty) return 0;
    final currentYear = DateTime.now().year;
    final totalAge = widget.vehicles.fold(0, (sum, vehicle) => sum + (currentYear - vehicle.year));
    return totalAge / widget.vehicles.length;
  }
  Map<String, int> _getAgeDistribution() {
    final currentYear = DateTime.now().year;
    final ageRanges = <String, int>{
      '0-2 years': 0,
      '3-5 years': 0,
      '6-10 years': 0,
      '11+ years': 0,
    };
    
    for (final vehicle in widget.vehicles) {
      final age = currentYear - vehicle.year;
      if (age <= 2) {
        ageRanges['0-2 years'] = ageRanges['0-2 years']! + 1;
      } else if (age <= 5) {
        ageRanges['3-5 years'] = ageRanges['3-5 years']! + 1;
      } else if (age <= 10) {
        ageRanges['6-10 years'] = ageRanges['6-10 years']! + 1;
      } else {
        ageRanges['11+ years'] = ageRanges['11+ years']! + 1;
      }
    }
    
    return ageRanges;
  }

  Map<int, int> _getVehiclesByYear() {
    final yearCount = <int, int>{};
    for (final vehicle in widget.vehicles) {
      yearCount[vehicle.year] = (yearCount[vehicle.year] ?? 0) + 1;
    }
    return yearCount;
  }

  Map<String, int> _getMileageDistribution() {
    final mileageRanges = <String, int>{
      '0-25k': 0,
      '25-50k': 0,
      '50-75k': 0,
      '75-100k': 0,
      '100k+': 0,
    };
    
    for (final vehicle in widget.vehicles) {
      final mileage = vehicle.mileage;
      if (mileage <= 25000) {
        mileageRanges['0-25k'] = mileageRanges['0-25k']! + 1;
      } else if (mileage <= 50000) {
        mileageRanges['25-50k'] = mileageRanges['25-50k']! + 1;
      } else if (mileage <= 75000) {
        mileageRanges['50-75k'] = mileageRanges['50-75k']! + 1;
      } else if (mileage <= 100000) {
        mileageRanges['75-100k'] = mileageRanges['75-100k']! + 1;
      } else {
        mileageRanges['100k+'] = mileageRanges['100k+']! + 1;
      }
    }
    
    return mileageRanges;
  }

  // New enhanced analytics methods
  double _calculateAverageMileage() {
    if (widget.vehicles.isEmpty) return 0;
    final totalMileage = widget.vehicles.fold(0, (sum, vehicle) => sum + vehicle.mileage);
    return totalMileage / widget.vehicles.length;
  }

  String _getNewestVehicle() {
    if (widget.vehicles.isEmpty) return 'N/A';
    final newest = widget.vehicles.reduce((a, b) => a.year > b.year ? a : b);
    return '${newest.year} ${newest.make}';
  }

  String _getOldestVehicle() {
    if (widget.vehicles.isEmpty) return 'N/A';
    final oldest = widget.vehicles.reduce((a, b) => a.year < b.year ? a : b);
    return '${oldest.year} ${oldest.make}';
  }

  double _calculateEstimatedFleetValue() {
    if (widget.vehicles.isEmpty) return 0;
    // Simple estimation based on age and mileage
    // This is a basic formula - in real app you'd use actual market values
    double totalValue = 0;
    final currentYear = DateTime.now().year;

    for (final vehicle in widget.vehicles) {
      final age = currentYear - vehicle.year;
      double baseValue = 50000; // Base value in RM

      // Depreciation based on age (10% per year)
      double ageDepreciation = baseValue * (age * 0.1);

      // Depreciation based on mileage (RM 0.20 per km)
      double mileageDepreciation = vehicle.mileage * 0.2;

      double estimatedValue = baseValue - ageDepreciation - mileageDepreciation;
      if (estimatedValue < 5000) estimatedValue = 5000; // Minimum value

      totalValue += estimatedValue;
    }

    return totalValue;
  }

  double _calculateTotalServiceRevenue() {
    if (_allServiceRecords.isEmpty) return 0;
    return _allServiceRecords.fold(0, (sum, record) => sum + record.cost);
  }

  double _calculateAverageServiceCost() {
    if (_allServiceRecords.isEmpty) return 0;
    final totalCost = _allServiceRecords.fold(0.0, (sum, record) => sum + record.cost);
    return totalCost / _allServiceRecords.length;
  }

  Map<String, int> _getServiceStatusDistribution() {
    final statusCount = <String, int>{
      'Up to Date': 0,
      'Due Soon': 0,
      'Overdue': 0,
    };

    for (final vehicle in widget.vehicles) {
      if (vehicle.needsService) {
        statusCount['Overdue'] = statusCount['Overdue']! + 1;
      } else {
        // Check if service is due soon (within 30 days or 3000 miles)
        final vehicleRecords = _allServiceRecords.where((r) => r.vehicleId == vehicle.id).toList();
        if (vehicleRecords.isNotEmpty) {
          vehicleRecords.sort((a, b) => b.serviceDate.compareTo(a.serviceDate));
          final lastService = vehicleRecords.first;
          final daysSinceService = DateTime.now().difference(lastService.serviceDate).inDays;
          final milesSinceService = vehicle.mileage - lastService.mileage;
          
          // Due soon if it's been 150+ days or 4500+ miles since last service
          if (daysSinceService >= 150 || milesSinceService >= 4500) {
            statusCount['Due Soon'] = statusCount['Due Soon']! + 1;
          } else {
            statusCount['Up to Date'] = statusCount['Up to Date']! + 1;
          }
        } else {
          // No service records, consider it due soon if it's an older vehicle
          final age = DateTime.now().year - vehicle.year;
          if (age > 2) {
            statusCount['Due Soon'] = statusCount['Due Soon']! + 1;
          } else {
            statusCount['Up to Date'] = statusCount['Up to Date']! + 1;
          }
        }
      }
    }

    return statusCount;
  }

  Widget _buildRegistrationTrendChart() {
    final registrationData = _getRegistrationTrendData();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: registrationData.values.isNotEmpty
            ? registrationData.values.reduce((a, b) => a > b ? a : b).toDouble() + 1
            : 5,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                final months = registrationData.keys.toList();
                if (value.toInt() < months.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      months[value.toInt()],
                      style: GoogleFonts.poppins(fontSize: 10),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                return Text(
                  value.toInt().toString(),
                  style: GoogleFonts.poppins(fontSize: 10),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: registrationData.entries.map((entry) {
          final index = registrationData.keys.toList().indexOf(entry.key);
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: entry.value.toDouble(),
                color: AppColors.primaryPink,
                width: 20,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Map<String, int> _getRegistrationTrendData() {
    final monthCounts = <String, int>{};
    final now = DateTime.now();

    // Get last 6 months
    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final monthKey = '${month.month.toString().padLeft(2, '0')}/${month.year.toString().substring(2)}';
      monthCounts[monthKey] = 0;
    }

    for (final vehicle in widget.vehicles) {
      final createdMonth = vehicle.createdAt;
      final monthKey = '${createdMonth.month.toString().padLeft(2, '0')}/${createdMonth.year.toString().substring(2)}';
      if (monthCounts.containsKey(monthKey)) {
        monthCounts[monthKey] = monthCounts[monthKey]! + 1;
      }
    }

    return monthCounts;
  }

  Map<String, double> _getMaintenanceCostByMake() {
    final makeCosts = <String, List<double>>{};

    // If we have real service record data, use it
    if (_allServiceRecords.isNotEmpty) {
      for (final record in _allServiceRecords) {
        final vehicle = widget.vehicles.where((v) => v.id == record.vehicleId).firstOrNull;
        if (vehicle != null) {
          if (!makeCosts.containsKey(vehicle.make)) {
            makeCosts[vehicle.make] = [];
          }
          makeCosts[vehicle.make]!.add(record.cost);
        }
      }
    }

    // For makes without service records, provide estimated costs
    for (final vehicle in widget.vehicles) {
      if (!makeCosts.containsKey(vehicle.make)) {
        makeCosts[vehicle.make] = [];
      }
      
      // If no real data, estimate based on age and mileage
      if (makeCosts[vehicle.make]!.isEmpty) {
        final age = DateTime.now().year - vehicle.year;
        final estimatedCost = (age * 500) + (vehicle.mileage * 0.05);
        makeCosts[vehicle.make]!.add(estimatedCost);
      }
    }

    final averageCosts = <String, double>{};
    makeCosts.forEach((make, costs) {
      if (costs.isNotEmpty) {
        averageCosts[make] = costs.reduce((a, b) => a + b) / costs.length;
      }
    });

    return averageCosts;
  }

  double _calculateTotalRevenue() {
    return _allServiceRecords.fold(0.0, (sum, record) => sum + record.cost);
  }
}
