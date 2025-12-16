/// Observation model representing a bird sighting
class Observation {
  final String id;
  final String userId;
  final String? tripId;
  final String speciesName;
  final DateTime observationDate;
  final String location;
  final double? latitude;
  final double? longitude;
  final String? notes;
  final String? photoUrl;
  final String? localPhotoPath; // For offline photos
  final bool isShared;
  final bool pendingSync; // Local only - indicates if observation needs to be synced
  final DateTime createdAt;
  final DateTime updatedAt;

  const Observation({
    required this.id,
    required this.userId,
    this.tripId,
    required this.speciesName,
    required this.observationDate,
    required this.location,
    this.latitude,
    this.longitude,
    this.notes,
    this.photoUrl,
    this.localPhotoPath,
    required this.isShared,
    this.pendingSync = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates an Observation from JSON data (from API)
  factory Observation.fromJson(Map<String, dynamic> json) {
    return Observation(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      tripId: json['trip_id'] as String?,
      speciesName: json['species_name'] as String,
      observationDate: DateTime.parse(json['observation_date'] as String),
      location: json['location'] as String,
      latitude: json['latitude'] as double?,
      longitude: json['longitude'] as double?,
      notes: json['notes'] as String?,
      photoUrl: json['photo_url'] as String?,
      localPhotoPath: null, // Not from API
      isShared: json['is_shared'] as bool? ?? false,
      pendingSync: false, // Not from API
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Converts Observation to JSON format (for API)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'trip_id': tripId,
      'species_name': speciesName,
      'observation_date': observationDate.toIso8601String(),
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'notes': notes,
      'photo_url': photoUrl,
      'is_shared': isShared,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Creates an Observation from SQLite database map
  factory Observation.fromMap(Map<String, dynamic> map) {
    return Observation(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      tripId: map['trip_id'] as String?,
      speciesName: map['species_name'] as String,
      observationDate: DateTime.parse(map['observation_date'] as String),
      location: map['location'] as String,
      latitude: map['latitude'] as double?,
      longitude: map['longitude'] as double?,
      notes: map['notes'] as String?,
      photoUrl: map['photo_url'] as String?,
      localPhotoPath: map['local_photo_path'] as String?,
      isShared: (map['is_shared'] as int) == 1,
      pendingSync: (map['pending_sync'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Converts Observation to SQLite database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'trip_id': tripId,
      'species_name': speciesName,
      'observation_date': observationDate.toIso8601String(),
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'notes': notes,
      'photo_url': photoUrl,
      'local_photo_path': localPhotoPath,
      'is_shared': isShared ? 1 : 0,
      'pending_sync': pendingSync ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Creates a copy of this Observation with the given fields replaced
  Observation copyWith({
    String? id,
    String? userId,
    String? tripId,
    String? speciesName,
    DateTime? observationDate,
    String? location,
    double? latitude,
    double? longitude,
    String? notes,
    String? photoUrl,
    String? localPhotoPath,
    bool? isShared,
    bool? pendingSync,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Observation(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      tripId: tripId ?? this.tripId,
      speciesName: speciesName ?? this.speciesName,
      observationDate: observationDate ?? this.observationDate,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      notes: notes ?? this.notes,
      photoUrl: photoUrl ?? this.photoUrl,
      localPhotoPath: localPhotoPath ?? this.localPhotoPath,
      isShared: isShared ?? this.isShared,
      pendingSync: pendingSync ?? this.pendingSync,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Observation &&
        other.id == id &&
        other.userId == userId &&
        other.tripId == tripId &&
        other.speciesName == speciesName &&
        other.observationDate == observationDate &&
        other.location == location &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.notes == notes &&
        other.photoUrl == photoUrl &&
        other.localPhotoPath == localPhotoPath &&
        other.isShared == isShared &&
        other.pendingSync == pendingSync &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      tripId,
      speciesName,
      observationDate,
      location,
      latitude,
      longitude,
      notes,
      photoUrl,
      localPhotoPath,
      isShared,
      pendingSync,
      createdAt,
      updatedAt,
    );
  }

  @override
  String toString() {
    return 'Observation(id: $id, userId: $userId, tripId: $tripId, '
        'speciesName: $speciesName, observationDate: $observationDate, '
        'location: $location, latitude: $latitude, longitude: $longitude, '
        'notes: $notes, photoUrl: $photoUrl, localPhotoPath: $localPhotoPath, '
        'isShared: $isShared, pendingSync: $pendingSync, '
        'createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}
