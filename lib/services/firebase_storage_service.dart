import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseStorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  
  // Upload vehicle photo to Firebase Storage
  static Future<String> uploadVehiclePhoto({
    required String vehicleId,
    required File photoFile,
  }) async {
    try {
      // Ensure user is authenticated
      await _ensureAuthenticated();
      // Generate unique filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = photoFile.path;
      final extension = filePath.substring(filePath.lastIndexOf('.'));
      final fileName = 'photo_${timestamp}$extension';
      
      // Create reference to Firebase Storage location
      final ref = _storage
          .ref()
          .child('vehicles')
          .child(vehicleId)
          .child('photos')
          .child(fileName);
      
      // Upload file with metadata
      final uploadTask = ref.putFile(
        photoFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'vehicleId': vehicleId,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );
      
      // Wait for upload to complete
      final snapshot = await uploadTask;
      
      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      throw FirebaseStorageException(
        'Failed to upload photo: ${e.toString()}',
      );
    }
  }
  
  // Delete vehicle photo from Firebase Storage
  static Future<void> deleteVehiclePhoto(String photoUrl) async {
    try {
      // Extract the storage reference from the URL
      final ref = _storage.refFromURL(photoUrl);
      await ref.delete();
    } catch (e) {
      throw FirebaseStorageException(
        'Failed to delete photo: ${e.toString()}',
      );
    }
  }
  
  // Get all photos for a vehicle (if needed for debugging)
  static Future<List<String>> getVehiclePhotos(String vehicleId) async {
    try {
      final ref = _storage
          .ref()
          .child('vehicles')
          .child(vehicleId)
          .child('photos');
      
      final result = await ref.listAll();
      final urls = <String>[];
      
      for (final item in result.items) {
        final url = await item.getDownloadURL();
        urls.add(url);
      }
      
      return urls;
    } catch (e) {
      throw FirebaseStorageException(
        'Failed to get vehicle photos: ${e.toString()}',
      );
    }
  }
  
  // Delete all photos for a vehicle (useful when deleting a vehicle)
  static Future<void> deleteAllVehiclePhotos(String vehicleId) async {
    try {
      final ref = _storage
          .ref()
          .child('vehicles')
          .child(vehicleId)
          .child('photos');
      
      final result = await ref.listAll();
      
      // Delete all photos
      for (final item in result.items) {
        await item.delete();
      }
    } catch (e) {
      throw FirebaseStorageException(
        'Failed to delete all vehicle photos: ${e.toString()}',
      );
    }
  }
  
  // Get storage usage for a vehicle (optional utility)
  static Future<int> getVehicleStorageUsage(String vehicleId) async {
    try {
      final ref = _storage
          .ref()
          .child('vehicles')
          .child(vehicleId)
          .child('photos');
      
      final result = await ref.listAll();
      int totalSize = 0;
      
      for (final item in result.items) {
        final metadata = await item.getMetadata();
        totalSize += metadata.size ?? 0;
      }
      
      return totalSize;
    } catch (e) {
      throw FirebaseStorageException(
        'Failed to get storage usage: ${e.toString()}',
      );
    }
  }

  /// Ensure user is authenticated for Firebase Storage access
  static Future<void> _ensureAuthenticated() async {
    final auth = FirebaseAuth.instance;

    if (auth.currentUser == null) {
      try {
        await auth.signInAnonymously();
      } catch (e) {
        throw FirebaseStorageException(
          'Authentication failed: ${e.toString()}',
        );
      }
    }
  }
}

class FirebaseStorageException implements Exception {
  final String message;

  const FirebaseStorageException(this.message);

  @override
  String toString() => 'FirebaseStorageException: $message';
}
