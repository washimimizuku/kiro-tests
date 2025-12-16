/// User model representing a registered user in the bird watching app
class User {
  final String id;
  final String username;
  final String email;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.username,
    required this.email,
    required this.createdAt,
  });

  /// Creates a User from JSON data
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Converts User to JSON format
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Creates a copy of this User with the given fields replaced
  User copyWith({
    String? id,
    String? username,
    String? email,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User &&
        other.id == id &&
        other.username == username &&
        other.email == email &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(id, username, email, createdAt);
  }

  @override
  String toString() {
    return 'User(id: $id, username: $username, email: $email, createdAt: $createdAt)';
  }
}
