enum JobStatus {
  scheduled,
  inProgress,
  completed,
  cancelled,
  overdue,
}

class JobAppointment {
  final String id;
  final String vehicleInfo;
  final String customerName;
  final String? vehicleId; // Actual vehicle document ID
  final String? customerId; // Actual customer document ID
  final String mechanicName;
  final DateTime startTime;
  final DateTime endTime;
  final String serviceType;
  final JobStatus status;
  final String? notes;
  final List<String>? partsNeeded;
  final double? estimatedCost;

  JobAppointment({
    required this.id,
    required this.vehicleInfo,
    required this.customerName,
    this.vehicleId,
    this.customerId,
    required this.mechanicName,
    required this.startTime,
    required this.endTime,
    required this.serviceType,
    required this.status,
    this.notes,
    this.partsNeeded,
    this.estimatedCost,
  });

  JobAppointment copyWith({
    String? id,
    String? vehicleInfo,
    String? customerName,
    String? vehicleId,
    String? customerId,
    String? mechanicName,
    DateTime? startTime,
    DateTime? endTime,
    String? serviceType,
    JobStatus? status,
    String? notes,
    List<String>? partsNeeded,
    double? estimatedCost,
  }) {
    return JobAppointment(
      id: id ?? this.id,
      vehicleInfo: vehicleInfo ?? this.vehicleInfo,
      customerName: customerName ?? this.customerName,
      vehicleId: vehicleId ?? this.vehicleId,
      customerId: customerId ?? this.customerId,
      mechanicName: mechanicName ?? this.mechanicName,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      serviceType: serviceType ?? this.serviceType,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      partsNeeded: partsNeeded ?? this.partsNeeded,
      estimatedCost: estimatedCost ?? this.estimatedCost,
    );
  }

  Duration get duration => endTime.difference(startTime);

  bool get isToday {
    final now = DateTime.now();
    return startTime.year == now.year &&
        startTime.month == now.month &&
        startTime.day == now.day;
  }

  bool get isOverdue {
    return endTime.isBefore(DateTime.now()) && status != JobStatus.completed;
  }

  // Convert from Firestore map
  factory JobAppointment.fromMap(Map<String, dynamic> map) {
    return JobAppointment(
      id: map['id'] ?? '',
      vehicleInfo: map['vehicleInfo'] ?? '',
      customerName: map['customerName'] ?? '',
      vehicleId: map['vehicleId'],
      customerId: map['customerId'],
      mechanicName: map['mechanicName'] ?? '',
      startTime: map['startTime'] is DateTime
          ? map['startTime']
          : DateTime.parse(map['startTime'].toString()),
      endTime: map['endTime'] is DateTime
          ? map['endTime']
          : DateTime.parse(map['endTime'].toString()),
      serviceType: map['serviceType'] ?? '',
      status: JobStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => JobStatus.scheduled,
      ),
      notes: map['notes'],
      partsNeeded: map['partsNeeded'] != null
          ? List<String>.from(map['partsNeeded'])
          : null,
      estimatedCost: map['estimatedCost']?.toDouble(),
    );
  }

  // Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vehicleInfo': vehicleInfo,
      'customerName': customerName,
      'vehicleId': vehicleId,
      'customerId': customerId,
      'mechanicName': mechanicName,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'serviceType': serviceType,
      'status': status.name,
      'notes': notes,
      'partsNeeded': partsNeeded,
      'estimatedCost': estimatedCost,
    };
  }
}
