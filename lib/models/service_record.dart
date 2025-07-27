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
