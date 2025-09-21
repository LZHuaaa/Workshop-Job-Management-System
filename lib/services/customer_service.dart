import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/customer.dart';

class CustomerService {
  static final CustomerService _instance = CustomerService._internal();
  factory CustomerService() => _instance;
  CustomerService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'customers';

  // Get customers collection reference
  CollectionReference get _customersRef => _firestore.collection(_collection);

  // Create a new customer
  Future<String> createCustomer(Customer customer) async {
    try {
      final docRef = await _customersRef.add(customer.toMap());

      // Update the customer with the generated ID
      await docRef.update({'id': docRef.id});

      return docRef.id;
    } catch (e) {
      throw CustomerServiceException(
          'Failed to create customer: ${e.toString()}');
    }
  }

  // Get a customer by ID
  Future<Customer?> getCustomer(String customerId) async {
    try {
      final doc = await _customersRef.doc(customerId).get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id; // Ensure ID is set

      return Customer.fromMap(data);
    } catch (e) {
      throw CustomerServiceException('Failed to get customer: ${e.toString()}');
    }
  }

  // Get all customers
  Future<List<Customer>> getAllCustomers() async {
    try {
      final querySnapshot =
          await _customersRef.orderBy('createdAt', descending: true).get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Ensure ID is set
        return Customer.fromMap(data);
      }).toList();
    } catch (e) {
      throw CustomerServiceException(
          'Failed to get customers: ${e.toString()}');
    }
  }

  // Update a customer
  Future<void> updateCustomer(Customer customer) async {
    try {
      await _customersRef.doc(customer.id).update(customer.toMap());
    } catch (e) {
      throw CustomerServiceException(
          'Failed to update customer: ${e.toString()}');
    }
  }

  // Delete a customer
  Future<void> deleteCustomer(String customerId) async {
    try {
      // First, check if customer has any vehicles or service records
      final hasRelatedData = await _hasRelatedData(customerId);

      if (hasRelatedData) {
        throw CustomerServiceException(
            'Cannot delete customer with existing vehicles or service records. Please remove all related data first.');
      }

      await _customersRef.doc(customerId).delete();
    } catch (e) {
      if (e is CustomerServiceException) {
        rethrow;
      }
      throw CustomerServiceException(
          'Failed to delete customer: ${e.toString()}');
    }
  }

  // Delete a customer along with all related data (vehicles and service records)
  Future<void> deleteCustomerWithRelatedData(String customerId) async {
    try {
      final batch = _firestore.batch();

      // Delete all vehicles belonging to this customer
      final vehiclesQuery = await _firestore
          .collection('vehicles')
          .where('customerId', isEqualTo: customerId)
          .get();

      for (final vehicleDoc in vehiclesQuery.docs) {
        batch.delete(vehicleDoc.reference);
      }

      // Delete all service records belonging to this customer
      final serviceRecordsQuery = await _firestore
          .collection('service_records')
          .where('customerId', isEqualTo: customerId)
          .get();

      for (final serviceDoc in serviceRecordsQuery.docs) {
        batch.delete(serviceDoc.reference);
      }

      // Delete the customer
      batch.delete(_customersRef.doc(customerId));

      // Execute all deletions in a single batch
      await batch.commit();
    } catch (e) {
      throw CustomerServiceException(
          'Failed to delete customer and related data: ${e.toString()}');
    }
  }

  // Get related data counts for a customer
  Future<RelatedDataInfo> getRelatedDataInfo(String customerId) async {
    try {
      // Count vehicles
      final vehiclesQuery = await _firestore
          .collection('vehicles')
          .where('customerId', isEqualTo: customerId)
          .get();

      // Count service records
      final serviceRecordsQuery = await _firestore
          .collection('service_records')
          .where('customerId', isEqualTo: customerId)
          .get();

      return RelatedDataInfo(
        vehicleCount: vehiclesQuery.docs.length,
        serviceRecordCount: serviceRecordsQuery.docs.length,
      );
    } catch (e) {
      throw CustomerServiceException(
          'Failed to get related data info: ${e.toString()}');
    }
  }

  // Check if customer has related data (vehicles, service records)
  Future<bool> _hasRelatedData(String customerId) async {
    try {
      // Check for vehicles
      final vehiclesQuery = await _firestore
          .collection('vehicles')
          .where('customerId', isEqualTo: customerId)
          .limit(1)
          .get();

      if (vehiclesQuery.docs.isNotEmpty) {
        return true;
      }

      // Check for service records
      final serviceRecordsQuery = await _firestore
          .collection('service_records')
          .where('customerId', isEqualTo: customerId)
          .limit(1)
          .get();

      return serviceRecordsQuery.docs.isNotEmpty;
    } catch (e) {
      // If we can't check, assume there's related data to be safe
      return true;
    }
  }

  // Get customers stream for real-time updates
  Stream<List<Customer>> getCustomersStream() {
    return _customersRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Ensure ID is set
        return Customer.fromMap(data);
      }).toList();
    });
  }

  // Get customer stream for real-time updates
  Stream<Customer?> getCustomerStream(String customerId) {
    return _customersRef.doc(customerId).snapshots().map((doc) {
      if (!doc.exists) {
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id; // Ensure ID is set

      return Customer.fromMap(data);
    });
  }

  // Search customers by name, email, or phone
  Future<List<Customer>> searchCustomers(String query) async {
    try {
      if (query.isEmpty) {
        return await getAllCustomers();
      }

      final lowercaseQuery = query.toLowerCase();

      // Get all customers and filter locally (Firestore has limited search capabilities)
      final allCustomers = await getAllCustomers();

      return allCustomers.where((customer) {
        return customer.fullName.toLowerCase().contains(lowercaseQuery) ||
            customer.email.toLowerCase().contains(lowercaseQuery) ||
            customer.phone.contains(query);
      }).toList();
    } catch (e) {
      throw CustomerServiceException(
          'Failed to search customers: ${e.toString()}');
    }
  }

  // Get customers by filter
  Future<List<Customer>> getCustomersByFilter(CustomerFilter filter) async {
    try {
      final allCustomers = await getAllCustomers();

      return allCustomers.where((customer) {
        switch (filter) {
          case CustomerFilter.vip:
            return customer.isVip;
          case CustomerFilter.recent:
            return customer.computedLastVisit != null &&
                customer.daysSinceLastVisit <= 30;
          case CustomerFilter.inactive:
            return customer.computedLastVisit == null ||
                customer.daysSinceLastVisit > 90;
          case CustomerFilter.all:
            return true;
        }
      }).toList();
    } catch (e) {
      throw CustomerServiceException(
          'Failed to filter customers: ${e.toString()}');
    }
  }

  // Update customer's total spent and visit count
  Future<void> updateCustomerStats(
      String customerId, double additionalSpent) async {
    try {
      final customer = await getCustomer(customerId);
      if (customer == null) {
        throw CustomerServiceException('Customer not found');
      }

      final updatedCustomer = customer.copyWith(
        totalSpent: customer.totalSpent + additionalSpent,
        lastVisit: DateTime.now(),
      );

      await updateCustomer(updatedCustomer);
    } catch (e) {
      if (e is CustomerServiceException) {
        rethrow;
      }
      throw CustomerServiceException(
          'Failed to update customer stats: ${e.toString()}');
    }
  }

  // Add communication log to customer
  Future<void> addCommunicationLog(
      String customerId, CommunicationLog log) async {
    try {
      final customer = await getCustomer(customerId);
      if (customer == null) {
        throw CustomerServiceException('Customer not found');
      }

      final updatedHistory =
          List<CommunicationLog>.from(customer.communicationHistory)..add(log);

      final updatedCustomer = customer.copyWith(
        communicationHistory: updatedHistory,
      );

      await updateCustomer(updatedCustomer);
    } catch (e) {
      if (e is CustomerServiceException) {
        rethrow;
      }
      throw CustomerServiceException(
          'Failed to add communication log: ${e.toString()}');
    }
  }

  // Add vehicle ID to customer
  Future<void> addVehicleToCustomer(String customerId, String vehicleId) async {
    try {
      final customer = await getCustomer(customerId);
      if (customer == null) {
        throw CustomerServiceException('Customer not found');
      }

      if (customer.vehicleIds.contains(vehicleId)) {
        return; // Vehicle already linked
      }

      final updatedVehicleIds = List<String>.from(customer.vehicleIds)
        ..add(vehicleId);

      final updatedCustomer = customer.copyWith(
        vehicleIds: updatedVehicleIds,
      );

      await updateCustomer(updatedCustomer);
    } catch (e) {
      if (e is CustomerServiceException) {
        rethrow;
      }
      throw CustomerServiceException(
          'Failed to add vehicle to customer: ${e.toString()}');
    }
  }

  // Remove vehicle ID from customer
  Future<void> removeVehicleFromCustomer(
      String customerId, String vehicleId) async {
    try {
      final customer = await getCustomer(customerId);
      if (customer == null) {
        throw CustomerServiceException('Customer not found');
      }

      final updatedVehicleIds = List<String>.from(customer.vehicleIds)
        ..remove(vehicleId);

      final updatedCustomer = customer.copyWith(
        vehicleIds: updatedVehicleIds,
      );

      await updateCustomer(updatedCustomer);
    } catch (e) {
      if (e is CustomerServiceException) {
        rethrow;
      }
      throw CustomerServiceException(
          'Failed to remove vehicle from customer: ${e.toString()}');
    }
  }

  // Batch create customers (for sample data population)
  Future<void> batchCreateCustomers(List<Customer> customers) async {
    try {
      final batch = _firestore.batch();

      for (final customer in customers) {
        final docRef = _customersRef.doc();
        final customerData = customer.copyWith(id: docRef.id).toMap();
        batch.set(docRef, customerData);
      }

      await batch.commit();
    } catch (e) {
      throw CustomerServiceException(
          'Failed to batch create customers: ${e.toString()}');
    }
  }
}

// Custom exception class for customer service errors
class CustomerServiceException implements Exception {
  final String message;

  CustomerServiceException(this.message);

  @override
  String toString() => 'CustomerServiceException: $message';
}

// Enum for customer filters
enum CustomerFilter {
  all,
  vip,
  recent,
  inactive,
}

// Related data information for a customer
class RelatedDataInfo {
  final int vehicleCount;
  final int serviceRecordCount;

  RelatedDataInfo({
    required this.vehicleCount,
    required this.serviceRecordCount,
  });

  bool get hasRelatedData => vehicleCount > 0 || serviceRecordCount > 0;

  String get relatedDataDescription {
    final parts = <String>[];
    if (vehicleCount > 0) {
      parts.add('$vehicleCount vehicle${vehicleCount != 1 ? 's' : ''}');
    }
    if (serviceRecordCount > 0) {
      parts.add(
          '$serviceRecordCount service record${serviceRecordCount != 1 ? 's' : ''}');
    }
    return parts.join(' and ');
  }
}
