import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/customer.dart';
import '../models/vehicle.dart';
import '../models/service_record.dart' as sr;
import '../models/service_record.dart';
import '../models/job_appointment.dart';
import '../models/invoice.dart';
import '../models/inventory_item.dart';
import '../models/order_request.dart';
import '../services/inventory_usage_data_populator.dart';
import 'sample_data_generator.dart';

class FirebaseDataPopulator {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection names
  static const String customersCollection = 'customers';
  static const String vehiclesCollection = 'vehicles';
  static const String serviceRecordsCollection = 'service_records';
  static const String appointmentsCollection = 'appointments';
  static const String invoicesCollection = 'invoices';
  static const String inventoryCollection = 'inventory';
  static const String orderRequestsCollection = 'order_requests';
  static const String inventoryUsageCollection = 'inventory_usage';

  /// Populate Firebase with comprehensive Malaysian sample data
  static Future<void> populateAllData({
    int customerCount = 30,
    int maxVehiclesPerCustomer = 3,
    int maxServiceRecordsPerVehicle = 5,
    int appointmentCount = 25,
    int invoiceCount = 20,
    int inventoryItemCount = 50,
    int orderRequestCount = 15,
    int inventoryUsageCount = 25,
  }) async {
    try {
      debugPrint('🚀 Starting Firebase data population...');

      // Step 1: Generate all sample data
      debugPrint('📊 Generating sample data...');
      final customers = SampleDataGenerator.generateCustomers(customerCount);
      final vehicles = SampleDataGenerator.generateVehicles(
          customers, maxVehiclesPerCustomer);
      final serviceRecords = SampleDataGenerator.generateServiceRecords(
          vehicles, maxServiceRecordsPerVehicle);
      final appointments = SampleDataGenerator.generateJobAppointments(
          vehicles, appointmentCount);
      final invoices =
          SampleDataGenerator.generateInvoices(serviceRecords, invoiceCount);
      final inventoryItems =
          SampleDataGenerator.generateInventoryItems(inventoryItemCount);
      final orderRequests = SampleDataGenerator.generateOrderRequests(
          inventoryItems, orderRequestCount);

      debugPrint('✅ Generated:');
      debugPrint('   - ${customers.length} customers');
      debugPrint('   - ${vehicles.length} vehicles');
      debugPrint('   - ${serviceRecords.length} service records');
      debugPrint('   - ${appointments.length} appointments');
      debugPrint('   - ${invoices.length} invoices');
      debugPrint('   - ${inventoryItems.length} inventory items');
      debugPrint('   - ${orderRequests.length} order requests');
      debugPrint(
          '   - $inventoryUsageCount inventory usage records (to be generated)');

      // Step 2: Update relationships
      debugPrint('🔗 Updating data relationships...');
      _updateDataRelationships(customers, vehicles, serviceRecords, invoices);

      // Step 3: Populate Firebase collections
      debugPrint('🔥 Populating Firebase collections...');

      await _populateCustomers(customers);
      await _populateVehicles(vehicles);
      await _populateServiceRecords(serviceRecords);
      await _populateAppointments(appointments);
      await _populateInvoices(invoices);
      await _populateInventoryItems(inventoryItems);
      await _populateOrderRequests(orderRequests);

      // Step 4: Populate inventory usage data (after inventory items are created)
      debugPrint('📝 Populating inventory usage data...');
      await InventoryUsageDataPopulator.populateInventoryUsage(
        usageRecordCount: inventoryUsageCount,
      );

      debugPrint('🎉 Firebase data population completed successfully!');
    } catch (e) {
      debugPrint('❌ Error populating Firebase data: $e');
      rethrow;
    }
  }

  /// Update relationships between data entities
  static void _updateDataRelationships(
    List<Customer> customers,
    List<Vehicle> vehicles,
    List<sr.ServiceRecord> serviceRecords,
    List<Invoice> invoices,
  ) {
    // Update customer vehicle IDs and service history
    for (final customer in customers) {
      final customerVehicles =
          vehicles.where((v) => v.customerId == customer.id).toList();
      final customerServiceRecords =
          serviceRecords.where((s) => s.customerId == customer.id).toList();

      // Convert sr.ServiceRecord to ServiceRecord (customer model type)
      final customerServiceHistory = customerServiceRecords.map((srRecord) {
        return ServiceRecord(
          id: srRecord.id,
          customerId: srRecord.customerId,
          vehicleId: srRecord.vehicleId,
          serviceDate: srRecord.serviceDate,
          serviceType: srRecord.serviceType,
          description: srRecord.description,
          servicesPerformed: srRecord.servicesPerformed,
          cost: srRecord.cost,
          mechanicName: srRecord.mechanicName,
          status: ServiceStatus.values.firstWhere(
            (e) => e.name == srRecord.status.name,
            orElse: () => ServiceStatus.completed,
          ),
          nextServiceDue: srRecord.nextServiceDue,
          mileage: srRecord.mileage,
          partsReplaced: srRecord.partsReplaced,
          notes: srRecord.notes,
        );
      }).toList();

      // Update customer with vehicle IDs, service history, and calculated values
      final updatedCustomer = customer.copyWith(
        vehicleIds: customerVehicles.map((v) => v.id).toList(),
        serviceHistory: customerServiceHistory,
        totalSpent: customerServiceRecords.fold<double>(
            0.0, (double total, record) => total + record.cost),
        lastVisit: customerServiceRecords.isNotEmpty
            ? customerServiceRecords
                .map((r) => r.serviceDate)
                .reduce((a, b) => a.isAfter(b) ? a : b)
            : null,
      );

      // Replace customer in list
      final index = customers.indexOf(customer);
      customers[index] = updatedCustomer;
    }

    // Update vehicle service history
    for (final vehicle in vehicles) {
      final vehicleServiceRecords =
          serviceRecords.where((s) => s.vehicleId == vehicle.id).toList();

      if (vehicleServiceRecords.isNotEmpty) {
        final lastServiceDate = vehicleServiceRecords
            .map((r) => r.serviceDate)
            .reduce((a, b) => a.isAfter(b) ? a : b);

        final updatedVehicle = vehicle.copyWith(
          lastServiceDate: lastServiceDate,
        );

        // Replace vehicle in list
        final index = vehicles.indexOf(vehicle);
        vehicles[index] = updatedVehicle;
      }
    }

    // Update invoice customer names
    for (final invoice in invoices) {
      final customer = customers.firstWhere((c) => c.id == invoice.customerId);
      final updatedInvoice = Invoice(
        id: invoice.id,
        customerId: invoice.customerId,
        customerName: customer.fullName,
        vehicleId: invoice.vehicleId,
        jobId: invoice.jobId,
        issueDate: invoice.issueDate,
        dueDate: invoice.dueDate,
        items: invoice.items,
        status: invoice.status,
        notes: invoice.notes,
      );

      // Replace invoice in list
      final index = invoices.indexOf(invoice);
      invoices[index] = updatedInvoice;
    }
  }

  /// Populate customers collection
  static Future<void> _populateCustomers(List<Customer> customers) async {
    debugPrint('👥 Populating customers...');
    final batch = _firestore.batch();

    for (final customer in customers) {
      final docRef =
          _firestore.collection(customersCollection).doc(customer.id);
      batch.set(docRef, _customerToMap(customer));
    }

    await batch.commit();
    debugPrint('✅ ${customers.length} customers added to Firestore');
  }

  /// Populate vehicles collection
  static Future<void> _populateVehicles(List<Vehicle> vehicles) async {
    debugPrint('🚗 Populating vehicles...');
    final batch = _firestore.batch();

    for (final vehicle in vehicles) {
      final docRef = _firestore.collection(vehiclesCollection).doc(vehicle.id);
      batch.set(docRef, _vehicleToMap(vehicle));
    }

    await batch.commit();
    debugPrint('✅ ${vehicles.length} vehicles added to Firestore');
  }

  /// Populate service records collection
  static Future<void> _populateServiceRecords(
      List<sr.ServiceRecord> serviceRecords) async {
    debugPrint('🔧 Populating service records...');
    final batch = _firestore.batch();

    for (final serviceRecord in serviceRecords) {
      final docRef =
          _firestore.collection(serviceRecordsCollection).doc(serviceRecord.id);
      batch.set(docRef, _serviceRecordToMap(serviceRecord));
    }

    await batch.commit();
    debugPrint('✅ ${serviceRecords.length} service records added to Firestore');
  }

  /// Populate appointments collection
  static Future<void> _populateAppointments(
      List<JobAppointment> appointments) async {
    debugPrint('📅 Populating appointments...');
    final batch = _firestore.batch();

    for (final appointment in appointments) {
      final docRef =
          _firestore.collection(appointmentsCollection).doc(appointment.id);
      batch.set(docRef, _appointmentToMap(appointment));
    }

    await batch.commit();
    debugPrint('✅ ${appointments.length} appointments added to Firestore');
  }

  /// Populate invoices collection
  static Future<void> _populateInvoices(List<Invoice> invoices) async {
    debugPrint('💰 Populating invoices...');
    final batch = _firestore.batch();

    for (final invoice in invoices) {
      final docRef = _firestore.collection(invoicesCollection).doc(invoice.id);
      batch.set(docRef, invoice.toJson());
    }

    await batch.commit();
    debugPrint('✅ ${invoices.length} invoices added to Firestore');
  }

  /// Populate inventory items collection
  static Future<void> _populateInventoryItems(
      List<InventoryItem> inventoryItems) async {
    debugPrint('📦 Populating inventory items...');
    final batch = _firestore.batch();

    for (final item in inventoryItems) {
      final docRef = _firestore.collection(inventoryCollection).doc(item.id);
      batch.set(docRef, _inventoryItemToMap(item));
    }

    await batch.commit();
    debugPrint('✅ ${inventoryItems.length} inventory items added to Firestore');
  }

  /// Populate order requests collection
  static Future<void> _populateOrderRequests(
      List<OrderRequest> orderRequests) async {
    debugPrint('📋 Populating order requests...');
    final batch = _firestore.batch();

    for (final orderRequest in orderRequests) {
      final docRef =
          _firestore.collection(orderRequestsCollection).doc(orderRequest.id);
      batch.set(docRef, orderRequest.toJson());
    }

    await batch.commit();
    debugPrint('✅ ${orderRequests.length} order requests added to Firestore');
  }

  /// Clear all data from Firebase (use with caution!)
  static Future<void> clearAllData() async {
    debugPrint('🗑️ Clearing all data from Firebase...');

    final collections = [
      customersCollection,
      vehiclesCollection,
      serviceRecordsCollection,
      appointmentsCollection,
      invoicesCollection,
      inventoryCollection,
      orderRequestsCollection,
      inventoryUsageCollection,
    ];

    for (final collectionName in collections) {
      final collection = _firestore.collection(collectionName);
      final snapshot = await collection.get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      debugPrint('✅ Cleared $collectionName collection');
    }

    debugPrint('🎉 All data cleared from Firebase');
  }

  /// Clear only customer data from Firebase
  static Future<void> clearCustomerData() async {
    debugPrint('🗑️ Clearing customer data from Firebase...');

    final collection = _firestore.collection(customersCollection);
    final snapshot = await collection.get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();

    debugPrint('✅ Cleared customers collection');
  }

  /// Re-populate customer data with correct service history
  static Future<void> repopulateCustomerData({int customerCount = 30}) async {
    try {
      debugPrint(
          '🔄 Re-populating customer data with correct service history...');

      // First, get existing vehicles and service records from Firebase
      debugPrint('📋 Fetching existing vehicles and service records...');

      final vehiclesSnapshot =
          await _firestore.collection(vehiclesCollection).get();
      final serviceRecordsSnapshot =
          await _firestore.collection(serviceRecordsCollection).get();

      if (vehiclesSnapshot.docs.isEmpty ||
          serviceRecordsSnapshot.docs.isEmpty) {
        debugPrint(
            '❌ No existing vehicles or service records found. Please populate all data first.');
        return;
      }

      // Clear existing customer data
      await clearCustomerData();

      // Generate new customers with the same count
      debugPrint('👥 Generating new customers...');
      final customers = SampleDataGenerator.generateCustomers(customerCount);

      // Convert Firebase data back to objects for relationship mapping
      final vehicles = <Vehicle>[];
      final serviceRecords = <sr.ServiceRecord>[];

      for (final doc in vehiclesSnapshot.docs) {
        try {
          vehicles.add(_vehicleFromMap(doc.data(), doc.id));
        } catch (e) {
          debugPrint('⚠️ Error parsing vehicle ${doc.id}: $e');
        }
      }

      for (final doc in serviceRecordsSnapshot.docs) {
        try {
          serviceRecords.add(_serviceRecordFromMap(doc.data(), doc.id));
        } catch (e) {
          debugPrint('⚠️ Error parsing service record ${doc.id}: $e');
        }
      }

      debugPrint(
          '✅ Loaded ${vehicles.length} vehicles and ${serviceRecords.length} service records');

      // Update relationships between customers and their data
      debugPrint('🔗 Updating customer relationships...');
      _updateCustomerRelationships(customers, vehicles, serviceRecords);

      // Populate customers with correct service history
      await _populateCustomers(customers);

      debugPrint('🎉 Customer data re-population completed successfully!');
      debugPrint(
          '📊 Updated ${customers.length} customers with service history');
    } catch (e) {
      debugPrint('❌ Error re-populating customer data: $e');
      rethrow;
    }
  }

  /// Update customer relationships specifically
  static void _updateCustomerRelationships(
    List<Customer> customers,
    List<Vehicle> vehicles,
    List<sr.ServiceRecord> serviceRecords,
  ) {
    for (int i = 0; i < customers.length; i++) {
      final customer = customers[i];
      final customerVehicles =
          vehicles.where((v) => v.customerId == customer.id).toList();
      final customerServiceRecords =
          serviceRecords.where((s) => s.customerId == customer.id).toList();

      // Convert sr.ServiceRecord to ServiceRecord (customer model type)
      final customerServiceHistory = customerServiceRecords.map((srRecord) {
        return ServiceRecord(
          id: srRecord.id,
          customerId: srRecord.customerId,
          vehicleId: srRecord.vehicleId,
          serviceDate: srRecord.serviceDate,
          serviceType: srRecord.serviceType,
          description: srRecord.description,
          servicesPerformed: srRecord.servicesPerformed,
          cost: srRecord.cost,
          mechanicName: srRecord.mechanicName,
          status: ServiceStatus.values.firstWhere(
            (e) => e.name == srRecord.status.name,
            orElse: () => ServiceStatus.completed,
          ),
          nextServiceDue: srRecord.nextServiceDue,
          mileage: srRecord.mileage,
          partsReplaced: srRecord.partsReplaced,
          notes: srRecord.notes,
        );
      }).toList();

      // Update customer with vehicle IDs, service history, and calculated values
      final updatedCustomer = customer.copyWith(
        vehicleIds: customerVehicles.map((v) => v.id).toList(),
        serviceHistory: customerServiceHistory,
        totalSpent: customerServiceRecords.fold<double>(
            0.0, (double total, record) => total + record.cost),
        lastVisit: customerServiceRecords.isNotEmpty
            ? customerServiceRecords
                .map((r) => r.serviceDate)
                .reduce((a, b) => a.isAfter(b) ? a : b)
            : null,
      );

      customers[i] = updatedCustomer;

      debugPrint(
          '📝 Customer ${customer.fullName}: ${customerServiceHistory.length} visits, RM${updatedCustomer.totalSpent.toStringAsFixed(2)} spent');
    }
  }

  // Data mapping methods

  /// Convert Customer to Map for Firestore
  static Map<String, dynamic> _customerToMap(Customer customer) {
    return {
      'id': customer.id,
      'firstName': customer.firstName,
      'lastName': customer.lastName,
      'email': customer.email,
      'phone': customer.phone,
      'address': customer.address,
      'city': customer.city,
      'state': customer.state,
      'zipCode': customer.zipCode,
      'createdAt': Timestamp.fromDate(customer.createdAt),
      'lastVisit': customer.lastVisit != null
          ? Timestamp.fromDate(customer.lastVisit!)
          : null,
      'vehicleIds': customer.vehicleIds,
      'communicationHistory': customer.communicationHistory
          .map((comm) => _communicationLogToMap(comm))
          .toList(),
      'serviceHistory': customer.serviceHistory
          .map((service) => _serviceRecordToMap(service))
          .toList(),
      'preferences': _customerPreferencesToMap(customer.preferences),
      'totalSpent': customer.totalSpent,
      'notes': customer.notes,
    };
  }

  /// Convert Vehicle to Map for Firestore
  static Map<String, dynamic> _vehicleToMap(Vehicle vehicle) {
    return {
      'id': vehicle.id,
      'make': vehicle.make,
      'model': vehicle.model,
      'year': vehicle.year,
      'licensePlate': vehicle.licensePlate,
      'vin': vehicle.vin,
      'color': vehicle.color,
      'mileage': vehicle.mileage,
      'customerId': vehicle.customerId,
      'customerName': vehicle.customerName,
      'customerPhone': vehicle.customerPhone,
      'customerEmail': vehicle.customerEmail,
      'createdAt': Timestamp.fromDate(vehicle.createdAt),
      'lastServiceDate': vehicle.lastServiceDate != null
          ? Timestamp.fromDate(vehicle.lastServiceDate!)
          : null,
      'serviceHistoryIds': vehicle.serviceHistoryIds,
      'serviceHistory':
          [], // Service history is now stored separately in service_records collection
      'photos': vehicle.photos,
      'notes': vehicle.notes,
    };
  }

  /// Convert ServiceRecord to Map for Firestore
  static Map<String, dynamic> _serviceRecordToMap(dynamic serviceRecord) {
    if (serviceRecord is sr.ServiceRecord) {
      return {
        'id': serviceRecord.id,
        'customerId': serviceRecord.customerId,
        'vehicleId': serviceRecord.vehicleId,
        'serviceDate': Timestamp.fromDate(serviceRecord.serviceDate),
        'serviceType': serviceRecord.serviceType,
        'description': serviceRecord.description,
        'servicesPerformed': serviceRecord.servicesPerformed,
        'cost': serviceRecord.cost,
        'mechanicName': serviceRecord.mechanicName,
        'status': serviceRecord.status.name,
        'nextServiceDue': serviceRecord.nextServiceDue != null
            ? Timestamp.fromDate(serviceRecord.nextServiceDue!)
            : null,
        'mileage': serviceRecord.mileage,
        'partsReplaced': serviceRecord.partsReplaced,
        'notes': serviceRecord.notes,
      };
    } else {
      // Handle the ServiceRecord from vehicle.dart (legacy format)
      return {
        'id': serviceRecord.id,
        'date': Timestamp.fromDate(serviceRecord.date),
        'mileage': serviceRecord.mileage,
        'serviceType': serviceRecord.serviceType,
        'description': serviceRecord.description,
        'partsUsed': serviceRecord.partsUsed,
        'laborHours': serviceRecord.laborHours,
        'totalCost': serviceRecord.totalCost,
        'mechanicName': serviceRecord.mechanicName,
        'notes': serviceRecord.notes,
      };
    }
  }

  /// Convert JobAppointment to Map for Firestore
  static Map<String, dynamic> _appointmentToMap(JobAppointment appointment) {
    return {
      'id': appointment.id,
      'vehicleInfo': appointment.vehicleInfo,
      'customerName': appointment.customerName,
      'mechanicName': appointment.mechanicName,
      'startTime': Timestamp.fromDate(appointment.startTime),
      'endTime': Timestamp.fromDate(appointment.endTime),
      'serviceType': appointment.serviceType,
      'status': appointment.status.name,
      'notes': appointment.notes,
      'partsNeeded': appointment.partsNeeded,
      'estimatedCost': appointment.estimatedCost,
    };
  }

  /// Convert InventoryItem to Map for Firestore
  static Map<String, dynamic> _inventoryItemToMap(InventoryItem item) {
    return {
      'id': item.id,
      'name': item.name,
      'category': item.category,
      'currentStock': item.currentStock,
      'minStock': item.minStock,
      'maxStock': item.maxStock,
      'unitPrice': item.unitPrice,
      'supplier': item.supplier,
      'location': item.location,
      'description': item.description,
      'lastRestocked': item.lastRestocked != null
          ? Timestamp.fromDate(item.lastRestocked!)
          : null,
      'imageUrl': item.imageUrl,
      'pendingOrderRequest': item.pendingOrderRequest,
      'orderRequestDate': item.orderRequestDate != null
          ? Timestamp.fromDate(item.orderRequestDate!)
          : null,
      'orderRequestId': item.orderRequestId,
    };
  }

  /// Convert CustomerPreferences to Map for Firestore
  static Map<String, dynamic> _customerPreferencesToMap(
      CustomerPreferences preferences) {
    return {
      'preferredContactMethod': preferences.preferredContactMethod,
      'receivePromotions': preferences.receivePromotions,
      'receiveReminders': preferences.receiveReminders,
      'preferredMechanic': preferences.preferredMechanic,
      'preferredServiceTime': preferences.preferredServiceTime,
    };
  }

  /// Convert CommunicationLog to Map for Firestore
  static Map<String, dynamic> _communicationLogToMap(CommunicationLog log) {
    return {
      'id': log.id,
      'date': Timestamp.fromDate(log.date),
      'type': log.type,
      'subject': log.subject,
      'content': log.content,
      'direction': log.direction,
      'staffMember': log.staffMember,
    };
  }

  // Helper methods to convert Firebase data back to objects

  /// Convert Firebase document to Vehicle object
  static Vehicle _vehicleFromMap(Map<String, dynamic> data, String docId) {
    return Vehicle(
      id: data['id'] ?? docId,
      make: data['make'] ?? '',
      model: data['model'] ?? '',
      year: data['year'] ?? 0,
      licensePlate: data['licensePlate'] ?? '',
      vin: data['vin'] ?? '',
      color: data['color'] ?? '',
      mileage: data['mileage'] ?? 0,
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? '',
      customerPhone: data['customerPhone'] ?? '',
      customerEmail: data['customerEmail'] ?? '',
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      lastServiceDate: data['lastServiceDate'] is Timestamp
          ? (data['lastServiceDate'] as Timestamp).toDate()
          : null,
      serviceHistoryIds: List<String>.from(data['serviceHistoryIds'] ?? []),
      photos: List<String>.from(data['photos'] ?? []),
      notes: data['notes'],
    );
  }

  /// Convert Firebase document to ServiceRecord object
  static sr.ServiceRecord _serviceRecordFromMap(
      Map<String, dynamic> data, String docId) {
    return sr.ServiceRecord(
      id: data['id'] ?? docId,
      customerId: data['customerId'] ?? '',
      vehicleId: data['vehicleId'] ?? '',
      serviceDate: data['serviceDate'] is Timestamp
          ? (data['serviceDate'] as Timestamp).toDate()
          : DateTime.now(),
      serviceType: data['serviceType'] ?? '',
      description: data['description'] ?? '',
      servicesPerformed: List<String>.from(data['servicesPerformed'] ?? []),
      cost: (data['cost'] ?? 0.0).toDouble(),
      mechanicName: data['mechanicName'] ?? '',
      status: sr.ServiceStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => sr.ServiceStatus.completed,
      ),
      nextServiceDue: data['nextServiceDue'] is Timestamp
          ? (data['nextServiceDue'] as Timestamp).toDate()
          : null,
      mileage: data['mileage'] ?? 0,
      partsReplaced: List<String>.from(data['partsReplaced'] ?? []),
      notes: data['notes'],
    );
  }
}
