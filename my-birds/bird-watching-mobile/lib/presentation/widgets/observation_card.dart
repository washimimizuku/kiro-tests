import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../data/models/observation.dart';
import '../../data/services/cache_manager_service.dart';
import '../../core/utils/accessibility_utils.dart';

/// Card widget displaying observation summary
/// Shows thumbnail, species name, date, location, and sync status
class ObservationCard extends StatelessWidget {
  final Observation observation;
  final VoidCallback? onTap;
  final bool showOwner;

  const ObservationCard({
    super.key,
    required this.observation,
    this.onTap,
    this.showOwner = false,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final formattedDate = dateFormat.format(observation.observationDate);
    
    // Generate accessibility label
    final semanticLabel = AccessibilityUtils.observationCardLabel(
      speciesName: observation.speciesName,
      date: formattedDate,
      location: observation.location,
      hasPendingSync: observation.pendingSync,
      hasPhoto: observation.photoUrl != null || observation.localPhotoPath != null,
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      child: Semantics(
        label: semanticLabel,
        hint: AccessibilityUtils.actionHint('view observation details'),
        button: true,
        enabled: onTap != null,
        child: InkWell(
          onTap: onTap,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Thumbnail
            _buildThumbnail(),
            
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Species name
                    Text(
                      observation.speciesName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    
                    // Date
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          formattedDate,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    
                    // Location
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            observation.location,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    
                    // Owner (for shared observations)
                    if (showOwner) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.person, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            observation.userId,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                    
                    // Sync status indicator
                    if (observation.pendingSync) ...[
                      const SizedBox(height: 8),
                      _buildSyncStatusChip(),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build thumbnail image widget
  Widget _buildThumbnail() {
    const double thumbnailSize = 100;
    
    final imageLabel = AccessibilityUtils.imageLabel(
      speciesName: observation.speciesName,
      additionalInfo: 'thumbnail',
    );

    // Show local photo if available
    if (observation.localPhotoPath != null) {
      return Semantics(
        label: imageLabel,
        image: true,
        child: Container(
          width: thumbnailSize,
          height: thumbnailSize,
          color: Colors.grey[200],
          child: Image.asset(
            observation.localPhotoPath!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildPlaceholder();
            },
          ),
        ),
      );
    }

    // Show remote photo if available
    if (observation.photoUrl != null && observation.photoUrl!.isNotEmpty) {
      return Semantics(
        label: imageLabel,
        image: true,
        child: SizedBox(
          width: thumbnailSize,
          height: thumbnailSize,
          child: CachedNetworkImage(
            imageUrl: observation.photoUrl!,
            fit: BoxFit.cover,
            cacheManager: PhotoCacheManager.instance,
            placeholder: (context, url) => Container(
              color: Colors.grey[200],
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            errorWidget: (context, url, error) => _buildPlaceholder(),
          ),
        ),
      );
    }

    // Show placeholder if no photo
    return _buildPlaceholder();
  }

  /// Build placeholder for missing photos
  Widget _buildPlaceholder() {
    return Semantics(
      label: 'No photo available for ${observation.speciesName}',
      child: Container(
        width: 100,
        height: 100,
        color: Colors.grey[200],
        child: Icon(
          Icons.photo_camera,
          size: 40,
          color: Colors.grey[400],
        ),
      ),
    );
  }

  /// Build sync status chip
  Widget _buildSyncStatusChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.sync,
            size: 14,
            color: Colors.orange[800],
          ),
          const SizedBox(width: 4),
          Text(
            'Pending sync',
            style: TextStyle(
              fontSize: 12,
              color: Colors.orange[800],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
