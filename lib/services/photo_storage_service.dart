import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'firebase_storage_service.dart';

/// Service that handles photo storage with Firebase fallback to local storage
class PhotoStorageService {
  static const String _localPhotosDir = 'vehicle_photos';
  
  /// Upload photo with Firebase Storage as primary, local storage as fallback
  static Future<String> uploadVehiclePhoto({
    required String vehicleId,
    required File photoFile,
  }) async {
    try {
      // Try Firebase Storage first
      final firebaseUrl = await FirebaseStorageService.uploadVehiclePhoto(
        vehicleId: vehicleId,
        photoFile: photoFile,
      );
      return firebaseUrl;
    } catch (e) {
      print('Firebase Storage failed, using local storage: $e');
      
      // Fallback to local storage
      return await _savePhotoLocally(vehicleId, photoFile);
    }
  }
  
  /// Delete photo from both Firebase and local storage
  static Future<void> deleteVehiclePhoto(String photoUrl) async {
    try {
      if (photoUrl.startsWith('http')) {
        // It's a Firebase URL
        await FirebaseStorageService.deleteVehiclePhoto(photoUrl);
      } else {
        // It's a local file path
        await _deleteLocalPhoto(photoUrl);
      }
    } catch (e) {
      print('Failed to delete photo: $e');
      // Don't throw - photo might already be deleted
    }
  }
  
  /// Save photo to local storage
  static Future<String> _savePhotoLocally(String vehicleId, File photoFile) async {
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
      
      return localFile.path;
    } catch (e) {
      throw PhotoStorageException('Failed to save photo locally: ${e.toString()}');
    }
  }
  
  /// Delete photo from local storage
  static Future<void> _deleteLocalPhoto(String photoPath) async {
    try {
      final file = File(photoPath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw PhotoStorageException('Failed to delete local photo: ${e.toString()}');
    }
  }
  
  /// Get all local photos for a vehicle (for debugging/migration)
  static Future<List<String>> getLocalVehiclePhotos(String vehicleId) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final photosDir = Directory('${appDir.path}/$_localPhotosDir/$vehicleId');
      
      if (!await photosDir.exists()) {
        return [];
      }
      
      final files = await photosDir.list().toList();
      return files
          .where((entity) => entity is File)
          .map((file) => file.path)
          .toList();
    } catch (e) {
      print('Failed to get local photos: $e');
      return [];
    }
  }
  
  /// Clean up old local photos (optional maintenance)
  static Future<void> cleanupOldLocalPhotos({int daysOld = 30}) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final photosDir = Directory('${appDir.path}/$_localPhotosDir');
      
      if (!await photosDir.exists()) {
        return;
      }
      
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
      
      await for (final entity in photosDir.list(recursive: true)) {
        if (entity is File) {
          final stat = await entity.stat();
          if (stat.modified.isBefore(cutoffDate)) {
            await entity.delete();
            print('Deleted old photo: ${entity.path}');
          }
        }
      }
    } catch (e) {
      print('Failed to cleanup old photos: $e');
    }
  }
  
  /// Check if a photo URL is local or remote
  static bool isLocalPhoto(String photoUrl) {
    return !photoUrl.startsWith('http');
  }
  
  /// Get storage info for debugging
  static Future<Map<String, dynamic>> getStorageInfo() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final photosDir = Directory('${appDir.path}/$_localPhotosDir');
      
      if (!await photosDir.exists()) {
        return {
          'localPhotosCount': 0,
          'localStorageSize': 0,
          'localStoragePath': photosDir.path,
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
      };
    } catch (e) {
      return {
        'error': e.toString(),
      };
    }
  }
}

class PhotoStorageException implements Exception {
  final String message;
  
  const PhotoStorageException(this.message);
  
  @override
  String toString() => 'PhotoStorageException: $message';
}
