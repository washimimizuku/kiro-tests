import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

/// Widget for picking location coordinates
/// Shows map and allows selecting location
class LocationPicker extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final Function(double latitude, double longitude) onLocationSelected;
  final bool enabled;

  const LocationPicker({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    required this.onLocationSelected,
    this.enabled = true,
  });

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  bool _isLoadingLocation = false;
  double? _accuracy;

  @override
  void initState() {
    super.initState();
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _selectedLocation = LatLng(widget.initialLatitude!, widget.initialLongitude!);
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    if (!widget.enabled) return;

    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location services are disabled. Please enable them in settings.'),
            ),
          );
        }
        return;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location permission denied'),
              ),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission permanently denied. Please enable in settings.'),
            ),
          );
        }
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
        _accuracy = position.accuracy;
      });

      widget.onLocationSelected(position.latitude, position.longitude);

      // Move camera to current location
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_selectedLocation!, 15),
      );

      // Show accuracy warning if low
      if (position.accuracy > 50 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('GPS accuracy is low (±${position.accuracy.toStringAsFixed(0)}m)'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  void _onMapTap(LatLng position) {
    if (!widget.enabled) return;

    setState(() {
      _selectedLocation = position;
      _accuracy = null; // Manual selection has no accuracy
    });

    widget.onLocationSelected(position.latitude, position.longitude);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Location',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (_isLoadingLocation)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // Use Current Location button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: widget.enabled ? _getCurrentLocation : null,
            icon: const Icon(Icons.my_location),
            label: const Text('Use Current Location'),
          ),
        ),
        const SizedBox(height: 12),

        // Coordinate display
        if (_selectedLocation != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _formatCoordinates(_selectedLocation!.latitude, _selectedLocation!.longitude),
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
                if (_accuracy != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Accuracy: ±${_accuracy!.toStringAsFixed(0)}m',
                    style: TextStyle(
                      fontSize: 12,
                      color: _accuracy! > 50 ? Colors.orange[800] : Colors.green[800],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Map
        Container(
          height: 250,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          clipBehavior: Clip.antiAlias,
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _selectedLocation ?? const LatLng(37.7749, -122.4194), // Default to SF
              zoom: _selectedLocation != null ? 15 : 10,
            ),
            markers: _selectedLocation != null
                ? {
                    Marker(
                      markerId: const MarkerId('selected'),
                      position: _selectedLocation!,
                      draggable: widget.enabled,
                      onDragEnd: (newPosition) {
                        setState(() {
                          _selectedLocation = newPosition;
                          _accuracy = null;
                        });
                        widget.onLocationSelected(newPosition.latitude, newPosition.longitude);
                      },
                    ),
                  }
                : {},
            onTap: _onMapTap,
            onMapCreated: (controller) {
              _mapController = controller;
            },
            myLocationButtonEnabled: false,
            zoomControlsEnabled: true,
            mapToolbarEnabled: false,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tap on the map to set location or drag the marker',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ],
    );
  }

  String _formatCoordinates(double latitude, double longitude) {
    final latDirection = latitude >= 0 ? 'N' : 'S';
    final lngDirection = longitude >= 0 ? 'E' : 'W';
    
    return '${latitude.abs().toStringAsFixed(6)}° $latDirection, '
           '${longitude.abs().toStringAsFixed(6)}° $lngDirection';
  }
}
