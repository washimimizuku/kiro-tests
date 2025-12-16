import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/services/cache_manager_service.dart';

/// Widget that lazy-loads images with placeholder and error handling
/// Optimized for list views with automatic memory management
class LazyImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final bool useThumbnail;

  const LazyImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.useThumbnail = false,
  });

  @override
  Widget build(BuildContext context) {
    // Return placeholder if no URL provided
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildPlaceholder();
    }

    // Use thumbnail URL if available and requested
    final effectiveUrl = useThumbnail ? _getThumbnailUrl(imageUrl!) : imageUrl!;

    return CachedNetworkImage(
      imageUrl: effectiveUrl,
      width: width,
      height: height,
      fit: fit,
      cacheManager: PhotoCacheManager.instance,
      
      // Placeholder while loading
      placeholder: (context, url) {
        return placeholder ?? _buildLoadingPlaceholder();
      },
      
      // Error widget if loading fails
      errorWidget: (context, url, error) {
        return errorWidget ?? _buildErrorWidget();
      },
      
      // Memory cache configuration
      memCacheWidth: useThumbnail ? 400 : null,
      memCacheHeight: useThumbnail ? 400 : null,
      
      // Fade in animation
      fadeInDuration: const Duration(milliseconds: 300),
      fadeOutDuration: const Duration(milliseconds: 100),
    );
  }

  /// Build default placeholder widget
  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: Icon(
        Icons.photo_camera,
        size: 40,
        color: Colors.grey[400],
      ),
    );
  }

  /// Build loading placeholder with progress indicator
  Widget _buildLoadingPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
        ),
      ),
    );
  }

  /// Build error widget
  Widget _buildErrorWidget() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image,
            size: 40,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 8),
          Text(
            'Failed to load',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  /// Get thumbnail URL by modifying the original URL
  /// This assumes the backend provides thumbnail endpoints
  String _getThumbnailUrl(String url) {
    // If the URL already has a thumbnail parameter, return as is
    if (url.contains('thumbnail=true') || url.contains('size=thumb')) {
      return url;
    }

    // Add thumbnail parameter to URL
    final uri = Uri.parse(url);
    final queryParams = Map<String, dynamic>.from(uri.queryParameters);
    queryParams['thumbnail'] = 'true';
    queryParams['width'] = '400';
    queryParams['height'] = '400';

    return uri.replace(queryParameters: queryParams).toString();
  }
}

/// Optimized image widget for list items
/// Uses smaller memory cache and thumbnail URLs
class ListItemImage extends StatelessWidget {
  final String? imageUrl;
  final double size;

  const ListItemImage({
    super.key,
    required this.imageUrl,
    this.size = 100,
  });

  @override
  Widget build(BuildContext context) {
    return LazyImage(
      imageUrl: imageUrl,
      width: size,
      height: size,
      useThumbnail: true,
      fit: BoxFit.cover,
    );
  }
}

/// Full-size image widget for detail views
/// Uses full resolution and larger memory cache
class DetailImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;

  const DetailImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return LazyImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      useThumbnail: false,
      fit: BoxFit.contain,
    );
  }
}
