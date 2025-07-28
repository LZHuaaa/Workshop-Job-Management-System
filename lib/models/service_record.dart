import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceRecord {
  final String id;
  final String customerId;
  final String vehicleId;
  final DateTime serviceDate;
  final String serviceType;
  final String description;
  final List<String> servicesPerformed;
  final double cost;
  final String mechanicName;
  final ServiceStatus status;
  final DateTime? nextServiceDue;
  final int mileage;
  final List<String> partsReplaced;
  final String notes;

  ServiceRecord({
    required this.id,
    required this.customerId,
    required this.vehicleId,
    required this.serviceDate,
    required this.serviceType,
    required this.description,
    this.servicesPerformed = const [],
    required this.cost,
    required this.mechanicName,
    this.status = ServiceStatus.completed,
    this.nextServiceDue,
    this.mileage = 0,
    this.partsReplaced = const [],
    this.notes = '',
  });

  // Firestore serialization methods
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'vehicleId': vehicleId,
      'serviceDate': serviceDate.toIso8601String(),
      'serviceType': serviceType,
      'description': description,
      'servicesPerformed': servicesPerformed,
      'cost': cost,
      'mechanicName': mechanicName,
      'status': status.name,
      'nextServiceDue': nextServiceDue?.toIso8601String(),
      'mileage': mileage,
      'partsReplaced': partsReplaced,
      'notes': notes,
    };
  }

  factory ServiceRecord.fromMap(Map<String, dynamic> map) {
    return ServiceRecord(
      id: map['id'] ?? '',
      customerId: map['customerId'] ?? '',
      vehicleId: map['vehicleId'] ?? '',
      serviceDate: _parseDateTime(map['serviceDate']),
      serviceType: map['serviceType'] ?? '',
      description: map['description'] ?? '',
      servicesPerformed: List<String>.from(map['servicesPerformed'] ?? []),
      cost: (map['cost'] ?? 0.0).toDouble(),
      mechanicName: map['mechanicName'] ?? '',
      status: ServiceStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ServiceStatus.completed,
      ),
      nextServiceDue: map['nextServiceDue'] != null
          ? _parseDateTime(map['nextServiceDue'])
          : null,
      mileage: map['mileage'] ?? 0,
      partsReplaced: List<String>.from(map['partsReplaced'] ?? []),
      notes: map['notes'] ?? '',
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

  ServiceRecord copyWith({
    String? id,
    String? customerId,
    String? vehicleId,
    DateTime? serviceDate,
    String? serviceType,
    String? description,
    List<String>? servicesPerformed,
    double? cost,
    String? mechanicName,
    ServiceStatus? status,
    DateTime? nextServiceDue,
    int? mileage,
    List<String>? partsReplaced,
    String? notes,
  }) {
    return ServiceRecord(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      vehicleId: vehicleId ?? this.vehicleId,
      serviceDate: serviceDate ?? this.serviceDate,
      serviceType: serviceType ?? this.serviceType,
      description: description ?? this.description,
      servicesPerformed: servicesPerformed ?? this.servicesPerformed,
      cost: cost ?? this.cost,
      mechanicName: mechanicName ?? this.mechanicName,
      status: status ?? this.status,
      nextServiceDue: nextServiceDue ?? this.nextServiceDue,
      mileage: mileage ?? this.mileage,
      partsReplaced: partsReplaced ?? this.partsReplaced,
      notes: notes ?? this.notes,
    );
  }
}

enum ServiceStatus {
  scheduled,
  inProgress,
  completed,
  cancelled,
}

extension ServiceStatusExtension on ServiceStatus {
  String get displayName {
    switch (this) {
      case ServiceStatus.scheduled:
        return 'Scheduled';
      case ServiceStatus.inProgress:
        return 'In Progress';
      case ServiceStatus.completed:
        return 'Completed';
      case ServiceStatus.cancelled:
        return 'Cancelled';
    }
  }
}
