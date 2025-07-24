enum JobStatus {
  scheduled,
  inProgress,
  completed,
  cancelled,
}

class JobAppointment {
  final String id;
  final String vehicleInfo;
  final String customerName;
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
}
