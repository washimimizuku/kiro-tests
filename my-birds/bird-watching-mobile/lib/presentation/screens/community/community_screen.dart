import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../data/models/observation.dart';
import '../../../data/repositories/observation_repository.dart';
import '../../../config/dependency_injection.dart';
import '../../widgets/observation_card.dart';
import '../observations/observation_detail_screen.dart';

/// Screen displaying shared observations from the community
class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final ObservationRepository _observationRepository = getIt<ObservationRepository>();
  
  List<Observation> _observations = [];
  List<Observation> _filteredObservations = [];
  bool _isLoading = false;
  bool _isMapView = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMorePages = true;
  
  // Filter state
  String _speciesFilter = '';
  String _locationFilter = '';
  
  // Map state
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _loadSharedObservations();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  /// Load shared observations from the repository
  Future<void> _loadSharedObservations({bool loadMore = false}) async {
    if (_isLoading || (!loadMore && _currentPage > 1)) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final page = loadMore ? _currentPage + 1 : 1;
      final observations = await _observationRepository.getSharedObservations(
        page: page,
        pageSize: 20,
      );

      setState(() {
        if (loadMore) {
          _observations.addAll(observations);
          _currentPage = page;
        } else {
          _observations = observations;
          _currentPage = 1;
        }
        _hasMorePages = observations.length == 20;
        _applyFilters();
        _updateMapMarkers();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Apply filters to observations
  void _applyFilters() {
    _filteredObservations = _observations.where((obs) {
      final matchesSpecies = _speciesFilter.isEmpty ||
          obs.speciesName.toLowerCase().contains(_speciesFilter.toLowerCase());
      final matchesLocation = _locationFilter.isEmpty ||
          obs.location.toLowerCase().contains(_locationFilter.toLowerCase());
      return matchesSpecies && matchesLocation;
    }).toList();
  }

  /// Update map markers based on filtered observations
  void _updateMapMarkers() {
    _markers = _filteredObservations
        .where((obs) => obs.latitude != null && obs.longitude != null)
        .map((obs) {
      return Marker(
        markerId: MarkerId(obs.id),
        position: LatLng(obs.latitude!, obs.longitude!),
        infoWindow: InfoWindow(
          title: obs.speciesName,
          snippet: obs.location,
          onTap: () => _showObservationDetails(obs),
        ),
        onTap: () => _showObservationDetails(obs),
      );
    }).toSet();
  }

  /// Show observation details in a bottom sheet
  void _showObservationDetails(Observation observation) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.2,
        maxChildSize: 0.8,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Observation details
                  Text(
                    observation.speciesName,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'By ${observation.userId}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 16),
                  if (observation.photoUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        observation.photoUrl!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 200,
                            color: Colors.grey[300],
                            child: const Icon(Icons.image_not_supported),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 16),
                  _buildDetailRow(Icons.location_on, observation.location),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    Icons.calendar_today,
                    '${observation.observationDate.year}-${observation.observationDate.month.toString().padLeft(2, '0')}-${observation.observationDate.day.toString().padLeft(2, '0')}',
                  ),
                  if (observation.notes != null && observation.notes!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Notes',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(observation.notes!),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ObservationDetailScreen(
                              observation: observation,
                            ),
                          ),
                        );
                      },
                      child: const Text('View Full Details'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      ],
    );
  }

  /// Show filter dialog
  void _showFilterDialog() {
    final speciesController = TextEditingController(text: _speciesFilter);
    final locationController = TextEditingController(text: _locationFilter);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Observations'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: speciesController,
              decoration: const InputDecoration(
                labelText: 'Species',
                hintText: 'Filter by species name',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                hintText: 'Filter by location',
                prefixIcon: Icon(Icons.location_on),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _speciesFilter = '';
                _locationFilter = '';
                _applyFilters();
                _updateMapMarkers();
              });
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _speciesFilter = speciesController.text;
                _locationFilter = locationController.text;
                _applyFilters();
                _updateMapMarkers();
              });
              Navigator.pop(context);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Filter bar
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Row(
              children: [
                // Filter button
                IconButton(
                  icon: Badge(
                    isLabelVisible: _speciesFilter.isNotEmpty || _locationFilter.isNotEmpty,
                    child: const Icon(Icons.filter_list),
                  ),
                  onPressed: _showFilterDialog,
                  tooltip: 'Filter',
                ),
                // Active filters display
                if (_speciesFilter.isNotEmpty || _locationFilter.isNotEmpty)
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          if (_speciesFilter.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Chip(
                                label: Text('Species: $_speciesFilter'),
                                onDeleted: () {
                                  setState(() {
                                    _speciesFilter = '';
                                    _applyFilters();
                                    _updateMapMarkers();
                                  });
                                },
                              ),
                            ),
                          if (_locationFilter.isNotEmpty)
                            Chip(
                              label: Text('Location: $_locationFilter'),
                              onDeleted: () {
                                setState(() {
                                  _locationFilter = '';
                                  _applyFilters();
                                  _updateMapMarkers();
                                });
                              },
                            ),
                        ],
                      ),
                    ),
                  )
                else
                  const Expanded(
                    child: Text('Shared Observations'),
                  ),
                // View toggle button
                IconButton(
                  icon: Icon(_isMapView ? Icons.list : Icons.map),
                  onPressed: () {
                    setState(() {
                      _isMapView = !_isMapView;
                    });
                  },
                  tooltip: _isMapView ? 'List View' : 'Map View',
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error loading shared observations',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadSharedObservations(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_isLoading && _observations.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_filteredObservations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No shared observations found',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _speciesFilter.isNotEmpty || _locationFilter.isNotEmpty
                  ? 'Try adjusting your filters'
                  : 'Check back later for community observations',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return _isMapView ? _buildMapView() : _buildListView();
  }

  Widget _buildListView() {
    return RefreshIndicator(
      onRefresh: () => _loadSharedObservations(),
      child: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          if (!_isLoading &&
              _hasMorePages &&
              scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
            _loadSharedObservations(loadMore: true);
          }
          return false;
        },
        child: ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: _filteredObservations.length + (_hasMorePages ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == _filteredObservations.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final observation = _filteredObservations[index];
            return ObservationCard(
              observation: observation,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ObservationDetailScreen(
                      observation: observation,
                    ),
                  ),
                );
              },
              showOwner: true,
            );
          },
        ),
      ),
    );
  }

  Widget _buildMapView() {
    if (_markers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No observations with coordinates'),
          ],
        ),
      );
    }

    // Calculate bounds for all markers
    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;

    for (final marker in _markers) {
      minLat = minLat < marker.position.latitude ? minLat : marker.position.latitude;
      maxLat = maxLat > marker.position.latitude ? maxLat : marker.position.latitude;
      minLng = minLng < marker.position.longitude ? minLng : marker.position.longitude;
      maxLng = maxLng > marker.position.longitude ? maxLng : marker.position.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: LatLng(
          (minLat + maxLat) / 2,
          (minLng + maxLng) / 2,
        ),
        zoom: 10,
      ),
      markers: _markers,
      onMapCreated: (controller) {
        _mapController = controller;
        // Animate to show all markers
        controller.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 50),
        );
      },
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
    );
  }
}
