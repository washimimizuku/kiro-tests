import 'package:dio/dio.dart';
import '../models/trip.dart';
import '../models/observation.dart';
import '../services/api_service.dart';
import '../services/local_database.dart';
import '../services/connectivity_service.dart';
import '../../core/constants/app_constants.dart';

/// Repository for trip operations
/// Handles CRUD operations for trips and trip-observation associations
class TripRepository {
  final ApiService _apiService;
  final LocalDatabase _localDb;
  final ConnectivityService _connectivity;

  TripRepository({
    required ApiService apiService,
    required LocalDatabase localDb,
    required ConnectivityService connectivity,
  })  : _apiService = apiService,
        _localDb = localDb,
        _connectivity = connectivity;

  /// Get all trips
  /// If online and forceRefresh is true, fetches from API and updates cache
  /// Otherwise returns cached trips
  Future<List<Trip>> getTrips({
    bool forceRefresh = false,
    String? userId,
  }) async {
    try {
      final isConnected = await _connectivity.isConnected();

      if (isConnected && forceRefresh) {
        // Fetch from API
        final response = await _apiService.get(
          AppConstants.tripsEndpoint,
          queryParams: userId != null ? {'user_id': userId} : null,
        );

        final trips = (response.data as List)
            .map((json) => Trip.fromJson(json as Map<String, dynamic>))
            .toList();

        // Update local cache
        for (final trip in trips) {
          await _localDb.insertTrip(trip.toMap());
        }

        return trips;
      }

      // Return from local database
      final maps = await _localDb.getTrips(userId: userId);
      return maps.map((map) => Trip.fromMap(map)).toList();
    } catch (e) {
      print('[TripRepository Error] Failed to get trips: $e');
      
      // Fallback to local database on error
      final maps = await _localDb.getTrips(userId: userId);
      return maps.map((map) => Trip.fromMap(map)).toList();
    }
  }

  /// Get trip by ID
  Future<Trip?> getTripById(String id) async {
    try {
      final isConnected = await _connectivity.isConnected();

      if (isConnected) {
        // Try to fetch from API
        final response = await _apiService.get('${AppConstants.tripsEndpoint}/$id');
        final trip = Trip.fromJson(response.data);
        
        // Update local cache
        await _localDb.insertTrip(trip.toMap());
        
        return trip;
      }

      // Return from local database
      final map = await _localDb.getTripById(id);
      return map != null ? Trip.fromMap(map) : null;
    } catch (e) {
      print('[TripRepository Error] Failed to get trip $id: $e');
      
      // Fallback to local database
      final map = await _localDb.getTripById(id);
      return map != null ? Trip.fromMap(map) : null;
    }
  }

  /// Create a new trip
  Future<Trip> createTrip(Trip trip) async {
    try {
      final isConnected = await _connectivity.isConnected();

      if (isConnected) {
        // Create via API
        final response = await _apiService.post(
          AppConstants.tripsEndpoint,
          data: trip.toJson(),
        );

        final createdTrip = Trip.fromJson(response.data);
        
        // Store in local database
        await _localDb.insertTrip(createdTrip.toMap());
        
        return createdTrip;
      } else {
        throw Exception('Cannot create trip while offline. Please connect to the internet.');
      }
    } catch (e) {
      print('[TripRepository Error] Failed to create trip: $e');
      rethrow;
    }
  }

  /// Update an existing trip
  Future<Trip> updateTrip(Trip trip) async {
    try {
      final isConnected = await _connectivity.isConnected();

      if (isConnected) {
        // Update via API
        final response = await _apiService.put(
          '${AppConstants.tripsEndpoint}/${trip.id}',
          data: trip.toJson(),
        );

        final updatedTrip = Trip.fromJson(response.data);
        
        // Update local database
        await _localDb.updateTrip(updatedTrip.toMap());
        
        return updatedTrip;
      } else {
        throw Exception('Cannot update trip while offline. Please connect to the internet.');
      }
    } catch (e) {
      print('[TripRepository Error] Failed to update trip: $e');
      rethrow;
    }
  }

  /// Delete a trip
  /// Note: This preserves all observations associated with the trip
  Future<void> deleteTrip(String id) async {
    try {
      final isConnected = await _connectivity.isConnected();

      if (isConnected) {
        // Delete via API (backend should preserve observations)
        await _apiService.delete('${AppConstants.tripsEndpoint}/$id');
      }

      // Delete from local database
      await _localDb.deleteTrip(id);
      
      print('[TripRepository] Deleted trip: $id');
    } catch (e) {
      print('[TripRepository Error] Failed to delete trip: $e');
      rethrow;
    }
  }

  /// Get all observations for a specific trip
  Future<List<Observation>> getTripObservations(String tripId) async {
    try {
      final isConnected = await _connectivity.isConnected();

      if (isConnected) {
        // Fetch from API
        final response = await _apiService.get(
          '${AppConstants.tripsEndpoint}/$tripId/observations',
        );

        final observations = (response.data as List)
            .map((json) => Observation.fromJson(json as Map<String, dynamic>))
            .toList();

        // Update local cache
        for (final observation in observations) {
          await _localDb.insertObservation(observation.toMap());
        }

        return observations;
      }

      // Return from local database
      final maps = await _localDb.getObservations();
      final allObservations = maps.map((map) => Observation.fromMap(map)).toList();
      
      // Filter by trip ID
      return allObservations.where((obs) => obs.tripId == tripId).toList();
    } catch (e) {
      print('[TripRepository Error] Failed to get trip observations: $e');
      
      // Fallback to local database
      final maps = await _localDb.getObservations();
      final allObservations = maps.map((map) => Observation.fromMap(map)).toList();
      
      // Filter by trip ID
      return allObservations.where((obs) => obs.tripId == tripId).toList();
    }
  }

  /// Add an observation to a trip
  Future<void> addObservationToTrip(String tripId, String observationId) async {
    try {
      final isConnected = await _connectivity.isConnected();

      if (isConnected) {
        // Update via API
        await _apiService.post(
          '${AppConstants.tripsEndpoint}/$tripId/observations/$observationId',
        );
      }

      // Update local observation
      final observationMap = await _localDb.getObservationById(observationId);
      if (observationMap != null) {
        final observation = Observation.fromMap(observationMap);
        final updatedObservation = observation.copyWith(tripId: tripId);
        await _localDb.updateObservation(updatedObservation.toMap());
      }

      print('[TripRepository] Added observation $observationId to trip $tripId');
    } catch (e) {
      print('[TripRepository Error] Failed to add observation to trip: $e');
      rethrow;
    }
  }

  /// Remove an observation from a trip
  Future<void> removeObservationFromTrip(String tripId, String observationId) async {
    try {
      final isConnected = await _connectivity.isConnected();

      if (isConnected) {
        // Update via API
        await _apiService.delete(
          '${AppConstants.tripsEndpoint}/$tripId/observations/$observationId',
        );
      }

      // Update local observation (set tripId to null)
      final observationMap = await _localDb.getObservationById(observationId);
      if (observationMap != null) {
        final observation = Observation.fromMap(observationMap);
        final updatedObservation = observation.copyWith(tripId: null);
        await _localDb.updateObservation(updatedObservation.toMap());
      }

      print('[TripRepository] Removed observation $observationId from trip $tripId');
    } catch (e) {
      print('[TripRepository Error] Failed to remove observation from trip: $e');
      rethrow;
    }
  }
}
