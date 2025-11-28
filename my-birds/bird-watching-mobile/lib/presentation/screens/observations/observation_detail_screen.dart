import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../data/models/observation.dart';
import '../../blocs/observation/observation_bloc.dart';
import '../../blocs/observation/observation_event.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import 'observation_form_screen.dart';

/// Screen displaying full observation details
/// Shows photo, map, and all observation information
class ObservationDetailScreen extends StatefulWidget {
  final Observation observation;

  const ObservationDetailScreen({
    super.key,
    required this.observation,
  });

  @override
  State<ObservationDetailScreen> createState() => _ObservationDetailScreenState();
}

class _ObservationDetailScreenState extends State<ObservationDetailScreen> {
  GoogleMapController? _mapController;
  bool _isOwner = false;

  @override
  void initState() {
    super.initState();
    _checkOwnership();
  }

  void _checkOwnership() {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      setState(() {
        _isOwner = authState.user.id == widget.observation.userId;
      });
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void _onEditPressed() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ObservationFormScreen(
          observation: widget.observation,
        ),
      ),
    );
  }

  void _onDeletePressed() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Observation'),
        content: const Text('Are you sure you want to delete this observation? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      context.read<ObservationBloc>().add(DeleteObservation(widget.observation.id));
      Navigator.of(context).pop(); // Return to previous screen
    }
  }

  void _onSharePressed() {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share observation - coming soon'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');
    final formattedDate = dateFormat.format(widget.observation.observationDate);
    final formattedTime = timeFormat.format(widget.observation.observationDate);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.observation.speciesName),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _onSharePressed,
            tooltip: 'Share',
          ),
          if (_isOwner) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _onEditPressed,
              tooltip: 'Edit',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _onDeletePressed,
              tooltip: 'Delete',
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo
            _buildPhotoSection(),

            // Details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Species name
                  Text(
                    widget.observation.speciesName,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),

                  // Date and time
                  _buildInfoRow(
                    icon: Icons.calendar_today,
                    label: 'Date',
                    value: formattedDate,
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    icon: Icons.access_time,
                    label: 'Time',
                    value: formattedTime,
                  ),
                  const SizedBox(height: 16),

                  // Location
                  _buildInfoRow(
                    icon: Icons.location_on,
                    label: 'Location',
                    value: widget.observation.location,
                  ),
                  
                  // Coordinates
                  if (widget.observation.latitude != null && widget.observation.longitude != null) ...[
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      icon: Icons.my_location,
                      label: 'Coordinates',
                      value: _formatCoordinates(
                        widget.observation.latitude!,
                        widget.observation.longitude!,
                      ),
                    ),
                  ],

                  // Notes
                  if (widget.observation.notes != null && widget.observation.notes!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Notes',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.observation.notes!,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],

                  // Sync status
                  if (widget.observation.pendingSync) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange[300]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.sync, color: Colors.orange[800]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'This observation is pending sync. It will be uploaded when you have an internet connection.',
                              style: TextStyle(color: Colors.orange[800]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Map
                  if (widget.observation.latitude != null && widget.observation.longitude != null) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Location on Map',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    _buildMapSection(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoSection() {
    // Show local photo if available
    if (widget.observation.localPhotoPath != null) {
      return Container(
        width: double.infinity,
        height: 300,
        color: Colors.grey[200],
        child: Image.asset(
          widget.observation.localPhotoPath!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildPhotoPlaceholder();
          },
        ),
      );
    }

    // Show remote photo if available
    if (widget.observation.photoUrl != null && widget.observation.photoUrl!.isNotEmpty) {
      return SizedBox(
        width: double.infinity,
        height: 300,
        child: CachedNetworkImage(
          imageUrl: widget.observation.photoUrl!,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Colors.grey[200],
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
          errorWidget: (context, url, error) => _buildPhotoPlaceholder(),
        ),
      );
    }

    // Show placeholder if no photo
    return _buildPhotoPlaceholder();
  }

  Widget _buildPhotoPlaceholder() {
    return Container(
      width: double.infinity,
      height: 300,
      color: Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_camera,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 8),
          Text(
            'No photo available',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMapSection() {
    final lat = widget.observation.latitude!;
    final lng = widget.observation.longitude!;
    final position = LatLng(lat, lng);

    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      clipBehavior: Clip.antiAlias,
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: position,
          zoom: 14,
        ),
        markers: {
          Marker(
            markerId: MarkerId(widget.observation.id),
            position: position,
            infoWindow: InfoWindow(
              title: widget.observation.speciesName,
              snippet: widget.observation.location,
            ),
          ),
        },
        onMapCreated: (controller) {
          _mapController = controller;
        },
        myLocationButtonEnabled: false,
        zoomControlsEnabled: true,
        mapToolbarEnabled: false,
      ),
    );
  }

  String _formatCoordinates(double latitude, double longitude) {
    final latDirection = latitude >= 0 ? 'N' : 'S';
    final lngDirection = longitude >= 0 ? 'E' : 'W';
    
    return '${latitude.abs().toStringAsFixed(6)}° $latDirection, '
           '${longitude.abs().toStringAsFixed(6)}° $lngDirection';
  }
}
