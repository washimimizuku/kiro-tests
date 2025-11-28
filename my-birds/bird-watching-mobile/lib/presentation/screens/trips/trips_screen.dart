import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/trip/trip_bloc.dart';
import '../../blocs/trip/trip_event.dart';
import '../../blocs/trip/trip_state.dart';
import '../../widgets/trip_card.dart';
import '../../../config/routes.dart';

/// Screen displaying list of trips
/// Shows trip cards with observation count, supports pull-to-refresh
class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  @override
  void initState() {
    super.initState();
    // Load trips when screen initializes
    context.read<TripBloc>().add(const LoadTrips());
  }

  Future<void> _onRefresh() async {
    // Trigger refresh with force refresh flag
    context.read<TripBloc>().add(const LoadTrips(forceRefresh: true));
    
    // Wait for the state to update
    await context.read<TripBloc>().stream.firstWhere(
      (state) => state is! TripsLoading,
    );
  }

  void _navigateToTripForm() {
    Navigator.pushNamed(
      context,
      AppRoutes.tripForm,
    ).then((_) {
      // Reload trips after returning from form
      context.read<TripBloc>().add(const LoadTrips(forceRefresh: true));
    });
  }

  void _navigateToTripDetail(String tripId) {
    Navigator.pushNamed(
      context,
      AppRoutes.tripDetail,
      arguments: {'id': tripId},
    ).then((_) {
      // Reload trips after returning from detail
      context.read<TripBloc>().add(const LoadTrips(forceRefresh: true));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trips'),
        elevation: 0,
      ),
      body: BlocBuilder<TripBloc, TripState>(
        builder: (context, state) {
          if (state is TripsLoading) {
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
                    'Error loading trips',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.read<TripBloc>().add(const LoadTrips(forceRefresh: true));
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is TripsLoaded) {
            final trips = state.trips;

            if (trips.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.explore_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No trips yet',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create your first trip to organize observations',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _navigateToTripForm,
                      icon: const Icon(Icons.add),
                      label: const Text('Create Trip'),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: _onRefresh,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: trips.length,
                itemBuilder: (context, index) {
                  final trip = trips[index];
                  return TripCard(
                    trip: trip,
                    onTap: () => _navigateToTripDetail(trip.id),
                  );
                },
              ),
            );
          }

          // Initial state or unknown state
          return const Center(
            child: Text('Pull down to load trips'),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToTripForm,
        tooltip: 'Create Trip',
        child: const Icon(Icons.add),
      ),
    );
  }
}
