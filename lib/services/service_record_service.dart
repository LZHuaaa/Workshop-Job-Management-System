import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/service_record.dart';
import 'customer_service.dart';

class ServiceRecordService {
  static final ServiceRecordService _instance =
      ServiceRecordService._internal();
  factory ServiceRecordService() => _instance;
  ServiceRecordService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'service_records';
  final CustomerService _customerService = CustomerService();

  // Get service records collection reference
  CollectionReference get _serviceRecordsRef =>
      _firestore.collection(_collection);

  // Create a new service record
  Future<String> createServiceRecord(ServiceRecord serviceRecord) async {
    try {
      final docRef = await _serviceRecordsRef.add(serviceRecord.toMap());

      // Update the service record with the generated ID
      await docRef.update({'id': docRef.id});

      // Update customer stats (total spent, visit count, last visit)
      await _customerService.updateCustomerStats(
          serviceRecord.customerId, serviceRecord.cost);

      // Update vehicle's last service date directly - use Timestamp for consistency
      await _firestore
          .collection('vehicles')
          .doc(serviceRecord.vehicleId)
          .update({
        'lastServiceDate': Timestamp.fromDate(serviceRecord.serviceDate),
      });

      return docRef.id;
    } catch (e) {
      throw ServiceRecordServiceException(
          'Failed to create service record: ${e.toString()}');
    }
  }

  // Get a service record by ID
  Future<ServiceRecord?> getServiceRecord(String serviceRecordId) async {
    try {
      final doc = await _serviceRecordsRef.doc(serviceRecordId).get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id; // Ensure ID is set

      return ServiceRecord.fromMap(data);
    } catch (e) {
      throw ServiceRecordServiceException(
          'Failed to get service record: ${e.toString()}');
    }
  }

  // Get all service records
  Future<List<ServiceRecord>> getAllServiceRecords() async {
    try {
      final querySnapshot = await _serviceRecordsRef
          .orderBy('serviceDate', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Ensure ID is set
        return ServiceRecord.fromMap(data);
      }).toList();
    } catch (e) {
      throw ServiceRecordServiceException(
          'Failed to get service records: ${e.toString()}');
    }
  }

  // Get service records by customer ID
  Future<List<ServiceRecord>> getServiceRecordsByCustomer(
      String customerId) async {
    try {
      final querySnapshot = await _serviceRecordsRef
          .where('customerId', isEqualTo: customerId)
          .get();

      final serviceRecords = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Ensure ID is set
        return ServiceRecord.fromMap(data);
      }).toList();

      // Sort by service date in Dart (descending order)
      serviceRecords.sort((a, b) => b.serviceDate.compareTo(a.serviceDate));

      return serviceRecords;
    } catch (e) {
      throw ServiceRecordServiceException(
          'Failed to get customer service records: ${e.toString()}');
    }
  }

  // Get service records by vehicle ID
  Future<List<ServiceRecord>> getServiceRecordsByVehicle(
      String vehicleId) async {
    try {
      final querySnapshot = await _serviceRecordsRef
          .where('vehicleId', isEqualTo: vehicleId)
          .orderBy('serviceDate', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Ensure ID is set
        return ServiceRecord.fromMap(data);
      }).toList();
    } catch (e) {
      throw ServiceRecordServiceException(
          'Failed to get vehicle service records: ${e.toString()}');
    }
  }

  // Update a service record
  Future<void> updateServiceRecord(ServiceRecord serviceRecord) async {
    try {
      await _serviceRecordsRef
          .doc(serviceRecord.id)
          .update(serviceRecord.toMap());
    } catch (e) {
      throw ServiceRecordServiceException(
          'Failed to update service record: ${e.toString()}');
    }
  }

  // Delete a service record
  Future<void> deleteServiceRecord(String serviceRecordId) async {
    try {
      final serviceRecord = await getServiceRecord(serviceRecordId);
      if (serviceRecord == null) {
        throw ServiceRecordServiceException('Service record not found');
      }

      // Update customer stats (subtract cost, reduce visit count)
      final customer =
          await _customerService.getCustomer(serviceRecord.customerId);
      if (customer != null) {
        final updatedCustomer = customer.copyWith(
          totalSpent: (customer.totalSpent - serviceRecord.cost)
              .clamp(0.0, double.infinity),
        );
        await _customerService.updateCustomer(updatedCustomer);
      }

      await _serviceRecordsRef.doc(serviceRecordId).delete();
    } catch (e) {
      if (e is ServiceRecordServiceException) {
        rethrow;
      }
      throw ServiceRecordServiceException(
          'Failed to delete service record: ${e.toString()}');
    }
  }

  // Get service records stream for real-time updates
  Stream<List<ServiceRecord>> getServiceRecordsStream() {
    return _serviceRecordsRef
        .orderBy('serviceDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Ensure ID is set
        return ServiceRecord.fromMap(data);
      }).toList();
    });
  }

  // Get service records stream by customer
  Stream<List<ServiceRecord>> getServiceRecordsByCustomerStream(
      String customerId) {
    return _serviceRecordsRef
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map((snapshot) {
      final serviceRecords = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Ensure ID is set
        return ServiceRecord.fromMap(data);
      }).toList();

      // Sort by service date in Dart (descending order)
      serviceRecords.sort((a, b) => b.serviceDate.compareTo(a.serviceDate));

      return serviceRecords;
    });
  }

  // Get service records stream by vehicle
  Stream<List<ServiceRecord>> getServiceRecordsByVehicleStream(
      String vehicleId) {
    return _serviceRecordsRef
        .where('vehicleId', isEqualTo: vehicleId)
        .orderBy('serviceDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Ensure ID is set
        return ServiceRecord.fromMap(data);
      }).toList();
    });
  }

  // Get service record stream for real-time updates
  Stream<ServiceRecord?> getServiceRecordStream(String serviceRecordId) {
    return _serviceRecordsRef.doc(serviceRecordId).snapshots().map((doc) {
      if (!doc.exists) {
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id; // Ensure ID is set

      return ServiceRecord.fromMap(data);
    });
  }

  // Get service records by status
  Future<List<ServiceRecord>> getServiceRecordsByStatus(
      ServiceStatus status) async {
    try {
      final querySnapshot = await _serviceRecordsRef
          .where('status', isEqualTo: status.name)
          .orderBy('serviceDate', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Ensure ID is set
        return ServiceRecord.fromMap(data);
      }).toList();
    } catch (e) {
      throw ServiceRecordServiceException(
          'Failed to get service records by status: ${e.toString()}');
    }
  }

  // Get service records by date range
  Future<List<ServiceRecord>> getServiceRecordsByDateRange(
      DateTime startDate, DateTime endDate) async {
    try {
      // Use Timestamp format for Firestore consistency
      final querySnapshot = await _serviceRecordsRef
          .where('serviceDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('serviceDate',
              isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('serviceDate', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Ensure ID is set
        return ServiceRecord.fromMap(data);
      }).toList();
    } catch (e) {
      throw ServiceRecordServiceException(
          'Failed to get service records by date range: ${e.toString()}');
    }
  }

  // Search service records by service type or description
  Future<List<ServiceRecord>> searchServiceRecords(String query) async {
    try {
      if (query.isEmpty) {
        return await getAllServiceRecords();
      }

      final lowercaseQuery = query.toLowerCase();

      // Get all service records and filter locally (Firestore has limited search capabilities)
      final allServiceRecords = await getAllServiceRecords();

      return allServiceRecords.where((record) {
        return record.serviceType.toLowerCase().contains(lowercaseQuery) ||
            record.description.toLowerCase().contains(lowercaseQuery) ||
            record.mechanicName.toLowerCase().contains(lowercaseQuery) ||
            record.servicesPerformed.any(
                (service) => service.toLowerCase().contains(lowercaseQuery)) ||
            record.partsReplaced
                .any((part) => part.toLowerCase().contains(lowercaseQuery));
      }).toList();
    } catch (e) {
      throw ServiceRecordServiceException(
          'Failed to search service records: ${e.toString()}');
    }
  }

  // Get service records by mechanic
  Future<List<ServiceRecord>> getServiceRecordsByMechanic(
      String mechanicName) async {
    try {
      final querySnapshot = await _serviceRecordsRef
          .where('mechanicName', isEqualTo: mechanicName)
          .orderBy('serviceDate', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Ensure ID is set
        return ServiceRecord.fromMap(data);
      }).toList();
    } catch (e) {
      throw ServiceRecordServiceException(
          'Failed to get service records by mechanic: ${e.toString()}');
    }
  }

  // Get upcoming service due dates
  Future<List<ServiceRecord>> getUpcomingServiceDue() async {
    try {
      final now = DateTime.now();
      final nextMonth = now.add(const Duration(days: 30));

      // Use Timestamp format for Firestore consistency
      final querySnapshot = await _serviceRecordsRef
          .where('nextServiceDue',
              isGreaterThanOrEqualTo: Timestamp.fromDate(now))
          .where('nextServiceDue',
              isLessThanOrEqualTo: Timestamp.fromDate(nextMonth))
          .orderBy('nextServiceDue')
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Ensure ID is set
        return ServiceRecord.fromMap(data);
      }).toList();
    } catch (e) {
      throw ServiceRecordServiceException(
          'Failed to get upcoming service due: ${e.toString()}');
    }
  }

  // Get service statistics
  Future<ServiceStats> getServiceStats() async {
    try {
      final allServiceRecords = await getAllServiceRecords();

      final totalServices = allServiceRecords.length;
      final totalRevenue = allServiceRecords.fold<double>(
          0.0, (sum, record) => sum + record.cost);

      // Group by status
      final statusGroups = <ServiceStatus, int>{};
      for (final record in allServiceRecords) {
        statusGroups[record.status] = (statusGroups[record.status] ?? 0) + 1;
      }

      // Group by service type
      final serviceTypeGroups = <String, int>{};
      for (final record in allServiceRecords) {
        serviceTypeGroups[record.serviceType] =
            (serviceTypeGroups[record.serviceType] ?? 0) + 1;
      }

      // Group by mechanic
      final mechanicGroups = <String, int>{};
      for (final record in allServiceRecords) {
        mechanicGroups[record.mechanicName] =
            (mechanicGroups[record.mechanicName] ?? 0) + 1;
      }

      // Calculate average cost
      final averageCost =
          totalServices > 0 ? totalRevenue / totalServices : 0.0;

      return ServiceStats(
        totalServices: totalServices,
        totalRevenue: totalRevenue,
        averageCost: averageCost,
        statusDistribution: statusGroups,
        serviceTypeDistribution: serviceTypeGroups,
        mechanicDistribution: mechanicGroups,
      );
    } catch (e) {
      throw ServiceRecordServiceException(
          'Failed to get service statistics: ${e.toString()}');
    }
  }

  // Update service status
  Future<void> updateServiceStatus(
      String serviceRecordId, ServiceStatus status) async {
    try {
      await _serviceRecordsRef.doc(serviceRecordId).update({
        'status': status.name,
      });
    } catch (e) {
      throw ServiceRecordServiceException(
          'Failed to update service status: ${e.toString()}');
    }
  }

  // Batch create service records (for sample data population)
  Future<void> batchCreateServiceRecords(
      List<ServiceRecord> serviceRecords) async {
    try {
      final batch = _firestore.batch();

      for (final serviceRecord in serviceRecords) {
        final docRef = _serviceRecordsRef.doc();
        final serviceRecordData = serviceRecord.copyWith(id: docRef.id).toMap();
        batch.set(docRef, serviceRecordData);
      }

      await batch.commit();
    } catch (e) {
      throw ServiceRecordServiceException(
          'Failed to batch create service records: ${e.toString()}');
    }
  }

  // Get recent service records (last 30 days)
  Future<List<ServiceRecord>> getRecentServiceRecords() async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

      // Use Timestamp format for Firestore consistency
      final querySnapshot = await _serviceRecordsRef
          .where('serviceDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(thirtyDaysAgo))
          .orderBy('serviceDate', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Ensure ID is set
        return ServiceRecord.fromMap(data);
      }).toList();
    } catch (e) {
      throw ServiceRecordServiceException(
          'Failed to get recent service records: ${e.toString()}');
    }
  }

  // Get the most recent service record for a vehicle
  Future<ServiceRecord?> getMostRecentServiceRecord(String vehicleId) async {
    try {
      final querySnapshot = await _serviceRecordsRef
          .where('vehicleId', isEqualTo: vehicleId)
          .orderBy('serviceDate', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      final doc = querySnapshot.docs.first;
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id; // Ensure ID is set
      return ServiceRecord.fromMap(data);
    } catch (e) {
      throw ServiceRecordServiceException(
          'Failed to get most recent service record: ${e.toString()}');
    }
  }

  // Get the last service date for a vehicle
  Future<DateTime?> getLastServiceDate(String vehicleId) async {
    try {
      final mostRecentRecord = await getMostRecentServiceRecord(vehicleId);
      return mostRecentRecord?.serviceDate;
    } catch (e) {
      throw ServiceRecordServiceException(
          'Failed to get last service date: ${e.toString()}');
    }
  }

  // Get service record count for a vehicle
  Future<int> getServiceRecordCount(String vehicleId) async {
    try {
      final querySnapshot = await _serviceRecordsRef
          .where('vehicleId', isEqualTo: vehicleId)
          .get();
      return querySnapshot.docs.length;
    } catch (e) {
      throw ServiceRecordServiceException(
          'Failed to get service record count: ${e.toString()}');
    }
  }
}

// Custom exception class for service record service errors
class ServiceRecordServiceException implements Exception {
  final String message;

  ServiceRecordServiceException(this.message);

  @override
  String toString() => 'ServiceRecordServiceException: $message';
}

// Service statistics model
class ServiceStats {
  final int totalServices;
  final double totalRevenue;
  final double averageCost;
  final Map<ServiceStatus, int> statusDistribution;
  final Map<String, int> serviceTypeDistribution;
  final Map<String, int> mechanicDistribution;

  ServiceStats({
    required this.totalServices,
    required this.totalRevenue,
    required this.averageCost,
    required this.statusDistribution,
    required this.serviceTypeDistribution,
    required this.mechanicDistribution,
  });
}
