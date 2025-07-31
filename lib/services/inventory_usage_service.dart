import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/inventory_usage.dart';
import 'notification_service.dart';


class InventoryUsageService {
  static final InventoryUsageService _instance = InventoryUsageService._internal();
  factory InventoryUsageService() => _instance;
  InventoryUsageService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'inventory_usage';
  final NotificationService _notificationService = NotificationService();

  // Get usage collection reference
  CollectionReference get _usageRef => _firestore.collection(_collection);

  // Get all usage records as stream
  Stream<List<InventoryUsage>> getAllUsageRecords() {
    return _usageRef.snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return <InventoryUsage>[];
      }

      final usageRecords = <InventoryUsage>[];
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final usage = _mapToInventoryUsage(data);
          usageRecords.add(usage);
        } catch (e) {
          print('Error mapping usage document ${doc.id}: $e');
        }
      }

      // Sort by usage date (newest first)
      usageRecords.sort((a, b) => b.usageDate.compareTo(a.usageDate));
      return usageRecords;
    }).handleError((error) {
      print('Stream error: $error');
      return <InventoryUsage>[];
    });
  }

  // Get usage records with filtering as stream
  Stream<List<InventoryUsage>> getUsageRecords({
    String? itemId,
    String? category,
    UsageType? usageType,
    UsageStatus? status,
    String? usedBy,
    String? customerId,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
    String? sortBy,
    bool sortAscending = false,
  }) {
    Query query = _usageRef;

    // Apply Firestore filters where possible
    if (itemId != null) {
      query = query.where('itemId', isEqualTo: itemId);
    }
    if (category != null) {
      query = query.where('itemCategory', isEqualTo: category);
    }
    if (usageType != null) {
      query = query.where('usageType', isEqualTo: usageType.name);
    }
    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }
    if (usedBy != null) {
      query = query.where('usedBy', isEqualTo: usedBy);
    }
    if (customerId != null) {
      query = query.where('customerId', isEqualTo: customerId);
    }
    if (startDate != null) {
      query = query.where('usageDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }
    if (endDate != null) {
      query = query.where('usageDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }

    return query.snapshots().map((snapshot) {
      var usageRecords = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return _mapToInventoryUsage(data);
      }).toList();

      // Apply client-side filters for complex queries
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final searchTerm = searchQuery.toLowerCase();
        usageRecords = usageRecords.where((usage) =>
            usage.itemName.toLowerCase().contains(searchTerm)).toList();
      }

      // Apply sorting
      if (sortBy != null) {
        switch (sortBy) {
          case 'Date':
            usageRecords.sort((a, b) => sortAscending
                ? a.usageDate.compareTo(b.usageDate)
                : b.usageDate.compareTo(a.usageDate));
            break;
          case 'Item Name':
            usageRecords.sort((a, b) => sortAscending
                ? a.itemName.compareTo(b.itemName)
                : b.itemName.compareTo(a.itemName));
            break;
          case 'Quantity':
            usageRecords.sort((a, b) => sortAscending
                ? a.quantityUsed.compareTo(b.quantityUsed)
                : b.quantityUsed.compareTo(a.quantityUsed));
            break;
          case 'Cost':
            usageRecords.sort((a, b) => sortAscending
                ? a.totalCost.compareTo(b.totalCost)
                : b.totalCost.compareTo(a.totalCost));
            break;
          case 'Status':
            usageRecords.sort((a, b) {
              // Define status priority order for logical workflow sorting
              // recorded (1) -> verified (2) -> disputed (3) -> cancelled (4)
              int getStatusPriority(UsageStatus status) {
                switch (status) {
                  case UsageStatus.recorded:
                    return 1;
                  case UsageStatus.verified:
                    return 2;
                  case UsageStatus.disputed:
                    return 3;
                  case UsageStatus.cancelled:
                    return 4;
                }
              }

              int priorityA = getStatusPriority(a.status);
              int priorityB = getStatusPriority(b.status);

              return sortAscending
                  ? priorityA.compareTo(priorityB)
                  : priorityB.compareTo(priorityA);
            });
            break;
          default:
            // Default sort by date (newest first)
            usageRecords.sort((a, b) => b.usageDate.compareTo(a.usageDate));
        }
      } else {
        // Default sort by date (newest first)
        usageRecords.sort((a, b) => b.usageDate.compareTo(a.usageDate));
      }

      return usageRecords;
    });
  }

  // Record new usage
  Future<String> recordUsage(InventoryUsage usage) async {
    try {
      final docRef = await _usageRef.add(_inventoryUsageToMap(usage));

      // Update the usage with the generated ID
      await docRef.update({'id': docRef.id});

      // Create notification for new usage record that needs verification
      if (usage.status == UsageStatus.recorded) {
        try {
          await _notificationService.createUsageVerificationAlert(
            usageId: docRef.id,
            itemName: usage.itemName,
            usedBy: usage.usedBy,
            totalCost: usage.totalCost,
          );
        } catch (notificationError) {
          // Don't fail the usage recording if notification fails
          print('Warning: Failed to create usage verification notification: $notificationError');
        }
      }

      return docRef.id;
    } catch (e) {
      throw InventoryUsageServiceException('Failed to record usage: ${e.toString()}');
    }
  }



  // Verify usage record
  Future<void> verifyUsage(String usageId, String verifiedBy) async {
    try {
      await _usageRef.doc(usageId).update({
        'status': UsageStatus.verified.name,
        'verifiedAt': Timestamp.fromDate(DateTime.now()),
        'verifiedBy': verifiedBy,
      });
    } catch (e) {
      throw InventoryUsageServiceException('Failed to verify usage: ${e.toString()}');
    }
  }

  // Dispute usage record
  Future<void> disputeUsage(String usageId, String disputedBy, String reason) async {
    try {
      // Get current usage record to append dispute reason to notes
      final doc = await _usageRef.doc(usageId).get();
      if (!doc.exists) {
        throw InventoryUsageServiceException('Usage record not found');
      }

      final data = doc.data() as Map<String, dynamic>;
      final currentNotes = data['notes'] as String? ?? '';
      final updatedNotes = '$currentNotes\n\nDISPUTE REASON: $reason'.trim();

      await _usageRef.doc(usageId).update({
        'status': UsageStatus.disputed.name,
        'verifiedAt': Timestamp.fromDate(DateTime.now()),
        'verifiedBy': disputedBy,
        'notes': updatedNotes,
      });
    } catch (e) {
      throw InventoryUsageServiceException('Failed to dispute usage: ${e.toString()}');
    }
  }

  // Undispute usage record (change back to recorded)
  Future<void> undisputeUsage(String usageId, String undisputedBy) async {
    try {
      // Get current usage record to remove dispute reason from notes
      final doc = await _usageRef.doc(usageId).get();
      if (!doc.exists) {
        throw InventoryUsageServiceException('Usage record not found');
      }

      final data = doc.data() as Map<String, dynamic>;
      String? updatedNotes = data['notes'] as String?;

      // Remove dispute reason from notes
      if (updatedNotes != null && updatedNotes.contains('DISPUTE REASON:')) {
        final disputeIndex = updatedNotes.indexOf('\n\nDISPUTE REASON:');
        if (disputeIndex != -1) {
          updatedNotes = updatedNotes.substring(0, disputeIndex).trim();
          if (updatedNotes.isEmpty) updatedNotes = null;
        }
      }

      await _usageRef.doc(usageId).update({
        'status': UsageStatus.recorded.name,
        'verifiedAt': null,
        'verifiedBy': null,
        'notes': updatedNotes,
      });
    } catch (e) {
      throw InventoryUsageServiceException('Failed to undispute usage: ${e.toString()}');
    }
  }

  // Delete usage record
  Future<void> deleteUsage(String usageId) async {
    try {
      await _usageRef.doc(usageId).delete();
    } catch (e) {
      throw InventoryUsageServiceException('Failed to delete usage: ${e.toString()}');
    }
  }

  // Get usage by item
  Stream<List<InventoryUsage>> getUsageByItem(String itemId) {
    return _usageRef
        .where('itemId', isEqualTo: itemId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return _mapToInventoryUsage(data);
      }).toList();
    });
  }

  // Get usage by employee
  Stream<List<InventoryUsage>> getUsageByEmployee(String employeeName) {
    return _usageRef
        .where('usedBy', isEqualTo: employeeName)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return _mapToInventoryUsage(data);
      }).toList();
    });
  }

  // Get usage by customer
  Stream<List<InventoryUsage>> getUsageByCustomer(String customerId) {
    return _usageRef
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return _mapToInventoryUsage(data);
      }).toList();
    });
  }



  // Get usage summary for a period
  Future<UsageSummary> getUsageSummary({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final query = _usageRef
          .where('usageDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('usageDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate));

      final snapshot = await query.get();
      final periodUsages = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return _mapToInventoryUsage(data);
      }).toList();

      final totalQuantity = periodUsages.fold<int>(0, (sum, usage) => sum + usage.quantityUsed);
      final totalCost = periodUsages.fold<double>(0, (sum, usage) => sum + usage.totalCost);

      final usageByCategory = <String, int>{};
      final usageByType = <UsageType, int>{};
      final usageByEmployee = <String, int>{};
      final itemUsageCount = <String, int>{};

      for (final usage in periodUsages) {
        final categoryCount = usageByCategory[usage.itemCategory] ?? 0;
        usageByCategory[usage.itemCategory] = categoryCount + usage.quantityUsed;

        final typeCount = usageByType[usage.usageType] ?? 0;
        usageByType[usage.usageType] = typeCount + 1;

        final employeeCount = usageByEmployee[usage.usedBy] ?? 0;
        usageByEmployee[usage.usedBy] = employeeCount + usage.quantityUsed;

        final itemCount = itemUsageCount[usage.itemName] ?? 0;
        itemUsageCount[usage.itemName] = itemCount + usage.quantityUsed;
      }

      final topUsedItems = itemUsageCount.entries
          .toList()
          ..sort((a, b) => b.value.compareTo(a.value))
          ..take(5);

      final mostActiveEmployees = usageByEmployee.entries
          .toList()
          ..sort((a, b) => b.value.compareTo(a.value))
          ..take(5);

      return UsageSummary(
        periodStart: startDate,
        periodEnd: endDate,
        totalUsageRecords: periodUsages.length,
        totalQuantityUsed: totalQuantity,
        totalCost: totalCost,
        usageByCategory: usageByCategory,
        usageByType: usageByType,
        usageByEmployee: usageByEmployee,
        topUsedItems: topUsedItems.map((e) => e.key).toList(),
        mostActiveEmployees: mostActiveEmployees.map((e) => e.key).toList(),
      );
    } catch (e) {
      throw InventoryUsageServiceException('Failed to get usage summary: ${e.toString()}');
    }
  }

  // Helper method to map Firestore data to InventoryUsage
  InventoryUsage _mapToInventoryUsage(Map<String, dynamic> data) {
    return InventoryUsage(
      id: data['id'] ?? '',
      itemId: data['itemId'] ?? '',
      itemName: data['itemName'] ?? '',
      itemCategory: data['itemCategory'] ?? '',
      quantityUsed: data['quantityUsed'] ?? 0,
      unitPrice: (data['unitPrice'] ?? 0.0).toDouble(),
      totalCost: (data['totalCost'] ?? 0.0).toDouble(),
      usageType: UsageType.values.firstWhere(
        (e) => e.name == data['usageType'],
        orElse: () => UsageType.other,
      ),
      status: UsageStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => UsageStatus.recorded,
      ),
      usageDate: data['usageDate'] is Timestamp
          ? (data['usageDate'] as Timestamp).toDate()
          : DateTime.parse(data['usageDate']),
      usedBy: data['usedBy'] ?? '',
      customerId: data['customerId'],
      customerName: data['customerName'],
      vehicleId: data['vehicleId'],
      vehiclePlate: data['vehiclePlate'],
      jobId: data['jobId'],
      serviceRecordId: data['serviceRecordId'],
      purpose: data['purpose'] ?? '',
      notes: data['notes'],
      location: data['location'],
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.parse(data['createdAt']),
      verifiedAt: data['verifiedAt'] != null
          ? (data['verifiedAt'] is Timestamp
              ? (data['verifiedAt'] as Timestamp).toDate()
              : DateTime.parse(data['verifiedAt']))
          : null,
      verifiedBy: data['verifiedBy'],
    );
  }

  // Helper method to convert InventoryUsage to Firestore map
  Map<String, dynamic> _inventoryUsageToMap(InventoryUsage usage) {
    return {
      'id': usage.id,
      'itemId': usage.itemId,
      'itemName': usage.itemName,
      'itemCategory': usage.itemCategory,
      'quantityUsed': usage.quantityUsed,
      'unitPrice': usage.unitPrice,
      'totalCost': usage.totalCost,
      'usageType': usage.usageType.name,
      'status': usage.status.name,
      'usageDate': Timestamp.fromDate(usage.usageDate),
      'usedBy': usage.usedBy,
      'customerId': usage.customerId,
      'customerName': usage.customerName,
      'vehicleId': usage.vehicleId,
      'vehiclePlate': usage.vehiclePlate,
      'jobId': usage.jobId,
      'serviceRecordId': usage.serviceRecordId,
      'purpose': usage.purpose,
      'notes': usage.notes,
      'location': usage.location,
      'createdAt': Timestamp.fromDate(usage.createdAt),
      'verifiedAt': usage.verifiedAt != null
          ? Timestamp.fromDate(usage.verifiedAt!)
          : null,
      'verifiedBy': usage.verifiedBy,
    };
  }

  // Get all unique employees from usage records
  Future<List<String>> getEmployees() async {
    try {
      final snapshot = await _usageRef.get();
      final employees = snapshot.docs
          .map((doc) => (doc.data() as Map<String, dynamic>)['usedBy'] as String)
          .toSet()
          .toList();
      employees.sort();
      return ['All', ...employees];
    } catch (e) {
      throw InventoryUsageServiceException('Failed to get employees: ${e.toString()}');
    }
  }
}

// Custom exception for inventory usage service errors
class InventoryUsageServiceException implements Exception {
  final String message;
  InventoryUsageServiceException(this.message);

  @override
  String toString() => 'InventoryUsageServiceException: $message';
}
