enum OrderRequestStatus {
  pending,
  approved,
  rejected,
  cancelled,
}

class OrderRequest {
  final String id;
  final String itemId;
  final String itemName;
  final String supplier;
  final int quantity;
  final double unitPrice;
  final double totalAmount;
  final OrderRequestStatus status;
  final DateTime requestDate;
  final DateTime? responseDate;
  final String? responseNote;
  final String requestedBy;

  OrderRequest({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.supplier,
    required this.quantity,
    required this.unitPrice,
    required this.totalAmount,
    required this.status,
    required this.requestDate,
    this.responseDate,
    this.responseNote,
    required this.requestedBy,
  });

  bool get isPending => status == OrderRequestStatus.pending;
  bool get isApproved => status == OrderRequestStatus.approved;
  bool get isRejected => status == OrderRequestStatus.rejected;
  bool get isCancelled => status == OrderRequestStatus.cancelled;

  String get statusText {
    switch (status) {
      case OrderRequestStatus.pending:
        return 'Pending Approval';
      case OrderRequestStatus.approved:
        return 'Approved';
      case OrderRequestStatus.rejected:
        return 'Rejected';
      case OrderRequestStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get statusColor {
    switch (status) {
      case OrderRequestStatus.pending:
        return '#FFA500'; // Orange
      case OrderRequestStatus.approved:
        return '#4CAF50'; // Green
      case OrderRequestStatus.rejected:
        return '#F44336'; // Red
      case OrderRequestStatus.cancelled:
        return '#9E9E9E'; // Grey
    }
  }

  OrderRequest copyWith({
    String? id,
    String? itemId,
    String? itemName,
    String? supplier,
    int? quantity,
    double? unitPrice,
    double? totalAmount,
    OrderRequestStatus? status,
    DateTime? requestDate,
    DateTime? responseDate,
    String? responseNote,
    String? requestedBy,
  }) {
    return OrderRequest(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      itemName: itemName ?? this.itemName,
      supplier: supplier ?? this.supplier,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      requestDate: requestDate ?? this.requestDate,
      responseDate: responseDate ?? this.responseDate,
      responseNote: responseNote ?? this.responseNote,
      requestedBy: requestedBy ?? this.requestedBy,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemId': itemId,
      'itemName': itemName,
      'supplier': supplier,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalAmount': totalAmount,
      'status': status.name,
      'requestDate': requestDate.toIso8601String(),
      'responseDate': responseDate?.toIso8601String(),
      'responseNote': responseNote,
      'requestedBy': requestedBy,
    };
  }

  factory OrderRequest.fromJson(Map<String, dynamic> json) {
    return OrderRequest(
      id: json['id'],
      itemId: json['itemId'],
      itemName: json['itemName'],
      supplier: json['supplier'],
      quantity: json['quantity'],
      unitPrice: json['unitPrice'].toDouble(),
      totalAmount: json['totalAmount'].toDouble(),
      status: OrderRequestStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => OrderRequestStatus.pending,
      ),
      requestDate: DateTime.parse(json['requestDate']),
      responseDate: json['responseDate'] != null
          ? DateTime.parse(json['responseDate'])
          : null,
      responseNote: json['responseNote'],
      requestedBy: json['requestedBy'],
    );
  }
} 