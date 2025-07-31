import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum for tracking order request approval status
enum OrderRequestStatus {
  pending,
  approved,
  rejected,
  completed,
}

/// Extension to provide string values and helper methods for OrderRequestStatus
extension OrderRequestStatusExtension on OrderRequestStatus {
  String get value {
    switch (this) {
      case OrderRequestStatus.pending:
        return 'pending';
      case OrderRequestStatus.approved:
        return 'approved';
      case OrderRequestStatus.rejected:
        return 'rejected';
      case OrderRequestStatus.completed:
        return 'completed';
    }
  }

  static OrderRequestStatus? fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'pending':
        return OrderRequestStatus.pending;
      case 'approved':
        return OrderRequestStatus.approved;
      case 'rejected':
        return OrderRequestStatus.rejected;
      case 'completed':
        return OrderRequestStatus.completed;
      default:
        return null; // Return null for no active order request
    }
  }
}

class InventoryItem {
  final String id;
  final String name;
  final String category;
  final int currentStock;
  final int minStock;
  final int maxStock;
  final double unitPrice;
  final String supplier;
  final String location;
  final String description;
  final DateTime? lastRestocked;
  final String? imageUrl;
  final bool pendingOrderRequest;
  final DateTime? orderRequestDate;
  final String? orderRequestId;
  final OrderRequestStatus? orderRequestStatus;

  InventoryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.currentStock,
    required this.minStock,
    required this.maxStock,
    required this.unitPrice,
    required this.supplier,
    required this.location,
    required this.description,
    this.lastRestocked,
    this.imageUrl,
    this.pendingOrderRequest = false,
    this.orderRequestDate,
    this.orderRequestId,
    this.orderRequestStatus,
  });

  bool get isLowStock => currentStock <= minStock;
  bool get isCriticalStock => currentStock <= (minStock * 0.5);
  bool get isOutOfStock => currentStock == 0;
  bool get isOverstocked => currentStock > maxStock;
  bool get isAvailable => currentStock > 0;

  double get stockPercentage => currentStock / maxStock;

  int get stockNeeded => maxStock - currentStock;
  int get stockToReorder => maxStock - currentStock;

  double get totalValue => currentStock * unitPrice;

  // Check if order can be requested (low/critical stock and no pending request)
  bool get canRequestOrder =>
      (isLowStock || isCriticalStock) && !pendingOrderRequest;

  // Order request status helper methods
  bool get hasOrderRequestPending => orderRequestStatus == OrderRequestStatus.pending;
  bool get hasOrderRequestApproved => orderRequestStatus == OrderRequestStatus.approved;
  bool get hasOrderRequestRejected => orderRequestStatus == OrderRequestStatus.rejected;
  bool get hasOrderRequestCompleted => orderRequestStatus == OrderRequestStatus.completed;
  bool get hasNoActiveOrderRequest => orderRequestStatus == null;

  // Check if item is waiting for company restocking (approved orders)
  bool get isWaitingForRestock => hasOrderRequestApproved;

  // Check if item can request order (low stock and no active request)
  bool get canRequestOrderNew => (isLowStock || isCriticalStock) && hasNoActiveOrderRequest;

  // Get human-readable status text
  String get orderRequestStatusText {
    switch (orderRequestStatus) {
      case OrderRequestStatus.pending:
        return 'Pending Company Approval';
      case OrderRequestStatus.approved:
        return 'Approved - Company Processing';
      case OrderRequestStatus.rejected:
        return 'Rejected by Company';
      case OrderRequestStatus.completed:
        return 'Restocking Complete';
      case null:
        return 'No Active Request';
    }
  }

  // Get status color for UI
  String get orderRequestStatusColor {
    switch (orderRequestStatus) {
      case OrderRequestStatus.pending:
        return '#FFA500'; // Orange
      case OrderRequestStatus.approved:
        return '#2196F3'; // Blue
      case OrderRequestStatus.rejected:
        return '#F44336'; // Red
      case OrderRequestStatus.completed:
        return '#4CAF50'; // Green
      case null:
        return '#9E9E9E'; // Grey
    }
  }

  InventoryItem copyWith({
    String? id,
    String? name,
    String? category,
    int? currentStock,
    int? minStock,
    int? maxStock,
    double? unitPrice,
    String? supplier,
    String? location,
    String? description,
    DateTime? lastRestocked,
    String? imageUrl,
    bool? pendingOrderRequest,
    DateTime? orderRequestDate,
    String? orderRequestId,
    OrderRequestStatus? orderRequestStatus,
    bool clearOrderRequestStatus = false,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      currentStock: currentStock ?? this.currentStock,
      minStock: minStock ?? this.minStock,
      maxStock: maxStock ?? this.maxStock,
      unitPrice: unitPrice ?? this.unitPrice,
      supplier: supplier ?? this.supplier,
      location: location ?? this.location,
      description: description ?? this.description,
      lastRestocked: lastRestocked ?? this.lastRestocked,
      imageUrl: imageUrl ?? this.imageUrl,
      pendingOrderRequest: pendingOrderRequest ?? this.pendingOrderRequest,
      orderRequestDate: orderRequestDate ?? this.orderRequestDate,
      orderRequestId: orderRequestId ?? this.orderRequestId,
      orderRequestStatus: clearOrderRequestStatus ? null : (orderRequestStatus ?? this.orderRequestStatus),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'currentStock': currentStock,
      'minStock': minStock,
      'maxStock': maxStock,
      'unitPrice': unitPrice,
      'supplier': supplier,
      'location': location,
      'description': description,
      'lastRestocked': lastRestocked?.toIso8601String(),
      'imageUrl': imageUrl,
      'pendingOrderRequest': pendingOrderRequest,
      'orderRequestDate': orderRequestDate?.toIso8601String(),
      'orderRequestId': orderRequestId,
      'orderRequestStatus': orderRequestStatus?.value,
    };
  }

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['id'],
      name: json['name'],
      category: json['category'],
      currentStock: json['currentStock'],
      minStock: json['minStock'],
      maxStock: json['maxStock'],
      unitPrice: json['unitPrice'].toDouble(),
      supplier: json['supplier'],
      location: json['location'],
      description: json['description'],
      lastRestocked: json['lastRestocked'] != null
          ? _parseDateTime(json['lastRestocked'])
          : null,
      imageUrl: json['imageUrl'],
      pendingOrderRequest: json['pendingOrderRequest'] ?? false,
      orderRequestDate: json['orderRequestDate'] != null
          ? _parseDateTime(json['orderRequestDate'])
          : null,
      orderRequestId: json['orderRequestId'],
      orderRequestStatus: OrderRequestStatusExtension.fromString(json['orderRequestStatus']),
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
}
