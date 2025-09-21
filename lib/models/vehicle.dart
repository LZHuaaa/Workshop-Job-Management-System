import 'package:cloud_firestore/cloud_firestore.dart';

import 'customer.dart';
import 'service_record.dart';

class Vehicle {
  final String id;
  final String make;
  final String model;
  final int year;
  final String licensePlate;
  final String vin;
  final String color;
  final int mileage;
  final String customerId; // Reference to Customer - don't duplicate customer data
  final DateTime createdAt;
  final DateTime? lastServiceDate;
  final List<String> serviceHistoryIds;
  final List<String> photos;
  final String? notes;

  // Temporary customer properties for creation/editing - not stored in database
  final String? customerName;
  final String? customerPhone;
  final String? customerEmail;

  Vehicle({
    required this.id,
    required this.make,
    required this.model,
    required this.year,
    required this.licensePlate,
    required this.vin,
    required this.color,
    required this.mileage,
    required this.customerId,
    required this.createdAt,
    this.lastServiceDate,
    this.serviceHistoryIds = const [],
    this.photos = const [],
    this.notes,
    this.customerName,
    this.customerPhone,
    this.customerEmail,
  });

  String get displayName => '$year $make $model';
  String get fullDisplayName => '$year $make $model - $licensePlate';

  bool get needsService {
    if (lastServiceDate == null) {
      // For new vehicles, give them a grace period of 30 days from creation date
      // before marking them as needing service
      final daysSinceCreation = DateTime.now().difference(createdAt).inDays;
      return daysSinceCreation > 30; // Grace period for new vehicles
    }
    final daysSinceService = DateTime.now().difference(lastServiceDate!).inDays;
    return daysSinceService > 90; // Fallback: Needs service every 3 months
  }

  /// Enhanced service due logic that directly checks nextServiceDue dates from service records
  /// Returns true if ANY service record has a nextServiceDue date that is overdue
  bool needsServiceWithRecords(List<ServiceRecord> serviceRecords) {
    if (serviceRecords.isEmpty) {
      // No service history - use the original 90-day logic as fallback
      return needsService;
    }

    final now = DateTime.now();
    
    // Direct check: if ANY service record has nextServiceDue that is overdue, return true
    return serviceRecords.any((record) => 
      record.nextServiceDue != null && record.nextServiceDue!.isBefore(now));
  }

  /// Get the earliest next service due date from all service records
  /// Returns null if no service records have nextServiceDue dates
  DateTime? getNextServiceDue(List<ServiceRecord> serviceRecords) {
    final dueDates = serviceRecords
        .where((record) => record.nextServiceDue != null)
        .map((record) => record.nextServiceDue!)
        .toList();
    
    if (dueDates.isEmpty) return null;
    
    // Return the earliest (most urgent) next service due date
    dueDates.sort();
    return dueDates.first;
  }

  int get daysSinceLastService {
    if (lastServiceDate == null) return 0;
    return DateTime.now().difference(lastServiceDate!).inDays;
  }

  // Firestore serialization methods
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'make': make,
      'model': model,
      'year': year,
      'licensePlate': licensePlate,
      'vin': vin,
      'color': color,
      'mileage': mileage,
      'customerId': customerId, // Only store customer reference
      'createdAt': createdAt.toIso8601String(),
      'lastServiceDate': lastServiceDate?.toIso8601String(),
      'serviceHistoryIds': serviceHistoryIds,
      'photos': photos,
      'notes': notes,
    };
  }

  factory Vehicle.fromMap(Map<String, dynamic> map) {
    return Vehicle(
      id: map['id'] ?? '',
      make: map['make'] ?? '',
      model: map['model'] ?? '',
      year: map['year'] ?? 0,
      licensePlate: map['licensePlate'] ?? '',
      vin: map['vin'] ?? '',
      color: map['color'] ?? '',
      mileage: map['mileage'] ?? 0,
      customerId: map['customerId'] ?? '',
      createdAt: _parseDateTime(map['createdAt']),
      lastServiceDate: map['lastServiceDate'] != null
          ? _parseDateTime(map['lastServiceDate'])
          : null,
      serviceHistoryIds: List<String>.from(map['serviceHistoryIds'] ?? []),
      photos: List<String>.from(map['photos'] ?? []),
      notes: map['notes'],
    );
  }

  // Helper method to parse DateTime from various formats
  static DateTime _parseDateTime(dynamic dateValue) {
    if (dateValue == null) {
      return DateTime.now();
    }

    if (dateValue is Timestamp) {
      return dateValue.toDate();
    }

    if (dateValue is String) {
      return DateTime.parse(dateValue);
    }

    if (dateValue is DateTime) {
      return dateValue;
    }

    // Fallback to current time if we can't parse
    return DateTime.now();
  }

  Vehicle copyWith({
    String? id,
    String? make,
    String? model,
    int? year,
    String? licensePlate,
    String? vin,
    String? color,
    int? mileage,
    String? customerId,
    DateTime? createdAt,
    DateTime? lastServiceDate,
    List<String>? serviceHistoryIds,
    List<String>? photos,
    String? notes,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
  }) {
    return Vehicle(
      id: id ?? this.id,
      make: make ?? this.make,
      model: model ?? this.model,
      year: year ?? this.year,
      licensePlate: licensePlate ?? this.licensePlate,
      vin: vin ?? this.vin,
      color: color ?? this.color,
      mileage: mileage ?? this.mileage,
      customerId: customerId ?? this.customerId,
      createdAt: createdAt ?? this.createdAt,
      lastServiceDate: lastServiceDate ?? this.lastServiceDate,
      serviceHistoryIds: serviceHistoryIds ?? this.serviceHistoryIds,
      photos: photos ?? this.photos,
      notes: notes ?? this.notes,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerEmail: customerEmail ?? this.customerEmail,
    );
  }
}

// Extended Vehicle class for UI display that includes customer data
class VehicleWithCustomer extends Vehicle {
  final String customerName;
  final String customerPhone;
  final String customerEmail;

  VehicleWithCustomer({
    required String id,
    required String make,
    required String model,
    required int year,
    required String licensePlate,
    required String vin,
    required String color,
    required int mileage,
    required String customerId,
    required DateTime createdAt,
    DateTime? lastServiceDate,
    List<String> serviceHistoryIds = const [],
    List<String> photos = const [],
    String? notes,
    required this.customerName,
    required this.customerPhone,
    required this.customerEmail,
  }) : super(
          id: id,
          make: make,
          model: model,
          year: year,
          licensePlate: licensePlate,
          vin: vin,
          color: color,
          mileage: mileage,
          customerId: customerId,
          createdAt: createdAt,
                lastServiceDate: lastServiceDate,
      serviceHistoryIds: serviceHistoryIds,
      photos: photos,
          notes: notes,
        );

  // Factory method to create VehicleWithCustomer from Vehicle and Customer
  factory VehicleWithCustomer.fromVehicleAndCustomer(
    Vehicle vehicle,
    Customer customer,
  ) {
    return VehicleWithCustomer(
      id: vehicle.id,
      make: vehicle.make,
      model: vehicle.model,
      year: vehicle.year,
      licensePlate: vehicle.licensePlate,
      vin: vehicle.vin,
      color: vehicle.color,
      mileage: vehicle.mileage,
      customerId: vehicle.customerId,
      createdAt: vehicle.createdAt,
      lastServiceDate: vehicle.lastServiceDate,
      serviceHistoryIds: vehicle.serviceHistoryIds,
      photos: vehicle.photos,
      notes: vehicle.notes,
      customerName: customer.fullName,
      customerPhone: customer.phone,
      customerEmail: customer.email,
    );
  }
}
