import 'package:cloud_firestore/cloud_firestore.dart';

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
  });

  bool get isLowStock => currentStock <= minStock;
  bool get isCriticalStock => currentStock <= (minStock * 0.5);
  bool get isOutOfStock => currentStock == 0;
  bool get isOverstocked => currentStock > maxStock;

  double get stockPercentage => currentStock / maxStock;

  int get stockNeeded => maxStock - currentStock;
  int get stockToReorder => maxStock - currentStock;

  double get totalValue => currentStock * unitPrice;

  // Check if order can be requested (low/critical stock and no pending request)
  bool get canRequestOrder =>
      (isLowStock || isCriticalStock) && !pendingOrderRequest;

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
