import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/vehicle.dart';
import '../models/service_record.dart';

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
        vehicle.serviceHistoryIds.length,
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
        'serviceHistoryIds': vehicle.serviceHistoryIds,
        'serviceHistory': [], // Service history is now stored separately in service_records collection
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
          serviceHistoryIds: [], // Service history would need separate import
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

        // Parse service history IDs (service records are now stored separately)
        final List<String> serviceHistoryIds = [];
        if (data.containsKey('serviceHistoryIds') &&
            data['serviceHistoryIds'] is List) {
          serviceHistoryIds.addAll(List<String>.from(data['serviceHistoryIds']));
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
          serviceHistoryIds: serviceHistoryIds,
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

  // Generate vehicle report as PDF
  Future<String> generateVehicleReport(List<Vehicle> vehicles) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final formatter = DateFormat('MMMM dd, yyyy');

    // Calculate statistics
    final serviceDueCount = vehicles.where((v) => v.needsService).length;
    final averageAge = vehicles.isNotEmpty
        ? vehicles.fold(0, (sum, v) => sum + (now.year - v.year)) / vehicles.length
        : 0;
    final totalMileage = vehicles.fold(0, (sum, v) => sum + v.mileage);

    // Vehicle breakdown by make
    final makeCount = <String, int>{};
    for (final vehicle in vehicles) {
      makeCount[vehicle.make] = (makeCount[vehicle.make] ?? 0) + 1;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'VEHICLE FLEET REPORT',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'Generated: ${formatter.format(now)}',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Summary Statistics
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'FLEET SUMMARY',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Total Vehicles: ${vehicles.length}'),
                          pw.Text('Vehicles Needing Service: $serviceDueCount'),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Average Fleet Age: ${averageAge.toStringAsFixed(1)} years'),
                          pw.Text('Total Fleet Mileage: ${NumberFormat('#,###').format(totalMileage)} miles'),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Vehicles by Make
            pw.Text(
              'VEHICLES BY MAKE',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Table.fromTextArray(
              headers: ['Make', 'Count', 'Percentage'],
              data: makeCount.entries.map((entry) {
                final percentage = (entry.value / vehicles.length * 100).toStringAsFixed(1);
                return [entry.key, entry.value.toString(), '$percentage%'];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellHeight: 25,
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.center,
                2: pw.Alignment.center,
              },
            ),
            pw.SizedBox(height: 20),

            // Service Due Vehicles
            if (serviceDueCount > 0) ...[
              pw.Text(
                'VEHICLES REQUIRING SERVICE',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.red,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Table.fromTextArray(
                headers: ['Vehicle', 'License Plate', 'Days Overdue', 'Customer'],
                data: vehicles.where((v) => v.needsService).map((vehicle) {
                  final daysSinceService = vehicle.lastServiceDate != null
                      ? now.difference(vehicle.lastServiceDate!).inDays
                      : 365;
                  return [
                    vehicle.displayName,
                    vehicle.licensePlate,
                    daysSinceService.toString(),
                    vehicle.customerName ?? 'Unknown',
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                cellHeight: 25,
              ),
              pw.SizedBox(height: 20),
            ],

            // Detailed Vehicle List
            pw.Text(
              'DETAILED VEHICLE LIST',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),
            ...vehicles.map((vehicle) => pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 15),
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        vehicle.displayName,
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: pw.BoxDecoration(
                          color: vehicle.needsService ? PdfColors.red100 : PdfColors.green100,
                          borderRadius: pw.BorderRadius.circular(12),
                        ),
                        child: pw.Text(
                          vehicle.needsService ? 'SERVICE DUE' : 'UP TO DATE',
                          style: pw.TextStyle(
                            fontSize: 10,
                            color: vehicle.needsService ? PdfColors.red : PdfColors.green,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 8),
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('License: ${vehicle.licensePlate}', style: const pw.TextStyle(fontSize: 12)),
                            pw.Text('VIN: ${vehicle.vin}', style: const pw.TextStyle(fontSize: 12)),
                            pw.Text('Customer: ${vehicle.customerName ?? 'Unknown'}', style: const pw.TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('Mileage: ${NumberFormat('#,###').format(vehicle.mileage)} miles', style: const pw.TextStyle(fontSize: 12)),
                            pw.Text('Last Service: ${vehicle.lastServiceDate != null ? formatter.format(vehicle.lastServiceDate!) : 'Never'}', style: const pw.TextStyle(fontSize: 12)),
                            pw.Text('Color: ${vehicle.color}', style: const pw.TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )).toList(),
          ];
        },
      ),
    );

    // Save PDF to file
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(now);
    final fileName = 'vehicle_report_$timestamp.pdf';
    final file = File('${directory.path}/$fileName');

    await file.writeAsBytes(await pdf.save());

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

    return dir
        .listSync()
        .where((file) =>
            file.path.contains('vehicles_export_') ||
            file.path.contains('vehicle_report_'))
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
