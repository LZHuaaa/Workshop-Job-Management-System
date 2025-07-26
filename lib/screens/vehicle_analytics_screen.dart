import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../models/vehicle.dart';
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

class _VehicleAnalyticsScreenState extends State<VehicleAnalyticsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Vehicle Analytics',
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
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryPink,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primaryPink,
          labelStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Service Trends'),
            Tab(text: 'Fleet Status'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildServiceTrendsTab(),
          _buildFleetStatusTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    final totalVehicles = widget.vehicles.length;
    final serviceDueCount = widget.vehicles.where((v) => v.needsService).length;
    final averageAge = _calculateAverageAge();
    final mostCommonMake = _getMostCommonMake();

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
                  'Top Make',
                  mostCommonMake,
                  Icons.star,
                  AppColors.accentPink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Vehicle Distribution by Make
          DashboardCard(
            title: 'Vehicle Distribution by Make',
            child: SizedBox(
              height: 200,
              child: _buildMakeDistributionChart(),
            ),
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

  Widget _buildMakeDistributionChart() {
    final makeData = _getMakeDistribution();
    
    return PieChart(
      PieChartData(
        sections: makeData.entries.map((entry) {
          final index = makeData.keys.toList().indexOf(entry.key);
          final colors = [
            AppColors.primaryPink,
            AppColors.accentPink,
            AppColors.successGreen,
            AppColors.warningOrange,
            AppColors.textSecondary,
          ];
          
          return PieChartSectionData(
            value: entry.value.toDouble(),
            title: '${entry.value}',
            color: colors[index % colors.length],
            radius: 60,
            titleStyle: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          );
        }).toList(),
        centerSpaceRadius: 40,
        sectionsSpace: 2,
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

  String _getMostCommonMake() {
    if (widget.vehicles.isEmpty) return 'N/A';
    final makeCount = <String, int>{};
    for (final vehicle in widget.vehicles) {
      makeCount[vehicle.make] = (makeCount[vehicle.make] ?? 0) + 1;
    }
    return makeCount.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  Map<String, int> _getMakeDistribution() {
    final makeCount = <String, int>{};
    for (final vehicle in widget.vehicles) {
      makeCount[vehicle.make] = (makeCount[vehicle.make] ?? 0) + 1;
    }
    return makeCount;
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
}
