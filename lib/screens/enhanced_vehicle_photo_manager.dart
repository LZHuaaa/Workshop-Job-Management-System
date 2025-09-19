import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/app_colors.dart';
import '../models/vehicle.dart';
import '../services/photo_storage_service.dart';
import '../services/vehicle_service.dart';
import '../services/vehicle_photo_service.dart';

enum PhotoCategory {
  exterior('Exterior', Icons.directions_car, Colors.blue),
  interior('Interior', Icons.airline_seat_recline_normal, Colors.green),
  engine('Engine', Icons.settings, Colors.orange),
  damage('Damage', Icons.warning, Colors.red),
  documents('Documents', Icons.description, Colors.purple),
  other('Other', Icons.photo, Colors.grey);

  const PhotoCategory(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;
}

class VehiclePhoto {
  final String id;
  final String vehicleId;
  final String url;
  final PhotoCategory category;
  final String? annotation;
  final DateTime createdAt;

  VehiclePhoto({
    required this.id,
    required this.vehicleId,
    required this.url,
    required this.category,
    this.annotation,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vehicleId': vehicleId,
      'url': url,
      'category': category.name,
      'annotation': annotation,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory VehiclePhoto.fromMap(Map<String, dynamic> map) {
    final categoryName = map['category'] as String?;
    print('🔍 Parsing VehiclePhoto from map:');
    print('  ID: ${map['id']}');
    print('  VehicleId: ${map['vehicleId']}');
    print('  Category from map: $categoryName');

    PhotoCategory category;
    try {
      category = PhotoCategory.values.firstWhere(
        (cat) => cat.name == categoryName,
      );
      print('  ✅ Found matching category: ${category.name}');
    } catch (e) {
      print('  ⚠️ Category "$categoryName" not found, defaulting to "other"');
      category = PhotoCategory.other;
    }

    return VehiclePhoto(
      id: map['id'] ?? '',
      vehicleId: map['vehicleId'] ?? '',
      url: map['url'] ?? '',
      category: category,
      annotation: map['annotation'],
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  VehiclePhoto copyWith({
    String? id,
    String? vehicleId,
    String? url,
    PhotoCategory? category,
    String? annotation,
    DateTime? createdAt,
  }) {
    return VehiclePhoto(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      url: url ?? this.url,
      category: category ?? this.category,
      annotation: annotation ?? this.annotation,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class EnhancedVehiclePhotoManager extends StatefulWidget {
  final Vehicle vehicle;
  final Function(List<String>) onPhotosUpdated;

  const EnhancedVehiclePhotoManager({
    super.key,
    required this.vehicle,
    required this.onPhotosUpdated,
  });

  @override
  State<EnhancedVehiclePhotoManager> createState() => _EnhancedVehiclePhotoManagerState();
}

class _EnhancedVehiclePhotoManagerState extends State<EnhancedVehiclePhotoManager>
    with TickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  final VehicleService _vehicleService = VehicleService();
  
  List<VehiclePhoto> _photos = [];
  bool _isLoading = false;
  bool _isUploading = false;
  PhotoCategory _selectedCategory = PhotoCategory.exterior;
  
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: PhotoCategory.values.length, vsync: this);
    _loadPhotos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadPhotos() async {
    print('🔄 Loading photos for vehicle: ${widget.vehicle.id}');

    try {
      // Load photos with metadata from Firebase
      final photos = await VehiclePhotoService.getVehiclePhotos(widget.vehicle.id);

      print('📸 Loaded ${photos.length} photos from Firebase:');
      for (final photo in photos) {
        print('  - ID: ${photo.id}, Category: ${photo.category.name}, URL: ${photo.url.substring(0, 50)}...');
      }

      if (mounted) {
        setState(() {
          _photos = photos;
        });
      }
    } catch (e) {
      print('❌ Error loading photos from Firebase: $e');

      // Fallback: Convert existing photos to VehiclePhoto objects
      // Treat all existing photos as 'other' category if no metadata exists
      print('🔄 Falling back to vehicle.photos (${widget.vehicle.photos.length} photos)');

      if (mounted) {
        setState(() {
          _photos = widget.vehicle.photos.map((url) {
            final fallbackPhoto = VehiclePhoto(
              id: 'fallback_${DateTime.now().millisecondsSinceEpoch}',
              vehicleId: widget.vehicle.id,
              url: url,
              category: PhotoCategory.other,
              createdAt: DateTime.now(),
            );
            print('  - Fallback photo: ${fallbackPhoto.id}, Category: ${fallbackPhoto.category.name}');
            return fallbackPhoto;
          }).toList();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Vehicle Photos',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primaryPink,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primaryPink,
          labelPadding: const EdgeInsets.symmetric(horizontal: 8),
          tabAlignment: TabAlignment.start,
          tabs: PhotoCategory.values.map((category) {
            final count = _photos.where((p) => p.category == category).length;
            return Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(category.icon, size: 16),
                  const SizedBox(width: 6),
                  Text(category.label),
                  if (count > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: category.color,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        count.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: PhotoCategory.values.map((category) {
                final categoryPhotos = _photos.where((p) => p.category == category).toList();
                return _buildCategoryView(category, categoryPhotos);
              }).toList(),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isUploading ? null : () => _showAddPhotoOptions(_selectedCategory),
        backgroundColor: _isUploading 
            ? AppColors.textSecondary 
            : AppColors.primaryPink,
        icon: _isUploading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.add_a_photo, color: Colors.white),
        label: Text(
          'Add Photo',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildCategoryView(PhotoCategory category, List<VehiclePhoto> photos) {
    if (photos.isEmpty) {
      return _buildEmptyState(category);
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1,
        ),
        itemCount: photos.length,
        itemBuilder: (context, index) {
          return _buildPhotoCard(photos[index], index);
        },
      ),
    );
  }

  Widget _buildEmptyState(PhotoCategory category) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            category.icon,
            size: 80,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'No ${category.label} Photos',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add photos to document ${category.label.toLowerCase()} details',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddPhotoOptions(category),
            icon: const Icon(Icons.add_a_photo),
            label: Text('Add ${category.label} Photo'),
            style: ElevatedButton.styleFrom(
              backgroundColor: category.color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoCard(VehiclePhoto photo, int index) {
    return GestureDetector(
      onTap: () => _viewPhoto(photo, index),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Photo
              photo.url.startsWith('http')
                  ? Image.network(
                      photo.url,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppColors.backgroundLight,
                          child: Icon(
                            Icons.broken_image,
                            color: AppColors.textSecondary,
                            size: 40,
                          ),
                        );
                      },
                    )
                  : Image.file(
                      File(photo.url),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppColors.backgroundLight,
                          child: Icon(
                            Icons.broken_image,
                            color: AppColors.textSecondary,
                            size: 40,
                          ),
                        );
                      },
                    ),
              
              // Category indicator
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: photo.category.color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        photo.category.icon,
                        color: Colors.white,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        photo.category.label,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Actions menu
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.more_vert,
                      color: Colors.white,
                      size: 20,
                    ),
                    onSelected: (value) {
                      switch (value) {
                        case 'view':
                          _viewPhoto(photo, index);
                          break;
                        case 'annotate':
                          _annotatePhoto(photo);
                          break;
                        case 'delete':
                          _deletePhoto(photo);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'view',
                        child: Row(
                          children: [
                            const Icon(Icons.visibility, size: 18),
                            const SizedBox(width: 8),
                            Text('View', style: GoogleFonts.poppins()),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'annotate',
                        child: Row(
                          children: [
                            const Icon(Icons.edit_note, size: 18),
                            const SizedBox(width: 8),
                            Text('Annotate', style: GoogleFonts.poppins()),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(Icons.delete, size: 18, color: Colors.red),
                            const SizedBox(width: 8),
                            Text(
                              'Delete',
                              style: GoogleFonts.poppins(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Annotation indicator
              if (photo.annotation != null && photo.annotation!.isNotEmpty)
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.note,
                          color: Colors.white,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Note',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddPhotoOptions(PhotoCategory category) {
    setState(() {
      _selectedCategory = category;
    });
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Add ${category.label} Photo',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Icon(
                  Icons.camera_alt,
                  color: category.color,
                ),
                title: Text(
                  'Take Photo',
                  style: GoogleFonts.poppins(),
                ),
                subtitle: Text(
                  'Use camera to take a new photo',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _takePhoto(category);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.photo_library,
                  color: category.color,
                ),
                title: Text(
                  'Choose from Gallery',
                  style: GoogleFonts.poppins(),
                ),
                subtitle: Text(
                  'Select from existing photos',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromGallery(category);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _takePhoto(PhotoCategory category) async {
    final status = await Permission.camera.request();
    if (status.isDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Camera permission is required to take photos',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
      return;
    }

    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (photo != null) {
        await _uploadPhotoToStorage(File(photo.path), category);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to take photo: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _pickFromGallery(PhotoCategory category) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (photo != null) {
        await _uploadPhotoToStorage(File(photo.path), category);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to pick photo: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  // Upload photo to storage and update vehicle
  Future<void> _uploadPhotoToStorage(File photoFile, PhotoCategory category) async {
    if (_isUploading) return;
    
    setState(() {
      _isUploading = true;
    });

    try {
      // Show uploading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 16),
                Text(
                  'Uploading ${category.label.toLowerCase()} photo...',
                  style: GoogleFonts.poppins(),
                ),
              ],
            ),
            backgroundColor: category.color,
            duration: const Duration(seconds: 30),
          ),
        );
      }

      // Save photo to local storage and metadata to Firestore
      final vehiclePhoto = await VehiclePhotoService.saveVehiclePhoto(
        vehicleId: widget.vehicle.id,
        photoFile: photoFile,
        category: category,
        annotation: null, // Can add annotation support later if needed
      );

      print('📸 Photo saved successfully: ID=${vehiclePhoto.id}, Category=${vehiclePhoto.category.name}, VehicleId=${vehiclePhoto.vehicleId}');
      print('📱 Local path: ${vehiclePhoto.url}');

      print('✅ Photo metadata saved successfully');

      // Verify the save by reading it back
      try {
        final savedPhotos = await VehiclePhotoService.getVehiclePhotos(widget.vehicle.id);
        final savedPhoto = savedPhotos.firstWhere((p) => p.id == vehiclePhoto.id);
        print('🔍 Verification - Saved photo category: ${savedPhoto.category.name}');
      } catch (e) {
        print('⚠️ Could not verify saved photo: $e');
      }

      // Update vehicle photos in Firestore (for backward compatibility)
      await _vehicleService.addPhotoToVehicle(widget.vehicle.id, vehiclePhoto.url);

      // Update local state
      setState(() {
        _photos.add(vehiclePhoto);
      });

      print('🔄 Local state updated, total photos: ${_photos.length}');

      // Update parent widget
      final photoUrls = _photos.map((p) => p.url).toList();
      widget.onPhotosUpdated(photoUrls);

      // Switch to the category tab
      final categoryIndex = PhotoCategory.values.indexOf(category);
      _tabController.animateTo(categoryIndex);

      // Hide uploading indicator and show success
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${category.label} photo uploaded successfully',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to upload photo: ${e.toString()}',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _viewPhoto(VehiclePhoto photo, int index) {
    // TODO: Implement enhanced photo viewer with zoom, swipe, etc.
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PhotoViewScreen(
          photo: photo,
          allPhotos: _photos,
          initialIndex: index,
        ),
      ),
    );
  }

  void _annotatePhoto(VehiclePhoto photo) {
    showDialog(
      context: context,
      builder: (context) => AnnotationDialog(
        photo: photo,
        onAnnotationSaved: (annotation) async {
          try {
            final updatedPhoto = photo.copyWith(annotation: annotation);

            // Save updated metadata to Firebase
            await VehiclePhotoService.updatePhotoMetadata(updatedPhoto);

            setState(() {
              final index = _photos.indexWhere((p) => p.id == photo.id);
              if (index != -1) {
                _photos[index] = updatedPhoto;
              }
            });
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Failed to save annotation: $e',
                    style: GoogleFonts.poppins(),
                  ),
                  backgroundColor: AppColors.errorRed,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _deletePhoto(VehiclePhoto photo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Photo',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to delete this ${photo.category.label.toLowerCase()} photo? This action cannot be undone.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deletePhotoFromStorage(photo);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(),
            ),
          ),
        ],
      ),
    );
  }

  // Delete photo from storage and update vehicle
  Future<void> _deletePhotoFromStorage(VehiclePhoto photo) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Delete photo from local storage and metadata from Firebase
      await VehiclePhotoService.deleteVehiclePhoto(photo);

      // Update vehicle photos in Firestore (for backward compatibility)
      await _vehicleService.removePhotoFromVehicle(widget.vehicle.id, photo.url);

      // Update local state
      setState(() {
        _photos.removeWhere((p) => p.id == photo.id);
      });

      // Update parent widget
      final photoUrls = _photos.map((p) => p.url).toList();
      widget.onPhotosUpdated(photoUrls);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Photo deleted successfully',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to delete photo: ${e.toString()}',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

// Placeholder classes - to be implemented
class PhotoViewScreen extends StatelessWidget {
  final VehiclePhoto photo;
  final List<VehiclePhoto> allPhotos;
  final int initialIndex;

  const PhotoViewScreen({
    super.key,
    required this.photo,
    required this.allPhotos,
    required this.initialIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          '${photo.category.label} Photo',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: InteractiveViewer(
          child: photo.url.startsWith('http')
              ? Image.network(photo.url, fit: BoxFit.contain)
              : Image.file(File(photo.url), fit: BoxFit.contain),
        ),
      ),
    );
  }
}

class AnnotationDialog extends StatefulWidget {
  final VehiclePhoto photo;
  final Function(String) onAnnotationSaved;

  const AnnotationDialog({
    super.key,
    required this.photo,
    required this.onAnnotationSaved,
  });

  @override
  State<AnnotationDialog> createState() => _AnnotationDialogState();
}

class _AnnotationDialogState extends State<AnnotationDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.photo.annotation ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Add Note',
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
      content: TextField(
        controller: _controller,
        maxLines: 3,
        decoration: const InputDecoration(
          hintText: 'Add a note about this photo...',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: GoogleFonts.poppins(color: AppColors.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onAnnotationSaved(_controller.text);
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryPink,
            foregroundColor: Colors.white,
          ),
          child: Text(
            'Save',
            style: GoogleFonts.poppins(),
          ),
        ),
      ],
    );
  }
}
