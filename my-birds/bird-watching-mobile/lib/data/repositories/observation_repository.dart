import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import '../models/observation.dart';
import '../services/api_service.dart';
import '../services/local_database.dart';
import '../services/connectivity_service.dart';
import '../../core/constants/app_constants.dart';

/// Repository for observation operations
/// Handles CRUD operations with offline support and automatic synchronization
class ObservationRepository {
  final ApiService _apiService;
  final LocalDatabase _localDb;
  final ConnectivityService _connectivity;
  final Uuid _uuid = const Uuid();

  ObservationRepository({
    required ApiService apiService,
    required LocalDatabase localDb,
    required ConnectivityService connectivity,
  })  : _apiService = apiService,
        _localDb = localDb,
        _connectivity = connectivity;

  /// Get all observations
  /// If online and forceRefresh is true, fetches from API and updates cache
  /// Otherwise returns cached observations
  Future<List<Observation>> getObservations({
    bool forceRefresh = false,
    String? userId,
  }) async {
    try {
      final isConnected = await _connectivity.isConnected();

      if (isConnected && forceRefresh) {
        // Fetch from API
        final response = await _apiService.get(
          AppConstants.observationsEndpoint,
          queryParams: userId != null ? {'user_id': userId} : null,
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
      final maps = await _localDb.getObservations(userId: userId);
      return maps.map((map) => Observation.fromMap(map)).toList();
    } catch (e) {
      print('[ObservationRepository Error] Failed to get observations: $e');
      
      // Fallback to local database on error
      final maps = await _localDb.getObservations(userId: userId);
      return maps.map((map) => Observation.fromMap(map)).toList();
    }
  }

  /// Get observation by ID
  Future<Observation?> getObservationById(String id) async {
    try {
      final isConnected = await _connectivity.isConnected();

      if (isConnected) {
        // Try to fetch from API
        final response = await _apiService.get('${AppConstants.observationsEndpoint}/$id');
        final observation = Observation.fromJson(response.data);
        
        // Update local cache
        await _localDb.insertObservation(observation.toMap());
        
        return observation;
      }

      // Return from local database
      final map = await _localDb.getObservationById(id);
      return map != null ? Observation.fromMap(map) : null;
    } catch (e) {
      print('[ObservationRepository Error] Failed to get observation $id: $e');
      
      // Fallback to local database
      final map = await _localDb.getObservationById(id);
      return map != null ? Observation.fromMap(map) : null;
    }
  }

  /// Create a new observation
  /// If online, creates via API. If offline, stores locally with pending sync status
  Future<Observation> createObservation(Observation observation) async {
    try {
      final isConnected = await _connectivity.isConnected();

      if (isConnected) {
        // Create via API
        final response = await _apiService.post(
          AppConstants.observationsEndpoint,
          data: observation.toJson(),
        );

        final createdObservation = Observation.fromJson(response.data);
        
        // Store in local database
        await _localDb.insertObservation(createdObservation.toMap());
        
        return createdObservation;
      } else {
        // Store locally with pending sync
        final offlineObservation = observation.copyWith(
          id: _uuid.v4(),
          pendingSync: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        await _localDb.insertObservation(
          offlineObservation.toMap(),
          pendingSync: true,
        );
        
        print('[ObservationRepository] Created observation offline: ${offlineObservation.id}');
        return offlineObservation;
      }
    } catch (e) {
      print('[ObservationRepository Error] Failed to create observation: $e');
      
      // Store locally with pending sync on error
      final offlineObservation = observation.copyWith(
        id: _uuid.v4(),
        pendingSync: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await _localDb.insertObservation(
        offlineObservation.toMap(),
        pendingSync: true,
      );
      
      return offlineObservation;
    }
  }

  /// Update an existing observation
  /// If online, updates via API. If offline, updates locally with pending sync status
  Future<Observation> updateObservation(Observation observation) async {
    try {
      final isConnected = await _connectivity.isConnected();

      if (isConnected) {
        // Update via API
        final response = await _apiService.put(
          '${AppConstants.observationsEndpoint}/${observation.id}',
          data: observation.toJson(),
        );

        final updatedObservation = Observation.fromJson(response.data);
        
        // Update local database
        await _localDb.updateObservation(updatedObservation.toMap());
        
        return updatedObservation;
      } else {
        // Update locally with pending sync
        final offlineObservation = observation.copyWith(
          pendingSync: true,
          updatedAt: DateTime.now(),
        );
        
        await _localDb.updateObservation(offlineObservation.toMap());
        
        print('[ObservationRepository] Updated observation offline: ${offlineObservation.id}');
        return offlineObservation;
      }
    } catch (e) {
      print('[ObservationRepository Error] Failed to update observation: $e');
      
      // Update locally with pending sync on error
      final offlineObservation = observation.copyWith(
        pendingSync: true,
        updatedAt: DateTime.now(),
      );
      
      await _localDb.updateObservation(offlineObservation.toMap());
      
      return offlineObservation;
    }
  }

  /// Delete an observation
  Future<void> deleteObservation(String id) async {
    try {
      final isConnected = await _connectivity.isConnected();

      if (isConnected) {
        // Delete via API
        await _apiService.delete('${AppConstants.observationsEndpoint}/$id');
      }

      // Delete from local database
      await _localDb.deleteObservation(id);
      
      print('[ObservationRepository] Deleted observation: $id');
    } catch (e) {
      print('[ObservationRepository Error] Failed to delete observation: $e');
      rethrow;
    }
  }

  /// Get observations pending synchronization
  Future<List<Observation>> getPendingSyncObservations() async {
    try {
      final maps = await _localDb.getPendingSyncObservations();
      return maps.map((map) => Observation.fromMap(map)).toList();
    } catch (e) {
      print('[ObservationRepository Error] Failed to get pending sync observations: $e');
      return [];
    }
  }

  /// Sync a single observation to the backend
  Future<void> syncObservation(Observation observation) async {
    try {
      final isConnected = await _connectivity.isConnected();
      
      if (!isConnected) {
        throw Exception('No internet connection');
      }

      // Check if observation exists on server (has a server-generated ID format)
      final isNewObservation = observation.id.contains('-'); // UUID format indicates local creation

      if (isNewObservation) {
        // Create new observation on server
        final response = await _apiService.post(
          AppConstants.observationsEndpoint,
          data: observation.toJson(),
        );

        final syncedObservation = Observation.fromJson(response.data);
        
        // Delete old local observation
        await _localDb.deleteObservation(observation.id);
        
        // Insert synced observation
        await _localDb.insertObservation(syncedObservation.toMap());
      } else {
        // Update existing observation on server
        final response = await _apiService.put(
          '${AppConstants.observationsEndpoint}/${observation.id}',
          data: observation.toJson(),
        );

        final syncedObservation = Observation.fromJson(response.data);
        
        // Update local observation
        await _localDb.updateObservation(syncedObservation.toMap());
      }

      // Mark as synced
      await _localDb.markAsSynced(observation.id);
      
      print('[ObservationRepository] Synced observation: ${observation.id}');
    } catch (e) {
      print('[ObservationRepository Error] Failed to sync observation: $e');
      rethrow;
    }
  }

  /// Search observations by species name or location
  Future<List<Observation>> searchObservations(
    String query, {
    String? userId,
  }) async {
    try {
      final isConnected = await _connectivity.isConnected();

      if (isConnected) {
        // Search via API
        final response = await _apiService.get(
          AppConstants.observationsEndpoint,
          queryParams: {
            'search': query,
            if (userId != null) 'user_id': userId,
          },
        );

        return (response.data as List)
            .map((json) => Observation.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      // Search in local database
      final allObservations = await getObservations(userId: userId);
      final lowerQuery = query.toLowerCase();
      
      return allObservations.where((obs) {
        return obs.speciesName.toLowerCase().contains(lowerQuery) ||
               obs.location.toLowerCase().contains(lowerQuery);
      }).toList();
    } catch (e) {
      print('[ObservationRepository Error] Failed to search observations: $e');
      
      // Fallback to local search
      final allObservations = await getObservations(userId: userId);
      final lowerQuery = query.toLowerCase();
      
      return allObservations.where((obs) {
        return obs.speciesName.toLowerCase().contains(lowerQuery) ||
               obs.location.toLowerCase().contains(lowerQuery);
      }).toList();
    }
  }

  /// Filter observations by date range
  Future<List<Observation>> filterByDateRange(
    DateTime startDate,
    DateTime endDate, {
    String? userId,
  }) async {
    try {
      final allObservations = await getObservations(userId: userId);
      
      return allObservations.where((obs) {
        return obs.observationDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
               obs.observationDate.isBefore(endDate.add(const Duration(days: 1)));
      }).toList();
    } catch (e) {
      print('[ObservationRepository Error] Failed to filter by date range: $e');
      return [];
    }
  }

  /// Get shared observations (from all users)
  Future<List<Observation>> getSharedObservations({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final isConnected = await _connectivity.isConnected();

      if (!isConnected) {
        throw Exception('No internet connection. Shared observations require online access.');
      }

      final response = await _apiService.get(
        AppConstants.observationsEndpoint,
        queryParams: {
          'shared': 'true',
          'page': page.toString(),
          'page_size': pageSize.toString(),
        },
      );

      return (response.data as List)
          .map((json) => Observation.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('[ObservationRepository Error] Failed to get shared observations: $e');
      rethrow;
    }
  }
}
