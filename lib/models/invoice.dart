import 'package:flutter/foundation.dart';

enum InvoiceStatus {
  draft,
  pending,
  approved,
  paid,
  cancelled
}

class InvoiceItem {
  final String id;
  final String description;
  final double quantity;
  final double unitPrice;
  final double tax;

  InvoiceItem({
    required this.id,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.tax,
  });

  double get subtotal => quantity * unitPrice;
  double get taxAmount => subtotal * (tax / 100);
  double get total => subtotal + taxAmount;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'tax': tax,
    };
  }

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      id: json['id'] as String,
      description: json['description'] as String,
      quantity: json['quantity'] as double,
      unitPrice: json['unitPrice'] as double,
      tax: json['tax'] as double,
    );
  }
}

class Invoice {
  final String id;
  final String customerId;
  final String customerName;
  final String vehicleId;
  final String jobId;
  final DateTime issueDate;
  final DateTime dueDate;
  final List<InvoiceItem> items;
  final InvoiceStatus status;
  final String? notes;

  Invoice({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.vehicleId,
    required this.jobId,
    required this.issueDate,
    required this.dueDate,
    required this.items,
    required this.status,
    this.notes,
  });

  double get subtotal => items.fold(0, (sum, item) => sum + item.subtotal);
  double get taxTotal => items.fold(0, (sum, item) => sum + item.taxAmount);
  double get total => subtotal + taxTotal;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'customerName': customerName,
      'vehicleId': vehicleId,
      'jobId': jobId,
      'issueDate': issueDate.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
      'status': status.toString(),
      'notes': notes,
    };
  }

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'] as String,
      customerId: json['customerId'] as String,
      customerName: json['customerName'] as String,
      vehicleId: json['vehicleId'] as String,
      jobId: json['jobId'] as String,
      issueDate: DateTime.parse(json['issueDate'] as String),
      dueDate: DateTime.parse(json['dueDate'] as String),
      items: (json['items'] as List)
          .map((item) => InvoiceItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      status: InvoiceStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
      ),
      notes: json['notes'] as String?,
    );
  }
} 