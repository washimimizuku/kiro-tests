import 'package:equatable/equatable.dart';

/// Base class for authentication events
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Event to request login
class LoginRequested extends AuthEvent {
  final String username;
  final String password;
  final bool rememberMe;

  const LoginRequested({
    required this.username,
    required this.password,
    this.rememberMe = false,
  });

  @override
  List<Object?> get props => [username, password, rememberMe];

  @override
  String toString() => 'LoginRequested(username: $username, rememberMe: $rememberMe)';
}

/// Event to request registration
class RegisterRequested extends AuthEvent {
  final String username;
  final String email;
  final String password;

  const RegisterRequested({
    required this.username,
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [username, email, password];

  @override
  String toString() => 'RegisterRequested(username: $username, email: $email)';
}

/// Event to request logout
class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}

/// Event when token expires
class TokenExpired extends AuthEvent {
  const TokenExpired();
}

/// Event to check authentication status on app start
class CheckAuthStatus extends AuthEvent {
  const CheckAuthStatus();
}
