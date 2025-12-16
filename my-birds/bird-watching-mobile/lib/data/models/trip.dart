/// Trip model representing a bird watching excursion
class Trip {
  final String id;
  final String userId;
  final String name;
  final DateTime tripDate;
  final String location;
  final String? description;
  final int observationCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Trip({
    required this.id,
    required this.userId,
    required this.name,
    required this.tripDate,
    required this.location,
    this.description,
    required this.observationCount,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a Trip from JSON data (from API)
  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      tripDate: DateTime.parse(json['trip_date'] as String),
      location: json['location'] as String,
      description: json['description'] as String?,
      observationCount: json['observation_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Converts Trip to JSON format (for API)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'trip_date': tripDate.toIso8601String(),
      'location': location,
      'description': description,
      'observation_count': observationCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Creates a Trip from SQLite database map
  factory Trip.fromMap(Map<String, dynamic> map) {
    return Trip(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      name: map['name'] as String,
      tripDate: DateTime.parse(map['trip_date'] as String),
      location: map['location'] as String,
      description: map['description'] as String?,
      observationCount: map['observation_count'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Converts Trip to SQLite database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'trip_date': tripDate.toIso8601String(),
      'location': location,
      'description': description,
      'observation_count': observationCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Creates a copy of this Trip with the given fields replaced
  Trip copyWith({
    String? id,
    String? userId,
    String? name,
    DateTime? tripDate,
    String? location,
    String? description,
    int? observationCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Trip(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      tripDate: tripDate ?? this.tripDate,
      location: location ?? this.location,
      description: description ?? this.description,
      observationCount: observationCount ?? this.observationCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Trip &&
        other.id == id &&
        other.userId == userId &&
        other.name == name &&
        other.tripDate == tripDate &&
        other.location == location &&
        other.description == description &&
        other.observationCount == observationCount &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      name,
      tripDate,
      location,
      description,
      observationCount,
      createdAt,
      updatedAt,
    );
  }

  @override
  String toString() {
    return 'Trip(id: $id, userId: $userId, name: $name, tripDate: $tripDate, '
        'location: $location, description: $description, '
        'observationCount: $observationCount, createdAt: $createdAt, '
        'updatedAt: $updatedAt)';
  }
}
