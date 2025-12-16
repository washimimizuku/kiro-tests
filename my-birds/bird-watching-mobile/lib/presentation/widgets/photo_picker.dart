import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/utils/accessibility_utils.dart';

/// Widget for picking photos from camera or gallery
/// Shows preview and handles compression
class PhotoPicker extends StatefulWidget {
  final File? initialPhoto;
  final Function(File?) onPhotoSelected;
  final bool enabled;

  const PhotoPicker({
    super.key,
    this.initialPhoto,
    required this.onPhotoSelected,
    this.enabled = true,
  });

  @override
  State<PhotoPicker> createState() => _PhotoPickerState();
}

class _PhotoPickerState extends State<PhotoPicker> {
  File? _selectedPhoto;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedPhoto = widget.initialPhoto;
  }

  Future<void> _pickFromCamera() async {
    if (!widget.enabled) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        final file = File(image.path);
        setState(() {
          _selectedPhoto = file;
        });
        widget.onPhotoSelected(file);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error taking photo: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickFromGallery() async {
    if (!widget.enabled) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        final file = File(image.path);
        setState(() {
          _selectedPhoto = file;
        });
        widget.onPhotoSelected(file);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking photo: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _removePhoto() {
    setState(() {
      _selectedPhoto = null;
    });
    widget.onPhotoSelected(null);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Photo',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        
        if (_selectedPhoto != null)
          _buildPhotoPreview()
        else
          _buildPhotoButtons(),
      ],
    );
  }

  Widget _buildPhotoPreview() {
    return Column(
      children: [
        Semantics(
          label: 'Selected photo preview',
          image: true,
          child: Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.file(
              _selectedPhoto!,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Semantics(
                label: AccessibilityUtils.photoButtonLabel(
                  hasPhoto: true,
                  isCamera: true,
                ),
                button: true,
                enabled: widget.enabled,
                child: OutlinedButton.icon(
                  onPressed: widget.enabled ? _pickFromCamera : null,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Retake'),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Semantics(
                label: AccessibilityUtils.photoButtonLabel(
                  hasPhoto: true,
                  isCamera: false,
                ),
                button: true,
                enabled: widget.enabled,
                child: OutlinedButton.icon(
                  onPressed: widget.enabled ? _removePhoto : null,
                  icon: const Icon(Icons.delete),
                  label: const Text('Remove'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPhotoButtons() {
    if (_isLoading) {
      return Semantics(
        label: 'Loading photo',
        liveRegion: true,
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: Semantics(
            label: AccessibilityUtils.photoButtonLabel(
              hasPhoto: false,
              isCamera: true,
            ),
            button: true,
            enabled: widget.enabled,
            child: OutlinedButton.icon(
              onPressed: widget.enabled ? _pickFromCamera : null,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Take Photo'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Semantics(
            label: AccessibilityUtils.photoButtonLabel(
              hasPhoto: false,
              isCamera: false,
            ),
            button: true,
            enabled: widget.enabled,
            child: OutlinedButton.icon(
              onPressed: widget.enabled ? _pickFromGallery : null,
              icon: const Icon(Icons.photo_library),
              label: const Text('Choose from Gallery'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
