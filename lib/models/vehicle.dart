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
      serviceHistory: serviceHistory ?? this.serviceHistory,
      photos: photos ?? this.photos,
      notes: notes ?? this.notes,
    );
  }
}

class ServiceRecord {
  final String id;
  final DateTime date;
  final int mileage;
  final String serviceType;
  final String description;
  final List<String> partsUsed;
  final double laborHours;
  final double totalCost;
  final String mechanicName;
  final String? notes;

  ServiceRecord({
    required this.id,
    required this.date,
    required this.mileage,
    required this.serviceType,
    required this.description,
    required this.partsUsed,
    required this.laborHours,
    required this.totalCost,
    required this.mechanicName,
    this.notes,
  });

  ServiceRecord copyWith({
    String? id,
    DateTime? date,
    int? mileage,
    String? serviceType,
    String? description,
    List<String>? partsUsed,
    double? laborHours,
    double? totalCost,
    String? mechanicName,
    String? notes,
  }) {
    return ServiceRecord(
      id: id ?? this.id,
      date: date ?? this.date,
      mileage: mileage ?? this.mileage,
      serviceType: serviceType ?? this.serviceType,
      description: description ?? this.description,
      partsUsed: partsUsed ?? this.partsUsed,
      laborHours: laborHours ?? this.laborHours,
      totalCost: totalCost ?? this.totalCost,
      mechanicName: mechanicName ?? this.mechanicName,
      notes: notes ?? this.notes,
    );
  }
}
