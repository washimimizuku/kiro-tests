import 'package:equatable/equatable.dart';
import '../../../data/models/user.dart';

/// Base class for authentication states
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state when the app starts
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// State when authentication is in progress
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// State when user is authenticated
class Authenticated extends AuthState {
  final User user;
  final String token;

  const Authenticated({
    required this.user,
    required this.token,
  });

  @override
  List<Object?> get props => [user, token];

  @override
  String toString() => 'Authenticated(user: ${user.username}, token: ${token.substring(0, 10)}...)';
}

/// State when user is not authenticated
class Unauthenticated extends AuthState {
  const Unauthenticated();
}

/// State when authentication error occurs
class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];

  @override
  String toString() => 'AuthError(message: $message)';
}
