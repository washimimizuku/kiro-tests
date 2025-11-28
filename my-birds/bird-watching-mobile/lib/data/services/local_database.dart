import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../core/constants/app_constants.dart';

/// Service for managing local SQLite database
class LocalDatabase {
  static LocalDatabase? _instance;
  static Database? _database;

  LocalDatabase._();

  /// Get singleton instance
  factory LocalDatabase() {
    _instance ??= LocalDatabase._();
    return _instance!;
  }

  /// Get database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize database
  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, AppConstants.databaseName);

    print('[LocalDatabase] Initializing database at: $path');

    return await openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create database tables
  Future<void> _onCreate(Database db, int version) async {
    print('[LocalDatabase] Creating database tables (version $version)');

    // Create observations table
    await db.execute('''
      CREATE TABLE ${AppConstants.observationsTable} (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        trip_id TEXT,
        species_name TEXT NOT NULL,
        observation_date TEXT NOT NULL,
        location TEXT NOT NULL,
        latitude REAL,
        longitude REAL,
        notes TEXT,
        photo_url TEXT,
        local_photo_path TEXT,
        is_shared INTEGER NOT NULL DEFAULT 0,
        pending_sync INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create index on user_id for faster queries
    await db.execute('''
      CREATE INDEX idx_observations_user_id 
      ON ${AppConstants.observationsTable}(user_id)
    ''');

    // Create index on observation_date for sorting
    await db.execute('''
      CREATE INDEX idx_observations_date 
      ON ${AppConstants.observationsTable}(observation_date DESC)
    ''');

    // Create index on pending_sync for sync queries
    await db.execute('''
      CREATE INDEX idx_observations_pending_sync 
      ON ${AppConstants.observationsTable}(pending_sync)
    ''');

    // Create trips table
    await db.execute('''
      CREATE TABLE ${AppConstants.tripsTable} (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        trip_date TEXT NOT NULL,
        location TEXT NOT NULL,
        description TEXT,
        observation_count INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create index on user_id for faster queries
    await db.execute('''
      CREATE INDEX idx_trips_user_id 
      ON ${AppConstants.tripsTable}(user_id)
    ''');

    // Create index on trip_date for sorting
    await db.execute('''
      CREATE INDEX idx_trips_date 
      ON ${AppConstants.tripsTable}(trip_date DESC)
    ''');

    print('[LocalDatabase] Database tables created successfully');
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('[LocalDatabase] Upgrading database from version $oldVersion to $newVersion');

    // Add migration logic here when database schema changes
    // Example:
    // if (oldVersion < 2) {
    //   await db.execute('ALTER TABLE observations ADD COLUMN new_field TEXT');
    // }
  }

  // Query result cache
  final Map<String, List<Map<String, dynamic>>> _queryCache = {};
  DateTime? _lastCacheTime;
  static const Duration _cacheExpiration = Duration(minutes: 5);

  /// Clear query cache
  void clearQueryCache() {
    _queryCache.clear();
    _lastCacheTime = null;
    print('[LocalDatabase] Query cache cleared');
  }

  /// Check if cache is valid
  bool _isCacheValid() {
    if (_lastCacheTime == null) return false;
    return DateTime.now().difference(_lastCacheTime!) < _cacheExpiration;
  }

  // Observation operations

  /// Insert an observation
  Future<void> insertObservation(
    Map<String, dynamic> observation, {
    bool pendingSync = false,
  }) async {
    final db = await database;
    observation['pending_sync'] = pendingSync ? 1 : 0;
    
    await db.insert(
      AppConstants.observationsTable,
      observation,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    
    // Invalidate cache when data changes
    clearQueryCache();
    
    print('[LocalDatabase] Inserted observation: ${observation['id']}');
  }

  /// Insert multiple observations in a batch transaction
  /// More efficient than inserting one at a time
  Future<void> insertObservationsBatch(
    List<Map<String, dynamic>> observations, {
    bool pendingSync = false,
  }) async {
    final db = await database;
    
    await db.transaction((txn) async {
      final batch = txn.batch();
      
      for (final observation in observations) {
        observation['pending_sync'] = pendingSync ? 1 : 0;
        batch.insert(
          AppConstants.observationsTable,
          observation,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      
      await batch.commit(noResult: true);
    });
    
    // Invalidate cache when data changes
    clearQueryCache();
    
    print('[LocalDatabase] Batch inserted ${observations.length} observations');
  }

  /// Get all observations with caching
  Future<List<Map<String, dynamic>>> getObservations({
    String? userId,
    bool? pendingSync,
    bool useCache = true,
  }) async {
    // Generate cache key
    final cacheKey = 'observations_${userId ?? 'all'}_${pendingSync ?? 'all'}';
    
    // Return cached result if valid
    if (useCache && _isCacheValid() && _queryCache.containsKey(cacheKey)) {
      print('[LocalDatabase] Retrieved ${_queryCache[cacheKey]!.length} observations from cache');
      return _queryCache[cacheKey]!;
    }
    
    final db = await database;
    
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (userId != null) {
      whereClause = 'user_id = ?';
      whereArgs.add(userId);
    }

    if (pendingSync != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'pending_sync = ?';
      whereArgs.add(pendingSync ? 1 : 0);
    }

    final results = await db.query(
      AppConstants.observationsTable,
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'observation_date DESC',
    );

    // Cache the results
    if (useCache) {
      _queryCache[cacheKey] = results;
      _lastCacheTime = DateTime.now();
    }

    print('[LocalDatabase] Retrieved ${results.length} observations from database');
    return results;
  }

  /// Get observations with pagination
  /// More efficient for large datasets
  Future<List<Map<String, dynamic>>> getObservationsPaginated({
    String? userId,
    bool? pendingSync,
    int limit = 20,
    int offset = 0,
  }) async {
    final db = await database;
    
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (userId != null) {
      whereClause = 'user_id = ?';
      whereArgs.add(userId);
    }

    if (pendingSync != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'pending_sync = ?';
      whereArgs.add(pendingSync ? 1 : 0);
    }

    final results = await db.query(
      AppConstants.observationsTable,
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'observation_date DESC',
      limit: limit,
      offset: offset,
    );

    print('[LocalDatabase] Retrieved ${results.length} observations (page: offset=$offset, limit=$limit)');
    return results;
  }

  /// Get observation by ID
  Future<Map<String, dynamic>?> getObservationById(String id) async {
    final db = await database;
    
    final results = await db.query(
      AppConstants.observationsTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    return results.isNotEmpty ? results.first : null;
  }

  /// Update an observation
  Future<void> updateObservation(Map<String, dynamic> observation) async {
    final db = await database;
    
    await db.update(
      AppConstants.observationsTable,
      observation,
      where: 'id = ?',
      whereArgs: [observation['id']],
    );
    
    // Invalidate cache when data changes
    clearQueryCache();
    
    print('[LocalDatabase] Updated observation: ${observation['id']}');
  }

  /// Update multiple observations in a batch transaction
  Future<void> updateObservationsBatch(List<Map<String, dynamic>> observations) async {
    final db = await database;
    
    await db.transaction((txn) async {
      final batch = txn.batch();
      
      for (final observation in observations) {
        batch.update(
          AppConstants.observationsTable,
          observation,
          where: 'id = ?',
          whereArgs: [observation['id']],
        );
      }
      
      await batch.commit(noResult: true);
    });
    
    // Invalidate cache when data changes
    clearQueryCache();
    
    print('[LocalDatabase] Batch updated ${observations.length} observations');
  }

  /// Delete an observation
  Future<void> deleteObservation(String id) async {
    final db = await database;
    
    await db.delete(
      AppConstants.observationsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    
    // Invalidate cache when data changes
    clearQueryCache();
    
    print('[LocalDatabase] Deleted observation: $id');
  }

  /// Delete multiple observations in a batch transaction
  Future<void> deleteObservationsBatch(List<String> ids) async {
    final db = await database;
    
    await db.transaction((txn) async {
      final batch = txn.batch();
      
      for (final id in ids) {
        batch.delete(
          AppConstants.observationsTable,
          where: 'id = ?',
          whereArgs: [id],
        );
      }
      
      await batch.commit(noResult: true);
    });
    
    // Invalidate cache when data changes
    clearQueryCache();
    
    print('[LocalDatabase] Batch deleted ${ids.length} observations');
  }

  /// Get pending sync observations
  Future<List<Map<String, dynamic>>> getPendingSyncObservations() async {
    return await getObservations(pendingSync: true);
  }

  /// Mark observation as synced
  Future<void> markAsSynced(String id) async {
    final db = await database;
    
    await db.update(
      AppConstants.observationsTable,
      {'pending_sync': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
    
    // Invalidate cache when data changes
    clearQueryCache();
    
    print('[LocalDatabase] Marked observation as synced: $id');
  }

  /// Mark multiple observations as synced in a batch transaction
  Future<void> markAsSyncedBatch(List<String> ids) async {
    final db = await database;
    
    await db.transaction((txn) async {
      final batch = txn.batch();
      
      for (final id in ids) {
        batch.update(
          AppConstants.observationsTable,
          {'pending_sync': 0},
          where: 'id = ?',
          whereArgs: [id],
        );
      }
      
      await batch.commit(noResult: true);
    });
    
    // Invalidate cache when data changes
    clearQueryCache();
    
    print('[LocalDatabase] Batch marked ${ids.length} observations as synced');
  }

  // Trip operations

  /// Insert a trip
  Future<void> insertTrip(Map<String, dynamic> trip) async {
    final db = await database;
    
    await db.insert(
      AppConstants.tripsTable,
      trip,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    
    print('[LocalDatabase] Inserted trip: ${trip['id']}');
  }

  /// Get all trips
  Future<List<Map<String, dynamic>>> getTrips({String? userId}) async {
    final db = await database;
    
    final results = await db.query(
      AppConstants.tripsTable,
      where: userId != null ? 'user_id = ?' : null,
      whereArgs: userId != null ? [userId] : null,
      orderBy: 'trip_date DESC',
    );

    print('[LocalDatabase] Retrieved ${results.length} trips');
    return results;
  }

  /// Get trip by ID
  Future<Map<String, dynamic>?> getTripById(String id) async {
    final db = await database;
    
    final results = await db.query(
      AppConstants.tripsTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    return results.isNotEmpty ? results.first : null;
  }

  /// Update a trip
  Future<void> updateTrip(Map<String, dynamic> trip) async {
    final db = await database;
    
    await db.update(
      AppConstants.tripsTable,
      trip,
      where: 'id = ?',
      whereArgs: [trip['id']],
    );
    
    print('[LocalDatabase] Updated trip: ${trip['id']}');
  }

  /// Delete a trip
  Future<void> deleteTrip(String id) async {
    final db = await database;
    
    await db.delete(
      AppConstants.tripsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    
    print('[LocalDatabase] Deleted trip: $id');
  }

  // Cache management

  /// Clear all cached data except pending syncs
  Future<void> clearCache() async {
    final db = await database;
    
    // Delete observations that are not pending sync
    await db.delete(
      AppConstants.observationsTable,
      where: 'pending_sync = ?',
      whereArgs: [0],
    );
    
    // Delete all trips (they don't have pending sync status)
    await db.delete(AppConstants.tripsTable);
    
    print('[LocalDatabase] Cache cleared (preserved pending syncs)');
  }

  /// Get database size in bytes
  Future<int> getDatabaseSize() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, AppConstants.databaseName);
    
    try {
      final file = await databaseFactory.openDatabase(path);
      // Note: sqflite doesn't provide direct file size access
      // This is a placeholder - actual implementation would need platform channels
      await file.close();
      return 0; // Placeholder
    } catch (e) {
      print('[LocalDatabase Error] Failed to get database size: $e');
      return 0;
    }
  }

  /// Close database connection
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
    print('[LocalDatabase] Database closed');
  }
}
