import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import '../screens/enhanced_vehicle_photo_manager.dart';

/// Service for managing vehicle photo metadata in Firebase and photos in local storage
class VehiclePhotoService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _photosCollection = 'vehicle_photos';
  static const String _localPhotosDir = 'vehicle_photos';

  /// Save photo to local storage and metadata to Firestore
  static Future<VehiclePhoto> saveVehiclePhoto({
    required String vehicleId,
    required File photoFile,
    required PhotoCategory category,
    String? annotation,
  }) async {
    try {
      // Save photo to local storage
      final localPath = await _savePhotoToLocal(vehicleId, photoFile);
      
      // Create photo metadata
      final photoId = '${vehicleId}_${DateTime.now().millisecondsSinceEpoch}';
      final photo = VehiclePhoto(
        id: photoId,
        vehicleId: vehicleId,
        url: localPath, // Store local file path instead of Firebase URL
        category: category,
        annotation: annotation,
        createdAt: DateTime.now(),
      );
      
      // Save metadata to Firestore
      await savePhotoMetadata(photo);
      
      return photo;
    } catch (e) {
      print('❌ Failed to save vehicle photo: $e');
      throw VehiclePhotoServiceException('Failed to save vehicle photo: ${e.toString()}');
    }
  }

  /// Save photo file to local device storage
  static Future<String> _savePhotoToLocal(String vehicleId, File photoFile) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final photosDir = Directory('${appDir.path}/$_localPhotosDir/$vehicleId');
      
      // Create directory if it doesn't exist
      if (!await photosDir.exists()) {
        await photosDir.create(recursive: true);
      }
      
      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = photoFile.path.substring(photoFile.path.lastIndexOf('.'));
      final fileName = 'photo_${timestamp}$extension';
      
      // Copy file to local storage
      final localFile = File('${photosDir.path}/$fileName');
      await photoFile.copy(localFile.path);
      
      print('📱 Photo saved to local storage: ${localFile.path}');
      return localFile.path;
    } catch (e) {
      throw VehiclePhotoServiceException('Failed to save photo to local storage: ${e.toString()}');
    }
  }

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

  /// Delete photo from local storage and metadata from Firestore
  static Future<void> deleteVehiclePhoto(VehiclePhoto photo) async {
    try {
      // Delete from local storage
      await _deletePhotoFromLocal(photo.url);
      
      // Delete metadata from Firestore
      await deletePhotoMetadata(photo.id);
      
      print('🗑️ Photo deleted: ${photo.id}');
    } catch (e) {
      throw VehiclePhotoServiceException('Failed to delete photo: ${e.toString()}');
    }
  }

  /// Delete photo metadata only
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

  /// Delete photo file from local storage
  static Future<void> _deletePhotoFromLocal(String photoPath) async {
    try {
      final file = File(photoPath);
      if (await file.exists()) {
        await file.delete();
        print('📱 Local photo file deleted: $photoPath');
      }
    } catch (e) {
      print('⚠️ Failed to delete local photo file: $e');
      // Don't throw - photo might already be deleted
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
      
      // Count photos by category (only count photos that still exist locally)
      for (final photo in photos) {
        if (await _photoExistsLocally(photo.url)) {
          counts[photo.category] = (counts[photo.category] ?? 0) + 1;
        }
      }
      
      return counts;
    } catch (e) {
      throw VehiclePhotoServiceException(
        'Failed to get photo counts: ${e.toString()}',
      );
    }
  }

  /// Check if a photo file exists locally
  static Future<bool> _photoExistsLocally(String photoPath) async {
    try {
      final file = File(photoPath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  /// Clean up orphaned photo metadata (photos that no longer exist locally)
  static Future<void> cleanupOrphanedMetadata(String vehicleId) async {
    try {
      final photos = await getVehiclePhotos(vehicleId);
      final orphanedPhotos = <VehiclePhoto>[];
      
      // Check which photos no longer exist locally
      for (final photo in photos) {
        if (!await _photoExistsLocally(photo.url)) {
          orphanedPhotos.add(photo);
        }
      }
      
      // Delete orphaned metadata
      for (final photo in orphanedPhotos) {
        await deletePhotoMetadata(photo.id);
        print('🧹 Cleaned up orphaned photo metadata: ${photo.id}');
      }
      
      if (orphanedPhotos.isNotEmpty) {
        print('✅ Cleaned up ${orphanedPhotos.length} orphaned photo records');
      }
    } catch (e) {
      print('⚠️ Failed to cleanup orphaned metadata: $e');
    }
  }

  /// Get local storage info for debugging
  static Future<Map<String, dynamic>> getStorageInfo() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final photosDir = Directory('${appDir.path}/$_localPhotosDir');
      
      if (!await photosDir.exists()) {
        return {
          'localPhotosCount': 0,
          'localStorageSize': 0,
          'localStoragePath': photosDir.path,
          'exists': false,
        };
      }
      
      int photoCount = 0;
      int totalSize = 0;
      
      await for (final entity in photosDir.list(recursive: true)) {
        if (entity is File) {
          photoCount++;
          final stat = await entity.stat();
          totalSize += stat.size;
        }
      }
      
      return {
        'localPhotosCount': photoCount,
        'localStorageSize': totalSize,
        'localStoragePath': photosDir.path,
        'exists': true,
      };
    } catch (e) {
      return {
        'error': e.toString(),
      };
    }
  }
}

class VehiclePhotoServiceException implements Exception {
  final String message;
  
  const VehiclePhotoServiceException(this.message);
  
  @override
  String toString() => 'VehiclePhotoServiceException: $message';
}
