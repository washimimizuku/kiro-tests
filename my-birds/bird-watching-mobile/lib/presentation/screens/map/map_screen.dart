import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import '../../../data/models/observation.dart';
import '../../blocs/map/map_bloc.dart';
import '../../blocs/map/map_event.dart';
import '../../blocs/map/map_state.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';

/// Screen displaying observations on a map
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  final Completer<GoogleMapController> _controllerCompleter = Completer();

  @override
  void initState() {
    super.initState();
    // Load observations when screen initializes
    _loadObservations();
  }

  void _loadObservations() {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      context.read<MapBloc>().add(LoadMapObservations(
            userId: authState.user.id,
          ));
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MapBloc, MapState>(
      builder: (context, state) {
        if (state is MapLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (state is MapError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error loading map',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(state.message),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadObservations,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (state is MapLoaded) {
          return Stack(
            children: [
              // Google Map
              _buildMap(state),

              // Filter controls
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: _buildFilterControls(state),
              ),

              // Center on current location button
              Positioned(
                bottom: state.selectedObservation != null ? 320 : 16,
                right: 16,
                child: _buildLocationButton(),
              ),

              // Clustering toggle button
              Positioned(
                bottom: state.selectedObservation != null ? 380 : 76,
                right: 16,
                child: _buildClusteringButton(state),
              ),

              // Bottom sheet for observation details
              if (state.selectedObservation != null)
                _buildObservationBottomSheet(state.selectedObservation!),
            ],
          );
        }

        // Initial state
        return const Center(
          child: Text('Loading map...'),
        );
      },
    );
  }

  Widget _buildMap(MapLoaded state) {
    // Calculate initial camera position
    CameraPosition initialPosition;
    if (state.center != null) {
      initialPosition = CameraPosition(
        target: LatLng(state.center!.latitude, state.center!.longitude),
        zoom: state.center!.zoom,
      );
    } else {
      // Default to a reasonable location if no center
      initialPosition = const CameraPosition(
        target: LatLng(37.7749, -122.4194), // San Francisco
        zoom: 10.0,
      );
    }

    // Create markers
    final markers = _createMarkers(state);

    return GoogleMap(
      initialCameraPosition: initialPosition,
      markers: markers,
      myLocationEnabled: true,
      myLocationButtonEnabled: false, // We have our own button
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      onMapCreated: (GoogleMapController controller) {
        if (!_controllerCompleter.isCompleted) {
          _controllerCompleter.complete(controller);
        }
        _mapController = controller;

        // Move camera to center if available
        if (state.center != null) {
          controller.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: LatLng(state.center!.latitude, state.center!.longitude),
                zoom: state.center!.zoom,
              ),
            ),
          );
        }
      },
      onTap: (_) {
        // Deselect observation when tapping on map
        if (state.selectedObservation != null) {
          context.read<MapBloc>().add(const DeselectObservation());
        }
      },
    );
  }

  Set<Marker> _createMarkers(MapLoaded state) {
    if (state.clusteringEnabled && state.markers.length > 50) {
      // For large numbers of markers, we would implement clustering
      // For now, we'll just show all markers
      // A proper implementation would use a clustering library
      return _createSimpleMarkers(state);
    } else {
      return _createSimpleMarkers(state);
    }
  }

  Set<Marker> _createSimpleMarkers(MapLoaded state) {
    return state.markers.map((mapMarker) {
      final isSelected =
          state.selectedObservation?.id == mapMarker.observation.id;

      return Marker(
        markerId: MarkerId(mapMarker.id),
        position: LatLng(mapMarker.latitude, mapMarker.longitude),
        icon: isSelected
            ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue)
            : BitmapDescriptor.defaultMarker,
        onTap: () {
          context
              .read<MapBloc>()
              .add(SelectObservation(mapMarker.observation));
        },
        infoWindow: InfoWindow(
          title: mapMarker.observation.speciesName,
          snippet: mapMarker.observation.location,
        ),
      );
    }).toSet();
  }

  Widget _buildFilterControls(MapLoaded state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Expanded(
              child: Text(
                state.hasActiveFilters
                    ? 'Filters active (${state.markers.length} observations)'
                    : '${state.markers.length} observations',
                style: const TextStyle(fontSize: 14),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () => _showFilterDialog(state),
              tooltip: 'Filter observations',
            ),
            if (state.hasActiveFilters)
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  context.read<MapBloc>().add(const ClearMapFilters());
                },
                tooltip: 'Clear filters',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationButton() {
    return FloatingActionButton(
      heroTag: 'location_button',
      mini: true,
      onPressed: () {
        context.read<MapBloc>().add(const CenterOnCurrentLocation());
      },
      child: const Icon(Icons.my_location),
    );
  }

  Widget _buildClusteringButton(MapLoaded state) {
    return FloatingActionButton(
      heroTag: 'clustering_button',
      mini: true,
      onPressed: () {
        context
            .read<MapBloc>()
            .add(SetClusteringEnabled(!state.clusteringEnabled));
      },
      child: Icon(
        state.clusteringEnabled ? Icons.grid_on : Icons.grid_off,
      ),
    );
  }

  Widget _buildObservationBottomSheet(Observation observation) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        height: 300,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Close button
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  context.read<MapBloc>().add(const DeselectObservation());
                },
              ),
            ),

            // Observation details
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Photo
                    if (observation.photoUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          observation.photoUrl!,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 150,
                              color: Colors.grey[300],
                              child: const Icon(Icons.image_not_supported),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Species name
                    Text(
                      observation.speciesName,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),

                    // Location
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 16),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(observation.location),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Date
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(observation.observationDate),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Coordinates
                    if (observation.latitude != null &&
                        observation.longitude != null)
                      Text(
                        'Coordinates: ${observation.latitude!.toStringAsFixed(6)}, ${observation.longitude!.toStringAsFixed(6)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),

                    // Notes
                    if (observation.notes != null &&
                        observation.notes!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Notes',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(observation.notes!),
                    ],

                    const SizedBox(height: 16),

                    // View details button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/observation-detail',
                            arguments: observation,
                          );
                        },
                        child: const Text('View Details'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog(MapLoaded state) {
    showDialog(
      context: context,
      builder: (dialogContext) => _FilterDialog(
        initialSpeciesFilter: state.speciesFilter,
        initialLocationFilter: state.locationFilter,
        initialStartDate: state.startDate,
        initialEndDate: state.endDate,
        onApply: (species, location, startDate, endDate) {
          context.read<MapBloc>().add(FilterMapObservations(
                speciesFilter: species,
                locationFilter: location,
                startDate: startDate,
                endDate: endDate,
              ));
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

/// Dialog for filtering observations on the map
class _FilterDialog extends StatefulWidget {
  final String? initialSpeciesFilter;
  final String? initialLocationFilter;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final Function(String?, String?, DateTime?, DateTime?) onApply;

  const _FilterDialog({
    this.initialSpeciesFilter,
    this.initialLocationFilter,
    this.initialStartDate,
    this.initialEndDate,
    required this.onApply,
  });

  @override
  State<_FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<_FilterDialog> {
  late TextEditingController _speciesController;
  late TextEditingController _locationController;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _speciesController =
        TextEditingController(text: widget.initialSpeciesFilter);
    _locationController =
        TextEditingController(text: widget.initialLocationFilter);
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;
  }

  @override
  void dispose() {
    _speciesController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filter Observations'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Species filter
            TextField(
              controller: _speciesController,
              decoration: const InputDecoration(
                labelText: 'Species',
                hintText: 'Filter by species name',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 16),

            // Location filter
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                hintText: 'Filter by location',
                prefixIcon: Icon(Icons.location_on),
              ),
            ),
            const SizedBox(height: 16),

            // Date range
            const Text('Date Range', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            // Start date
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: Text(_startDate == null
                  ? 'Start Date'
                  : _formatDate(_startDate!)),
              trailing: _startDate != null
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _startDate = null;
                        });
                      },
                    )
                  : null,
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _startDate ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() {
                    _startDate = date;
                  });
                }
              },
            ),

            // End date
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: Text(
                  _endDate == null ? 'End Date' : _formatDate(_endDate!)),
              trailing: _endDate != null
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _endDate = null;
                        });
                      },
                    )
                  : null,
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _endDate ?? DateTime.now(),
                  firstDate: _startDate ?? DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() {
                    _endDate = date;
                  });
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            // Clear all filters
            setState(() {
              _speciesController.clear();
              _locationController.clear();
              _startDate = null;
              _endDate = null;
            });
          },
          child: const Text('Clear All'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onApply(
              _speciesController.text.isEmpty ? null : _speciesController.text,
              _locationController.text.isEmpty
                  ? null
                  : _locationController.text,
              _startDate,
              _endDate,
            );
            Navigator.pop(context);
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
