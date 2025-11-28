import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../blocs/trip/trip_bloc.dart';
import '../../blocs/trip/trip_event.dart';
import '../../blocs/trip/trip_state.dart';
import '../../widgets/observation_card.dart';
import '../../../data/models/trip.dart';
import '../../../config/routes.dart';

/// Screen displaying trip details
/// Shows trip information, map with observations, and list of observations
class TripDetailScreen extends StatefulWidget {
  final String tripId;

  const TripDetailScreen({
    super.key,
    required this.tripId,
  });

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  GoogleMapController? _mapController;
  Trip? _currentTrip;

  @override
  void initState() {
    super.initState();
    // Load trip details and observations
    context.read<TripBloc>().add(LoadTripById(widget.tripId));
    context.read<TripBloc>().add(LoadTripObservations(widget.tripId));
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void _navigateToTripForm() {
    if (_currentTrip == null) return;

    Navigator.pushNamed(
      context,
      AppRoutes.tripForm,
      arguments: {'trip': _currentTrip},
    ).then((_) {
      // Reload trip after editing
      context.read<TripBloc>().add(LoadTripById(widget.tripId));
    });
  }

  void _navigateToObservationForm() {
    Navigator.pushNamed(
      context,
      AppRoutes.observationForm,
      arguments: {'tripId': widget.tripId},
    ).then((_) {
      // Reload observations after adding
      context.read<TripBloc>().add(LoadTripObservations(widget.tripId));
    });
  }

  void _navigateToObservationDetail(String observationId) {
    Navigator.pushNamed(
      context,
      AppRoutes.observationDetail,
      arguments: {'id': observationId},
    );
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Trip'),
        content: const Text(
          'Are you sure you want to delete this trip? '
          'All observations will be preserved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      context.read<TripBloc>().add(DeleteTrip(widget.tripId));
      Navigator.pop(context);
    }
  }

  void _removeObservationFromTrip(String observationId) {
    context.read<TripBloc>().add(
      RemoveObservationFromTrip(
        tripId: widget.tripId,
        observationId: observationId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Details'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _navigateToTripForm,
            tooltip: 'Edit Trip',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _confirmDelete,
            tooltip: 'Delete Trip',
          ),
        ],
      ),
      body: BlocBuilder<TripBloc, TripState>(
        builder: (context, state) {
          if (state is TripLoading || state is TripObservationsLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is TripError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading trip',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      state.message,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            );
          }

          if (state is TripLoaded) {
            _currentTrip = state.trip;
            return _buildTripInfo(state.trip);
          }

          if (state is TripObservationsLoaded) {
            return _buildTripWithObservations(state.observations);
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToObservationForm,
        icon: const Icon(Icons.add),
        label: const Text('Add Observation'),
      ),
    );
  }

  Widget _buildTripInfo(Trip trip) {
    final dateFormat = DateFormat('MMMM d, yyyy');

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Trip header
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trip.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      dateFormat.format(trip.tripDate),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        trip.location,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                      ),
                    ),
                  ],
                ),
                if (trip.description != null && trip.description!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    trip.description!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                  ),
                ],
              ],
            ),
          ),

          // Observation count
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '${trip.observationCount} ${trip.observationCount == 1 ? 'Observation' : 'Observations'}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),

          // Loading observations message
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: Text('Loading observations...'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripWithObservations(List<dynamic> observations) {
    if (_currentTrip == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final dateFormat = DateFormat('MMMM d, yyyy');
    final observationsWithCoords = observations
        .where((obs) => obs.latitude != null && obs.longitude != null)
        .toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Trip header
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentTrip!.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      dateFormat.format(_currentTrip!.tripDate),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _currentTrip!.location,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                      ),
                    ),
                  ],
                ),
                if (_currentTrip!.description != null && 
                    _currentTrip!.description!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    _currentTrip!.description!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                  ),
                ],
              ],
            ),
          ),

          // Map with observations
          if (observationsWithCoords.isNotEmpty) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Map',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 250,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              clipBehavior: Clip.antiAlias,
              child: _buildMap(observationsWithCoords),
            ),
          ],

          // Observations list
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Observations (${observations.length})',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const SizedBox(height: 8),

          if (observations.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.visibility_off,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No observations yet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add observations to this trip',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: observations.length,
              itemBuilder: (context, index) {
                final observation = observations[index];
                return Dismissible(
                  key: Key(observation.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    child: const Icon(
                      Icons.remove_circle,
                      color: Colors.white,
                    ),
                  ),
                  confirmDismiss: (direction) async {
                    return await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Remove Observation'),
                        content: const Text(
                          'Remove this observation from the trip? '
                          'The observation will not be deleted.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: const Text('Remove'),
                          ),
                        ],
                      ),
                    );
                  },
                  onDismissed: (direction) {
                    _removeObservationFromTrip(observation.id);
                  },
                  child: ObservationCard(
                    observation: observation,
                    onTap: () => _navigateToObservationDetail(observation.id),
                  ),
                );
              },
            ),
          const SizedBox(height: 80), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildMap(List<dynamic> observations) {
    // Calculate bounds to fit all markers
    double minLat = observations.first.latitude!;
    double maxLat = observations.first.latitude!;
    double minLng = observations.first.longitude!;
    double maxLng = observations.first.longitude!;

    for (final obs in observations) {
      if (obs.latitude! < minLat) minLat = obs.latitude!;
      if (obs.latitude! > maxLat) maxLat = obs.latitude!;
      if (obs.longitude! < minLng) minLng = obs.longitude!;
      if (obs.longitude! > maxLng) maxLng = obs.longitude!;
    }

    final center = LatLng(
      (minLat + maxLat) / 2,
      (minLng + maxLng) / 2,
    );

    // Create markers
    final markers = observations.map((obs) {
      return Marker(
        markerId: MarkerId(obs.id),
        position: LatLng(obs.latitude!, obs.longitude!),
        infoWindow: InfoWindow(
          title: obs.speciesName,
          snippet: obs.location,
        ),
      );
    }).toSet();

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: center,
        zoom: 12,
      ),
      markers: markers,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      onMapCreated: (controller) {
        _mapController = controller;
        
        // Fit bounds after map is created
        if (observations.length > 1) {
          final bounds = LatLngBounds(
            southwest: LatLng(minLat, minLng),
            northeast: LatLng(maxLat, maxLng),
          );
          
          Future.delayed(const Duration(milliseconds: 100), () {
            controller.animateCamera(
              CameraUpdate.newLatLngBounds(bounds, 50),
            );
          });
        }
      },
    );
  }
}
