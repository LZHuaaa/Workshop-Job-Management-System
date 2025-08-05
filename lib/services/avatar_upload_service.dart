import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'user_profile_service.dart';

class AvatarUploadService {
  static final AvatarUploadService _instance = AvatarUploadService._internal();
  factory AvatarUploadService() => _instance;
  AvatarUploadService._internal();

  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();
  final UserProfileService _profileService = UserProfileService();

  // Maximum file size (5MB)
  static const int maxFileSizeBytes = 5 * 1024 * 1024;
  
  // Maximum image dimensions
  static const int maxImageSize = 512;

  // Pick and upload avatar image
  Future<AvatarUploadResult> pickAndUploadAvatar({
    required ImageSource source,
  }) async {
    try {
      print('🖼️ Starting avatar upload process...');

      // Pick image with built-in compression
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: maxImageSize.toDouble(),
        maxHeight: maxImageSize.toDouble(),
        imageQuality: 70, // Reduced quality for better compression
      );

      if (pickedFile == null) {
        print('📷 Image selection cancelled by user');
        return AvatarUploadResult.cancelled('Image selection cancelled');
      }

      print('📷 Image selected: ${pickedFile.name}, path: ${pickedFile.path}');

      // Read image bytes directly (ImagePicker already handles compression)
      final Uint8List imageBytes = await pickedFile.readAsBytes();
      print('📏 Image size: ${imageBytes.length} bytes');

      // Validate file size after compression
      if (imageBytes.length > maxFileSizeBytes) {
        print('❌ Image too large: ${imageBytes.length} > $maxFileSizeBytes');
        return AvatarUploadResult.failure(
          'Image file is too large. Please select a smaller image.',
        );
      }

      print('☁️ Starting upload to Firebase Storage...');
      // Upload to Firebase Storage directly
      final String? downloadUrl = await _uploadToStorage(imageBytes);

      if (downloadUrl == null) {
        print('❌ Failed to upload to Firebase Storage');
        return AvatarUploadResult.failure('Failed to upload image to storage');
      }

      print('✅ Upload successful, URL: $downloadUrl');
      print('👤 Updating user profile with new photo URL...');

      // Update user profile
      final updateResult = await _profileService.updateProfilePhoto(downloadUrl);

      if (!updateResult.isSuccess) {
        print('❌ Failed to update profile: ${updateResult.message}');
        // Clean up uploaded file if profile update fails
        await _deleteFromStorage(downloadUrl);
        return AvatarUploadResult.failure(updateResult.message);
      }

      print('🎉 Avatar upload completed successfully!');
      return AvatarUploadResult.success(
        'Profile photo updated successfully',
        downloadUrl,
      );
    } catch (e) {
      print('💥 Avatar upload error: $e');
      return AvatarUploadResult.failure('Failed to upload avatar: ${e.toString()}');
    }
  }

  // Remove current avatar
  Future<AvatarUploadResult> removeAvatar() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return AvatarUploadResult.failure('No user is currently signed in');
      }

      final currentPhotoUrl = user.photoURL;

      // Update profile to remove photo URL
      final updateResult = await _profileService.updateProfilePhoto('');

      if (!updateResult.isSuccess) {
        return AvatarUploadResult.failure(updateResult.message);
      }

      // Delete old image from storage if it exists
      if (currentPhotoUrl != null && currentPhotoUrl.isNotEmpty) {
        await _deleteFromStorage(currentPhotoUrl);
      }

      return AvatarUploadResult.success('Profile photo removed successfully', null);
    } catch (e) {
      return AvatarUploadResult.failure('Failed to remove avatar: ${e.toString()}');
    }
  }



  // Upload image to Firebase Storage
  Future<String?> _uploadToStorage(Uint8List imageBytes) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('Upload failed: No authenticated user');
        return null;
      }

      // Create unique filename
      final String fileName = 'avatar_${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference ref = _storage.ref().child('user_avatars').child(fileName);

      print('Uploading avatar to: ${ref.fullPath}');

      // Upload file with progress tracking
      final UploadTask uploadTask = ref.putData(
        imageBytes,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'userId': user.uid,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      // Wait for upload completion
      final TaskSnapshot snapshot = await uploadTask;

      if (snapshot.state == TaskState.success) {
        final downloadUrl = await snapshot.ref.getDownloadURL();
        print('Upload successful: $downloadUrl');
        return downloadUrl;
      } else {
        print('Upload failed with state: ${snapshot.state}');
        return null;
      }
    } on FirebaseException catch (e) {
      print('Firebase upload error: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      print('Unexpected upload error: $e');
      return null;
    }
  }

  // Delete image from Firebase Storage
  Future<void> _deleteFromStorage(String downloadUrl) async {
    try {
      if (downloadUrl.isEmpty || !downloadUrl.contains('firebase')) return;
      
      final Reference ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
    } catch (e) {
      print('Error deleting from storage: $e');
      // Don't throw error as this is cleanup operation
    }
  }

  // Show image source selection dialog
  Future<ImageSource?> showImageSourceDialog(BuildContext context) async {
    return showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Select Image Source',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: Text('Camera', style: GoogleFonts.poppins()),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text('Gallery', style: GoogleFonts.poppins()),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: GoogleFonts.poppins()),
            ),
          ],
        );
      },
    );
  }
}

class AvatarUploadResult {
  final bool isSuccess;
  final bool isCancelled;
  final String message;
  final String? downloadUrl;

  AvatarUploadResult._({
    required this.isSuccess,
    required this.isCancelled,
    required this.message,
    this.downloadUrl,
  });

  factory AvatarUploadResult.success(String message, String? downloadUrl) {
    return AvatarUploadResult._(
      isSuccess: true,
      isCancelled: false,
      message: message,
      downloadUrl: downloadUrl,
    );
  }

  factory AvatarUploadResult.failure(String message) {
    return AvatarUploadResult._(
      isSuccess: false,
      isCancelled: false,
      message: message,
    );
  }

  factory AvatarUploadResult.cancelled(String message) {
    return AvatarUploadResult._(
      isSuccess: false,
      isCancelled: true,
      message: message,
    );
  }
}
