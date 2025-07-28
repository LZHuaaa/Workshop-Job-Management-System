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
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String customerEmail;
  final DateTime createdAt;
  final DateTime? lastServiceDate;
  final List<String> serviceHistoryIds;
  final List<ServiceRecord> serviceHistory;
  final List<String> photos;
  final String? notes;

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
    required this.customerName,
    required this.customerPhone,
    required this.customerEmail,
    required this.createdAt,
    this.lastServiceDate,
    this.serviceHistoryIds = const [],
    this.serviceHistory = const [],
    this.photos = const [],
    this.notes,
  });

  String get displayName => '$year $make $model';
  String get fullDisplayName => '$year $make $model - $licensePlate';

  bool get needsService {
    if (lastServiceDate == null) return true;
    final daysSinceService = DateTime.now().difference(lastServiceDate!).inDays;
    return daysSinceService > 90; // Needs service every 3 months
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
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerEmail': customerEmail,
      'createdAt': createdAt.toIso8601String(),
      'lastServiceDate': lastServiceDate?.toIso8601String(),
      'serviceHistory':
          serviceHistory.map((service) => service.toMap()).toList(),
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
      customerName: map['customerName'] ?? '',
      customerPhone: map['customerPhone'] ?? '',
      customerEmail: map['customerEmail'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
      lastServiceDate: map['lastServiceDate'] != null
          ? DateTime.parse(map['lastServiceDate'])
          : null,
      serviceHistory: (map['serviceHistory'] as List?)
              ?.map((service) => ServiceRecord.fromMap(service))
              .toList() ??
          [],
      photos: List<String>.from(map['photos'] ?? []),
      notes: map['notes'],
    );
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
    String? customerName,
    String? customerPhone,
    String? customerEmail,
    DateTime? createdAt,
    DateTime? lastServiceDate,
    List<String>? serviceHistoryIds,
    List<ServiceRecord>? serviceHistory,
    List<String>? photos,
    String? notes,
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
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerEmail: customerEmail ?? this.customerEmail,
      createdAt: createdAt ?? this.createdAt,
      lastServiceDate: lastServiceDate ?? this.lastServiceDate,
      serviceHistoryIds: serviceHistoryIds ?? this.serviceHistoryIds,
      serviceHistory: serviceHistory ?? this.serviceHistory,
      photos: photos ?? this.photos,
      notes: notes ?? this.notes,
    );
  }
}
