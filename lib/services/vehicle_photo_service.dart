import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/enhanced_vehicle_photo_manager.dart';

/// Service for managing vehicle photo metadata in Firebase
class VehiclePhotoService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _photosCollection = 'vehicle_photos';

  /// Save photo metadata to Firebase
  static Future<void> savePhotoMetadata(VehiclePhoto photo) async {
    try {
      final data = photo.toMap();
      print('💾 Saving photo metadata to Firestore:');
      print('  Collection: $_photosCollection');
      print('  Document ID: ${photo.id}');
      print('  Data: $data');

      await _firestore
          .collection(_photosCollection)
          .doc(photo.id)
          .set(data);

      print('✅ Photo metadata saved successfully');
    } catch (e) {
      print('❌ Failed to save photo metadata: $e');
      throw VehiclePhotoServiceException(
        'Failed to save photo metadata: ${e.toString()}',
      );
    }
  }

  /// Get all photos for a vehicle with metadata
  static Future<List<VehiclePhoto>> getVehiclePhotos(String vehicleId) async {
    try {
      print('🔍 Querying photos for vehicle: $vehicleId');
      print('  Collection: $_photosCollection');

      // Query without orderBy to avoid composite index requirement
      final snapshot = await _firestore
          .collection(_photosCollection)
          .where('vehicleId', isEqualTo: vehicleId)
          .get();

      print('📊 Found ${snapshot.docs.length} photo documents');

      // Convert to VehiclePhoto objects and sort client-side
      final photos = snapshot.docs.map((doc) {
        final data = doc.data();
        print('  - Doc ID: ${doc.id}, Data: $data');
        return VehiclePhoto.fromMap(data);
      }).toList();

      // Sort by createdAt on client side
      photos.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      print('✅ Returning ${photos.length} VehiclePhoto objects');
      return photos;
    } catch (e) {
      print('❌ Error getting vehicle photos: $e');
      throw VehiclePhotoServiceException(
        'Failed to get vehicle photos: ${e.toString()}',
      );
    }
  }

  /// Get photos by category for a vehicle
  static Future<List<VehiclePhoto>> getVehiclePhotosByCategory(
    String vehicleId,
    PhotoCategory category,
  ) async {
    try {
      // Query without orderBy to avoid composite index requirement
      final snapshot = await _firestore
          .collection(_photosCollection)
          .where('vehicleId', isEqualTo: vehicleId)
          .where('category', isEqualTo: category.name)
          .get();

      // Convert to VehiclePhoto objects and sort client-side
      final photos = snapshot.docs.map((doc) {
        final data = doc.data();
        return VehiclePhoto.fromMap(data);
      }).toList();

      // Sort by createdAt on client side
      photos.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      return photos;
    } catch (e) {
      throw VehiclePhotoServiceException(
        'Failed to get vehicle photos by category: ${e.toString()}',
      );
    }
  }

  /// Update photo metadata
  static Future<void> updatePhotoMetadata(VehiclePhoto photo) async {
    try {
      await _firestore
          .collection(_photosCollection)
          .doc(photo.id)
          .update(photo.toMap());
    } catch (e) {
      throw VehiclePhotoServiceException(
        'Failed to update photo metadata: ${e.toString()}',
      );
    }
  }

  /// Delete photo metadata
  static Future<void> deletePhotoMetadata(String photoId) async {
    try {
      await _firestore
          .collection(_photosCollection)
          .doc(photoId)
          .delete();
    } catch (e) {
      throw VehiclePhotoServiceException(
        'Failed to delete photo metadata: ${e.toString()}',
      );
    }
  }

  /// Delete all photos for a vehicle
  static Future<void> deleteAllVehiclePhotos(String vehicleId) async {
    try {
      final snapshot = await _firestore
          .collection(_photosCollection)
          .where('vehicleId', isEqualTo: vehicleId)
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      throw VehiclePhotoServiceException(
        'Failed to delete all vehicle photos: ${e.toString()}',
      );
    }
  }

  /// Stream of photos for a vehicle (for real-time updates)
  static Stream<List<VehiclePhoto>> streamVehiclePhotos(String vehicleId) {
    return _firestore
        .collection(_photosCollection)
        .where('vehicleId', isEqualTo: vehicleId)
        .snapshots()
        .map((snapshot) {
      // Convert to VehiclePhoto objects and sort client-side
      final photos = snapshot.docs.map((doc) {
        final data = doc.data();
        return VehiclePhoto.fromMap(data);
      }).toList();

      // Sort by createdAt on client side
      photos.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      return photos;
    });
  }

  /// Get photo count by category for a vehicle
  static Future<Map<PhotoCategory, int>> getPhotoCounts(String vehicleId) async {
    try {
      final photos = await getVehiclePhotos(vehicleId);
      final counts = <PhotoCategory, int>{};
      
      // Initialize all categories with 0
      for (final category in PhotoCategory.values) {
        counts[category] = 0;
      }
      
      // Count photos by category
      for (final photo in photos) {
        counts[photo.category] = (counts[photo.category] ?? 0) + 1;
      }
      
      return counts;
    } catch (e) {
      throw VehiclePhotoServiceException(
        'Failed to get photo counts: ${e.toString()}',
      );
    }
  }
}

class VehiclePhotoServiceException implements Exception {
  final String message;
  
  const VehiclePhotoServiceException(this.message);
  
  @override
  String toString() => 'VehiclePhotoServiceException: $message';
}
