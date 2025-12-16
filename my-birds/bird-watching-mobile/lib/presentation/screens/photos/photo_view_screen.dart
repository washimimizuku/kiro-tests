import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import '../../../data/models/observation.dart';
import '../../../data/services/cache_manager_service.dart';
import 'package:intl/intl.dart';

/// Screen for viewing photos in full screen with pinch-to-zoom
/// Requirements: 12.1, 12.2, 12.3
class PhotoViewScreen extends StatefulWidget {
  final String? photoUrl;
  final String? localPhotoPath;
  final Observation? observation;

  const PhotoViewScreen({
    super.key,
    this.photoUrl,
    this.localPhotoPath,
    this.observation,
  }) : assert(
          photoUrl != null || localPhotoPath != null,
          'Either photoUrl or localPhotoPath must be provided',
        );

  @override
  State<PhotoViewScreen> createState() => _PhotoViewScreenState();
}

class _PhotoViewScreenState extends State<PhotoViewScreen> {
  bool _showOverlay = true;
  final PhotoViewController _photoViewController = PhotoViewController();

  @override
  void dispose() {
    _photoViewController.dispose();
    super.dispose();
  }

  void _toggleOverlay() {
    setState(() {
      _showOverlay = !_showOverlay;
    });
  }

  Future<void> _sharePhoto() async {
    try {
      if (widget.localPhotoPath != null) {
        // Share local file
        await Share.shareXFiles(
          [XFile(widget.localPhotoPath!)],
          text: widget.observation != null
              ? 'Bird observation: ${widget.observation!.speciesName}'
              : 'Bird observation photo',
        );
      } else if (widget.photoUrl != null) {
        // Share URL
        await Share.share(
          widget.photoUrl!,
          subject: widget.observation != null
              ? 'Bird observation: ${widget.observation!.speciesName}'
              : 'Bird observation photo',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildPhotoView() {
    // Display local photo if available
    if (widget.localPhotoPath != null) {
      return PhotoView(
        imageProvider: FileImage(File(widget.localPhotoPath!)),
        controller: _photoViewController,
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 3,
        backgroundDecoration: const BoxDecoration(
          color: Colors.black,
        ),
        onTapUp: (context, details, controllerValue) {
          _toggleOverlay();
        },
        loadingBuilder: (context, event) {
          return Center(
            child: CircularProgressIndicator(
              value: event == null
                  ? null
                  : event.cumulativeBytesLoaded / (event.expectedTotalBytes ?? 1),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.white,
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  'Failed to load photo',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          );
        },
      );
    }

    // Display network photo with caching
    if (widget.photoUrl != null) {
      return PhotoView(
        imageProvider: CachedNetworkImageProvider(
          widget.photoUrl!,
          cacheManager: PhotoCacheManager.instance,
        ),
        controller: _photoViewController,
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 3,
        backgroundDecoration: const BoxDecoration(
          color: Colors.black,
        ),
        onTapUp: (context, details, controllerValue) {
          _toggleOverlay();
        },
        loadingBuilder: (context, event) {
          return Center(
            child: CircularProgressIndicator(
              value: event == null
                  ? null
                  : event.cumulativeBytesLoaded / (event.expectedTotalBytes ?? 1),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.broken_image,
                  color: Colors.white,
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  'Failed to load photo',
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  'Check your internet connection',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          );
        },
      );
    }

    // Fallback (should never reach here due to assertion)
    return const Center(
      child: Text(
        'No photo available',
        style: TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _buildObservationOverlay() {
    if (widget.observation == null) {
      return const SizedBox.shrink();
    }

    final observation = widget.observation!;
    final dateFormat = DateFormat('MMM d, yyyy');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.7),
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            observation.speciesName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.calendar_today,
                color: Colors.white70,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                dateFormat.format(observation.observationDate),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.location_on,
                color: Colors.white70,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  observation.location,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (observation.notes != null && observation.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              observation.notes!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: _showOverlay
          ? AppBar(
              backgroundColor: Colors.black.withOpacity(0.5),
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.share, color: Colors.white),
                  onPressed: _sharePhoto,
                  tooltip: 'Share photo',
                ),
              ],
            )
          : null,
      body: Stack(
        children: [
          // Photo viewer with pinch-to-zoom
          _buildPhotoView(),

          // Observation details overlay at bottom
          if (_showOverlay && widget.observation != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                child: _buildObservationOverlay(),
              ),
            ),
        ],
      ),
    );
  }
}
