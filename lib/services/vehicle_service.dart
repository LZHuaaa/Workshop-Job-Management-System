import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/vehicle.dart';
import '../models/service_record.dart' as sr;
import 'customer_service.dart';

class VehicleService {
  static final VehicleService _instance = VehicleService._internal();
  factory VehicleService() => _instance;
  VehicleService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'vehicles';
  final CustomerService _customerService = CustomerService();

  // Get vehicles collection reference
  CollectionReference get _vehiclesRef => _firestore.collection(_collection);

  // Create a new vehicle
  Future<String> createVehicle(Vehicle vehicle) async {
    try {
      final docRef = await _vehiclesRef.add(vehicle.toMap());

      // Update the vehicle with the generated ID
      await docRef.update({'id': docRef.id});

      // Add vehicle ID to customer's vehicle list
      await _customerService.addVehicleToCustomer(
          vehicle.customerId, docRef.id);

      return docRef.id;
    } catch (e) {
      throw VehicleServiceException(
          'Failed to create vehicle: ${e.toString()}');
    }
  }

  // Get a vehicle by ID
  Future<Vehicle?> getVehicle(String vehicleId) async {
    try {
      final doc = await _vehiclesRef.doc(vehicleId).get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id; // Ensure ID is set

      return Vehicle.fromMap(data);
    } catch (e) {
      throw VehicleServiceException('Failed to get vehicle: ${e.toString()}');
    }
  }

  // Get all vehicles
  Future<List<Vehicle>> getAllVehicles() async {
    try {
      final querySnapshot =
          await _vehiclesRef.orderBy('createdAt', descending: true).get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Ensure ID is set
        return Vehicle.fromMap(data);
      }).toList();
    } catch (e) {
      throw VehicleServiceException('Failed to get vehicles: ${e.toString()}');
    }
  }

  // Get vehicles by customer ID
  Future<List<Vehicle>> getVehiclesByCustomer(String customerId) async {
    try {
      final querySnapshot = await _vehiclesRef
          .where('customerId', isEqualTo: customerId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Ensure ID is set
        return Vehicle.fromMap(data);
      }).toList();
    } catch (e) {
      throw VehicleServiceException(
          'Failed to get customer vehicles: ${e.toString()}');
    }
  }

  // Update a vehicle
  Future<void> updateVehicle(Vehicle vehicle) async {
    try {
      await _vehiclesRef.doc(vehicle.id).update(vehicle.toMap());
    } catch (e) {
      throw VehicleServiceException(
          'Failed to update vehicle: ${e.toString()}');
    }
  }

  // Delete a vehicle
  Future<void> deleteVehicle(String vehicleId) async {
    try {
      final vehicle = await getVehicle(vehicleId);
      if (vehicle == null) {
        throw VehicleServiceException('Vehicle not found');
      }

      // Check if vehicle has service records
      final hasServiceRecords = await _hasServiceRecords(vehicleId);

      if (hasServiceRecords) {
        throw VehicleServiceException(
            'Cannot delete vehicle with existing service records. Please remove all service records first.');
      }

      // Remove vehicle ID from customer's vehicle list
      await _customerService.removeVehicleFromCustomer(
          vehicle.customerId, vehicleId);

      // Delete the vehicle
      await _vehiclesRef.doc(vehicleId).delete();
    } catch (e) {
      if (e is VehicleServiceException) {
        rethrow;
      }
      throw VehicleServiceException(
          'Failed to delete vehicle: ${e.toString()}');
    }
  }

  // Check if vehicle has service records
  Future<bool> _hasServiceRecords(String vehicleId) async {
    try {
      final serviceRecordsQuery = await _firestore
          .collection('service_records')
          .where('vehicleId', isEqualTo: vehicleId)
          .limit(1)
          .get();

      return serviceRecordsQuery.docs.isNotEmpty;
    } catch (e) {
      // If we can't check, assume there are service records to be safe
      return true;
    }
  }

  // Get vehicles stream for real-time updates
  Stream<List<Vehicle>> getVehiclesStream() {
    return _vehiclesRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Ensure ID is set
        return Vehicle.fromMap(data);
      }).toList();
    });
  }

  // Get vehicles stream by customer
  Stream<List<Vehicle>> getVehiclesByCustomerStream(String customerId) {
    return _vehiclesRef
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Ensure ID is set
        return Vehicle.fromMap(data);
      }).toList();
    });
  }

  // Get vehicle stream for real-time updates
  Stream<Vehicle?> getVehicleStream(String vehicleId) {
    return _vehiclesRef.doc(vehicleId).snapshots().map((doc) {
      if (!doc.exists) {
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id; // Ensure ID is set

      return Vehicle.fromMap(data);
    });
  }

  // Search vehicles by make, model, license plate, or VIN
  Future<List<Vehicle>> searchVehicles(String query) async {
    try {
      if (query.isEmpty) {
        return await getAllVehicles();
      }

      final lowercaseQuery = query.toLowerCase();

      // Get all vehicles and filter locally (Firestore has limited search capabilities)
      final allVehicles = await getAllVehicles();

      return allVehicles.where((vehicle) {
        return vehicle.make.toLowerCase().contains(lowercaseQuery) ||
            vehicle.model.toLowerCase().contains(lowercaseQuery) ||
            vehicle.licensePlate.toLowerCase().contains(lowercaseQuery) ||
            vehicle.vin.toLowerCase().contains(lowercaseQuery) ||
            vehicle.customerName.toLowerCase().contains(lowercaseQuery);
      }).toList();
    } catch (e) {
      throw VehicleServiceException(
          'Failed to search vehicles: ${e.toString()}');
    }
  }

  // Get vehicles that need service
  Future<List<Vehicle>> getVehiclesNeedingService() async {
    try {
      final allVehicles = await getAllVehicles();
      return allVehicles.where((vehicle) => vehicle.needsService).toList();
    } catch (e) {
      throw VehicleServiceException(
          'Failed to get vehicles needing service: ${e.toString()}');
    }
  }

  // Update vehicle service date
  Future<void> updateVehicleServiceDate(
      String vehicleId, DateTime serviceDate) async {
    try {
      await _vehiclesRef.doc(vehicleId).update({
        'lastServiceDate': serviceDate.toIso8601String(),
      });
    } catch (e) {
      throw VehicleServiceException(
          'Failed to update vehicle service date: ${e.toString()}');
    }
  }

  // Update vehicle mileage
  Future<void> updateVehicleMileage(String vehicleId, int mileage) async {
    try {
      await _vehiclesRef.doc(vehicleId).update({
        'mileage': mileage,
      });
    } catch (e) {
      throw VehicleServiceException(
          'Failed to update vehicle mileage: ${e.toString()}');
    }
  }

  // Add photo to vehicle
  Future<void> addPhotoToVehicle(String vehicleId, String photoUrl) async {
    try {
      final vehicle = await getVehicle(vehicleId);
      if (vehicle == null) {
        throw VehicleServiceException('Vehicle not found');
      }

      final updatedPhotos = List<String>.from(vehicle.photos)..add(photoUrl);

      final updatedVehicle = vehicle.copyWith(photos: updatedPhotos);
      await updateVehicle(updatedVehicle);
    } catch (e) {
      if (e is VehicleServiceException) {
        rethrow;
      }
      throw VehicleServiceException(
          'Failed to add photo to vehicle: ${e.toString()}');
    }
  }

  // Remove photo from vehicle
  Future<void> removePhotoFromVehicle(String vehicleId, String photoUrl) async {
    try {
      final vehicle = await getVehicle(vehicleId);
      if (vehicle == null) {
        throw VehicleServiceException('Vehicle not found');
      }

      final updatedPhotos = List<String>.from(vehicle.photos)..remove(photoUrl);

      final updatedVehicle = vehicle.copyWith(photos: updatedPhotos);
      await updateVehicle(updatedVehicle);
    } catch (e) {
      if (e is VehicleServiceException) {
        rethrow;
      }
      throw VehicleServiceException(
          'Failed to remove photo from vehicle: ${e.toString()}');
    }
  }

  // Get vehicles by make
  Future<List<Vehicle>> getVehiclesByMake(String make) async {
    try {
      final querySnapshot = await _vehiclesRef
          .where('make', isEqualTo: make)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Ensure ID is set
        return Vehicle.fromMap(data);
      }).toList();
    } catch (e) {
      throw VehicleServiceException(
          'Failed to get vehicles by make: ${e.toString()}');
    }
  }

  // Get vehicle statistics
  Future<VehicleStats> getVehicleStats() async {
    try {
      final allVehicles = await getAllVehicles();

      final totalVehicles = allVehicles.length;
      final vehiclesNeedingService =
          allVehicles.where((v) => v.needsService).length;

      // Group by make
      final makeGroups = <String, int>{};
      for (final vehicle in allVehicles) {
        makeGroups[vehicle.make] = (makeGroups[vehicle.make] ?? 0) + 1;
      }

      // Calculate average mileage
      final totalMileage =
          allVehicles.fold<int>(0, (sum, vehicle) => sum + vehicle.mileage);
      final averageMileage =
          totalVehicles > 0 ? totalMileage / totalVehicles : 0.0;

      return VehicleStats(
        totalVehicles: totalVehicles,
        vehiclesNeedingService: vehiclesNeedingService,
        averageMileage: averageMileage,
        makeDistribution: makeGroups,
      );
    } catch (e) {
      throw VehicleServiceException(
          'Failed to get vehicle statistics: ${e.toString()}');
    }
  }

  // Batch create vehicles (for sample data population)
  Future<void> batchCreateVehicles(List<Vehicle> vehicles) async {
    try {
      final batch = _firestore.batch();

      for (final vehicle in vehicles) {
        final docRef = _vehiclesRef.doc();
        final vehicleData = vehicle.copyWith(id: docRef.id).toMap();
        batch.set(docRef, vehicleData);
      }

      await batch.commit();
    } catch (e) {
      throw VehicleServiceException(
          'Failed to batch create vehicles: ${e.toString()}');
    }
  }

  // Check VIN uniqueness
  Future<bool> isVinUnique(String vin, {String? excludeVehicleId}) async {
    try {
      Query query = _vehiclesRef.where('vin', isEqualTo: vin);

      final querySnapshot = await query.get();

      if (excludeVehicleId != null) {
        // When updating, exclude the current vehicle from the check
        return querySnapshot.docs
            .where((doc) => doc.id != excludeVehicleId)
            .isEmpty;
      }

      return querySnapshot.docs.isEmpty;
    } catch (e) {
      throw VehicleServiceException(
          'Failed to check VIN uniqueness: ${e.toString()}');
    }
  }

  // Check license plate uniqueness
  Future<bool> isLicensePlateUnique(String licensePlate,
      {String? excludeVehicleId}) async {
    try {
      Query query = _vehiclesRef.where('licensePlate', isEqualTo: licensePlate);

      final querySnapshot = await query.get();

      if (excludeVehicleId != null) {
        // When updating, exclude the current vehicle from the check
        return querySnapshot.docs
            .where((doc) => doc.id != excludeVehicleId)
            .isEmpty;
      }

      return querySnapshot.docs.isEmpty;
    } catch (e) {
      throw VehicleServiceException(
          'Failed to check license plate uniqueness: ${e.toString()}');
    }
  }
}

// Custom exception class for vehicle service errors
class VehicleServiceException implements Exception {
  final String message;

  VehicleServiceException(this.message);

  @override
  String toString() => 'VehicleServiceException: $message';
}

// Vehicle statistics model
class VehicleStats {
  final int totalVehicles;
  final int vehiclesNeedingService;
  final double averageMileage;
  final Map<String, int> makeDistribution;

  VehicleStats({
    required this.totalVehicles,
    required this.vehiclesNeedingService,
    required this.averageMileage,
    required this.makeDistribution,
  });
}
