enum UsageType {
  service,
  maintenance,
  repair,
  installation,
  replacement,
  testing,
  other,
}

enum UsageStatus {
  recorded,
  verified,
  disputed,
  cancelled,
}

class InventoryUsage {
  final String id;
  final String itemId;
  final String itemName;
  final String itemCategory;
  final int quantityUsed;
  final double unitPrice;
  final double totalCost;
  final UsageType usageType;
  final UsageStatus status;
  final DateTime usageDate;
  final String usedBy; // Employee/mechanic name
  final String? customerId;
  final String? customerName;
  final String? vehicleId;
  final String? vehiclePlate;
  final String? jobId;
  final String? serviceRecordId;
  final String purpose; // Description of what it was used for
  final String? notes;
  final String? location; // Where the usage occurred
  final DateTime createdAt;
  final DateTime? verifiedAt;
  final String? verifiedBy;

  InventoryUsage({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.itemCategory,
    required this.quantityUsed,
    required this.unitPrice,
    required this.totalCost,
    required this.usageType,
    required this.status,
    required this.usageDate,
    required this.usedBy,
    this.customerId,
    this.customerName,
    this.vehicleId,
    this.vehiclePlate,
    this.jobId,
    this.serviceRecordId,
    required this.purpose,
    this.notes,
    this.location,
    required this.createdAt,
    this.verifiedAt,
    this.verifiedBy,
  });

  bool get isVerified => status == UsageStatus.verified;
  bool get isDisputed => status == UsageStatus.disputed;
  bool get isCancelled => status == UsageStatus.cancelled;

  String get usageTypeText {
    switch (usageType) {
      case UsageType.service:
        return 'Service';
      case UsageType.maintenance:
        return 'Maintenance';
      case UsageType.repair:
        return 'Repair';
      case UsageType.installation:
        return 'Installation';
      case UsageType.replacement:
        return 'Replacement';
      case UsageType.testing:
        return 'Testing';
      case UsageType.other:
        return 'Other';
    }
  }

  String get statusText {
    switch (status) {
      case UsageStatus.recorded:
        return 'Recorded';
      case UsageStatus.verified:
        return 'Verified';
      case UsageStatus.disputed:
        return 'Disputed';
      case UsageStatus.cancelled:
        return 'Cancelled';
    }
  }

  InventoryUsage copyWith({
    String? id,
    String? itemId,
    String? itemName,
    String? itemCategory,
    int? quantityUsed,
    double? unitPrice,
    double? totalCost,
    UsageType? usageType,
    UsageStatus? status,
    DateTime? usageDate,
    String? usedBy,
    String? customerId,
    String? customerName,
    String? vehicleId,
    String? vehiclePlate,
    String? jobId,
    String? serviceRecordId,
    String? purpose,
    String? notes,
    String? location,
    DateTime? createdAt,
    DateTime? verifiedAt,
    String? verifiedBy,
  }) {
    return InventoryUsage(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      itemName: itemName ?? this.itemName,
      itemCategory: itemCategory ?? this.itemCategory,
      quantityUsed: quantityUsed ?? this.quantityUsed,
      unitPrice: unitPrice ?? this.unitPrice,
      totalCost: totalCost ?? this.totalCost,
      usageType: usageType ?? this.usageType,
      status: status ?? this.status,
      usageDate: usageDate ?? this.usageDate,
      usedBy: usedBy ?? this.usedBy,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      vehicleId: vehicleId ?? this.vehicleId,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
      jobId: jobId ?? this.jobId,
      serviceRecordId: serviceRecordId ?? this.serviceRecordId,
      purpose: purpose ?? this.purpose,
      notes: notes ?? this.notes,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      verifiedBy: verifiedBy ?? this.verifiedBy,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemId': itemId,
      'itemName': itemName,
      'itemCategory': itemCategory,
      'quantityUsed': quantityUsed,
      'unitPrice': unitPrice,
      'totalCost': totalCost,
      'usageType': usageType.name,
      'status': status.name,
      'usageDate': usageDate.toIso8601String(),
      'usedBy': usedBy,
      'customerId': customerId,
      'customerName': customerName,
      'vehicleId': vehicleId,
      'vehiclePlate': vehiclePlate,
      'jobId': jobId,
      'serviceRecordId': serviceRecordId,
      'purpose': purpose,
      'notes': notes,
      'location': location,
      'createdAt': createdAt.toIso8601String(),
      'verifiedAt': verifiedAt?.toIso8601String(),
      'verifiedBy': verifiedBy,
    };
  }

  factory InventoryUsage.fromJson(Map<String, dynamic> json) {
    return InventoryUsage(
      id: json['id'],
      itemId: json['itemId'],
      itemName: json['itemName'],
      itemCategory: json['itemCategory'],
      quantityUsed: json['quantityUsed'],
      unitPrice: json['unitPrice'].toDouble(),
      totalCost: json['totalCost'].toDouble(),
      usageType: UsageType.values.firstWhere(
        (e) => e.name == json['usageType'],
        orElse: () => UsageType.other,
      ),
      status: UsageStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => UsageStatus.recorded,
      ),
      usageDate: DateTime.parse(json['usageDate']),
      usedBy: json['usedBy'],
      customerId: json['customerId'],
      customerName: json['customerName'],
      vehicleId: json['vehicleId'],
      vehiclePlate: json['vehiclePlate'],
      jobId: json['jobId'],
      serviceRecordId: json['serviceRecordId'],
      purpose: json['purpose'],
      notes: json['notes'],
      location: json['location'],
      createdAt: DateTime.parse(json['createdAt']),
      verifiedAt: json['verifiedAt'] != null
          ? DateTime.parse(json['verifiedAt'])
          : null,
      verifiedBy: json['verifiedBy'],
    );
  }
}

class UsageAnalytics {
  final String itemId;
  final String itemName;
  final String category;
  final int totalQuantityUsed;
  final double totalCost;
  final int usageCount;
  final DateTime firstUsage;
  final DateTime lastUsage;
  final double averageUsagePerMonth;
  final Map<UsageType, int> usageByType;
  final Map<String, int> usageByEmployee;

  UsageAnalytics({
    required this.itemId,
    required this.itemName,
    required this.category,
    required this.totalQuantityUsed,
    required this.totalCost,
    required this.usageCount,
    required this.firstUsage,
    required this.lastUsage,
    required this.averageUsagePerMonth,
    required this.usageByType,
    required this.usageByEmployee,
  });

  double get averageCostPerUsage => usageCount > 0 ? totalCost / usageCount : 0.0;
  double get averageQuantityPerUsage => usageCount > 0 ? totalQuantityUsed / usageCount : 0.0;
}

class UsageSummary {
  final DateTime periodStart;
  final DateTime periodEnd;
  final int totalUsageRecords;
  final int totalQuantityUsed;
  final double totalCost;
  final Map<String, int> usageByCategory;
  final Map<UsageType, int> usageByType;
  final Map<String, int> usageByEmployee;
  final List<String> topUsedItems;
  final List<String> mostActiveEmployees;

  UsageSummary({
    required this.periodStart,
    required this.periodEnd,
    required this.totalUsageRecords,
    required this.totalQuantityUsed,
    required this.totalCost,
    required this.usageByCategory,
    required this.usageByType,
    required this.usageByEmployee,
    required this.topUsedItems,
    required this.mostActiveEmployees,
  });

  double get averageCostPerRecord => totalUsageRecords > 0 ? totalCost / totalUsageRecords : 0.0;
  double get averageQuantityPerRecord => totalUsageRecords > 0 ? totalQuantityUsed / totalUsageRecords : 0.0;
}
