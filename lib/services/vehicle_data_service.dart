import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/vehicle.dart';

class VehicleDataService {
  static final VehicleDataService _instance = VehicleDataService._internal();
  factory VehicleDataService() => _instance;
  VehicleDataService._internal();

  // Export vehicles to CSV format
  Future<String> exportVehiclesToCSV(List<Vehicle> vehicles) async {
    final List<List<dynamic>> csvData = [];
    
    // Add headers
    csvData.add([
      'ID',
      'Make',
      'Model',
      'Year',
      'License Plate',
      'VIN',
      'Color',
      'Mileage',
      'Customer ID',
      'Customer Name',
      'Customer Phone',
      'Customer Email',
      'Created Date',
      'Last Service Date',
      'Service History Count',
      'Photos Count',
      'Notes',
      'Needs Service',
    ]);

    // Add vehicle data
    for (final vehicle in vehicles) {
      csvData.add([
        vehicle.id,
        vehicle.make,
        vehicle.model,
        vehicle.year,
        vehicle.licensePlate,
        vehicle.vin,
        vehicle.color,
        vehicle.mileage,
        vehicle.customerId,
        vehicle.customerName,
        vehicle.customerPhone,
        vehicle.customerEmail,
        DateFormat('yyyy-MM-dd HH:mm:ss').format(vehicle.createdAt),
        vehicle.lastServiceDate != null 
            ? DateFormat('yyyy-MM-dd HH:mm:ss').format(vehicle.lastServiceDate!)
            : '',
        vehicle.serviceHistory.length,
        vehicle.photos.length,
        vehicle.notes ?? '',
        vehicle.needsService ? 'Yes' : 'No',
      ]);
    }

    // Convert to CSV string
    final csvString = const ListToCsvConverter().convert(csvData);
    
    // Save to file
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'vehicles_export_$timestamp.csv';
    final file = File('${directory.path}/$fileName');
    
    await file.writeAsString(csvString);
    
    return file.path;
  }

  // Export vehicles to JSON format
  Future<String> exportVehiclesToJSON(List<Vehicle> vehicles) async {
    final List<Map<String, dynamic>> jsonData = [];
    
    for (final vehicle in vehicles) {
      jsonData.add({
        'id': vehicle.id,
        'make': vehicle.make,
        'model': vehicle.model,
        'year': vehicle.year,
        'licensePlate': vehicle.licensePlate,
        'vin': vehicle.vin,
        'color': vehicle.color,
        'mileage': vehicle.mileage,
        'customerId': vehicle.customerId,
        'customerName': vehicle.customerName,
        'customerPhone': vehicle.customerPhone,
        'customerEmail': vehicle.customerEmail,
        'createdAt': vehicle.createdAt.toIso8601String(),
        'lastServiceDate': vehicle.lastServiceDate?.toIso8601String(),
        'serviceHistory': vehicle.serviceHistory.map((service) => {
          'id': service.id,
          'date': service.date.toIso8601String(),
          'mileage': service.mileage,
          'serviceType': service.serviceType,
          'description': service.description,
          'partsUsed': service.partsUsed,
          'laborHours': service.laborHours,
          'totalCost': service.totalCost,
          'mechanicName': service.mechanicName,
        }).toList(),
        'photos': vehicle.photos,
        'notes': vehicle.notes,
      });
    }
    
    final jsonString = const JsonEncoder.withIndent('  ').convert({
      'exportDate': DateTime.now().toIso8601String(),
      'totalVehicles': vehicles.length,
      'vehicles': jsonData,
    });
    
    // Save to file
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'vehicles_export_$timestamp.json';
    final file = File('${directory.path}/$fileName');
    
    await file.writeAsString(jsonString);
    
    return file.path;
  }

  // Share exported file
  Future<void> shareExportedFile(String filePath, String format) async {
    final file = File(filePath);
    if (await file.exists()) {
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Vehicle data export in $format format',
        subject: 'Vehicle Database Export',
      );
    } else {
      throw Exception('Export file not found');
    }
  }

  // Import vehicles from CSV
  Future<List<Vehicle>> importVehiclesFromCSV(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('Import file not found');
    }

    final csvString = await file.readAsString();
    final csvData = const CsvToListConverter().convert(csvString);
    
    if (csvData.isEmpty) {
      throw Exception('CSV file is empty');
    }

    // Skip header row
    final dataRows = csvData.skip(1);
    final List<Vehicle> vehicles = [];

    for (final row in dataRows) {
      try {
        if (row.length < 18) {
          continue; // Skip incomplete rows
        }

        final vehicle = Vehicle(
          id: row[0].toString(),
          make: row[1].toString(),
          model: row[2].toString(),
          year: int.tryParse(row[3].toString()) ?? DateTime.now().year,
          licensePlate: row[4].toString(),
          vin: row[5].toString(),
          color: row[6].toString(),
          mileage: int.tryParse(row[7].toString()) ?? 0,
          customerId: row[8].toString(),
          customerName: row[9].toString(),
          customerPhone: row[10].toString(),
          customerEmail: row[11].toString(),
          createdAt: _parseDateTime(row[12].toString()) ?? DateTime.now(),
          lastServiceDate: _parseDateTime(row[13].toString()),
          serviceHistory: [], // Service history would need separate import
          photos: [], // Photos would need separate handling
          notes: row[16].toString().isEmpty ? null : row[16].toString(),
        );

        vehicles.add(vehicle);
      } catch (e) {
        // Skip invalid rows and continue
        print('Error parsing row: $e');
        continue;
      }
    }

    return vehicles;
  }

  // Import vehicles from JSON
  Future<List<Vehicle>> importVehiclesFromJSON(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('Import file not found');
    }

    final jsonString = await file.readAsString();
    final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
    
    if (!jsonData.containsKey('vehicles')) {
      throw Exception('Invalid JSON format - missing vehicles array');
    }

    final vehiclesData = jsonData['vehicles'] as List<dynamic>;
    final List<Vehicle> vehicles = [];

    for (final vehicleData in vehiclesData) {
      try {
        final data = vehicleData as Map<String, dynamic>;
        
        // Parse service history
        final List<ServiceRecord> serviceHistory = [];
        if (data.containsKey('serviceHistory') && data['serviceHistory'] is List) {
          for (final serviceData in data['serviceHistory'] as List<dynamic>) {
            final service = serviceData as Map<String, dynamic>;
            serviceHistory.add(ServiceRecord(
              id: service['id'].toString(),
              date: DateTime.parse(service['date'].toString()),
              mileage: service['mileage'] as int,
              serviceType: service['serviceType'].toString(),
              description: service['description'].toString(),
              partsUsed: List<String>.from(service['partsUsed'] as List),
              laborHours: (service['laborHours'] as num).toDouble(),
              totalCost: (service['totalCost'] as num).toDouble(),
              mechanicName: service['mechanicName'].toString(),
            ));
          }
        }

        final vehicle = Vehicle(
          id: data['id'].toString(),
          make: data['make'].toString(),
          model: data['model'].toString(),
          year: data['year'] as int,
          licensePlate: data['licensePlate'].toString(),
          vin: data['vin'].toString(),
          color: data['color'].toString(),
          mileage: data['mileage'] as int,
          customerId: data['customerId'].toString(),
          customerName: data['customerName'].toString(),
          customerPhone: data['customerPhone'].toString(),
          customerEmail: data['customerEmail'].toString(),
          createdAt: DateTime.parse(data['createdAt'].toString()),
          lastServiceDate: data['lastServiceDate'] != null 
              ? DateTime.parse(data['lastServiceDate'].toString())
              : null,
          serviceHistory: serviceHistory,
          photos: List<String>.from(data['photos'] as List? ?? []),
          notes: data['notes']?.toString(),
        );

        vehicles.add(vehicle);
      } catch (e) {
        // Skip invalid entries and continue
        print('Error parsing vehicle data: $e');
        continue;
      }
    }

    return vehicles;
  }

  // Generate vehicle report
  Future<String> generateVehicleReport(List<Vehicle> vehicles) async {
    final buffer = StringBuffer();
    final now = DateTime.now();
    final formatter = DateFormat('MMMM dd, yyyy');
    
    // Report header
    buffer.writeln('VEHICLE FLEET REPORT');
    buffer.writeln('Generated on: ${formatter.format(now)}');
    buffer.writeln('=' * 50);
    buffer.writeln();
    
    // Summary statistics
    buffer.writeln('FLEET SUMMARY');
    buffer.writeln('-' * 20);
    buffer.writeln('Total Vehicles: ${vehicles.length}');
    
    final serviceDueCount = vehicles.where((v) => v.needsService).length;
    buffer.writeln('Vehicles Needing Service: $serviceDueCount');
    
    final averageAge = vehicles.isNotEmpty 
        ? vehicles.fold(0, (sum, v) => sum + (now.year - v.year)) / vehicles.length
        : 0;
    buffer.writeln('Average Fleet Age: ${averageAge.toStringAsFixed(1)} years');
    
    final totalMileage = vehicles.fold(0, (sum, v) => sum + v.mileage);
    buffer.writeln('Total Fleet Mileage: ${NumberFormat('#,###').format(totalMileage)} miles');
    buffer.writeln();
    
    // Vehicle breakdown by make
    final makeCount = <String, int>{};
    for (final vehicle in vehicles) {
      makeCount[vehicle.make] = (makeCount[vehicle.make] ?? 0) + 1;
    }
    
    buffer.writeln('VEHICLES BY MAKE');
    buffer.writeln('-' * 20);
    for (final entry in makeCount.entries) {
      buffer.writeln('${entry.key}: ${entry.value}');
    }
    buffer.writeln();
    
    // Service due vehicles
    if (serviceDueCount > 0) {
      buffer.writeln('VEHICLES REQUIRING SERVICE');
      buffer.writeln('-' * 30);
      for (final vehicle in vehicles.where((v) => v.needsService)) {
        final daysSinceService = vehicle.lastServiceDate != null
            ? now.difference(vehicle.lastServiceDate!).inDays
            : 365;
        buffer.writeln('${vehicle.displayName} (${vehicle.licensePlate}) - $daysSinceService days overdue');
      }
      buffer.writeln();
    }
    
    // Detailed vehicle list
    buffer.writeln('DETAILED VEHICLE LIST');
    buffer.writeln('-' * 25);
    for (final vehicle in vehicles) {
      buffer.writeln(vehicle.displayName);
      buffer.writeln('  License Plate: ${vehicle.licensePlate}');
      buffer.writeln('  VIN: ${vehicle.vin}');
      buffer.writeln('  Customer: ${vehicle.customerName}');
      buffer.writeln('  Mileage: ${NumberFormat('#,###').format(vehicle.mileage)} miles');
      buffer.writeln('  Last Service: ${vehicle.lastServiceDate != null ? formatter.format(vehicle.lastServiceDate!) : 'Never'}');
      buffer.writeln('  Service Status: ${vehicle.needsService ? 'DUE' : 'Up to Date'}');
      buffer.writeln();
    }
    
    // Save report to file
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(now);
    final fileName = 'vehicle_report_$timestamp.txt';
    final file = File('${directory.path}/$fileName');
    
    await file.writeAsString(buffer.toString());
    
    return file.path;
  }

  // Get export/import file directory
  Future<String> getExportDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  // List all export files
  Future<List<FileSystemEntity>> getExportFiles() async {
    final directory = await getApplicationDocumentsDirectory();
    final dir = Directory(directory.path);
    
    return dir.listSync()
        .where((file) => file.path.contains('vehicles_export_') || file.path.contains('vehicle_report_'))
        .toList();
  }

  // Delete export file
  Future<void> deleteExportFile(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  // Helper method to parse DateTime from string
  DateTime? _parseDateTime(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return null;
    }
    
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      // Try different date formats
      try {
        return DateFormat('yyyy-MM-dd HH:mm:ss').parse(dateString);
      } catch (e) {
        try {
          return DateFormat('yyyy-MM-dd').parse(dateString);
        } catch (e) {
          return null;
        }
      }
    }
  }

  // Validate import file format
  Future<bool> validateImportFile(String filePath, String format) async {
    final file = File(filePath);
    if (!await file.exists()) {
      return false;
    }

    try {
      if (format.toLowerCase() == 'csv') {
        final csvString = await file.readAsString();
        final csvData = const CsvToListConverter().convert(csvString);
        return csvData.isNotEmpty && csvData.first.length >= 18;
      } else if (format.toLowerCase() == 'json') {
        final jsonString = await file.readAsString();
        final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
        return jsonData.containsKey('vehicles');
      }
    } catch (e) {
      return false;
    }

    return false;
  }
}
