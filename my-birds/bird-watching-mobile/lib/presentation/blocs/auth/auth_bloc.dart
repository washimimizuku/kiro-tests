import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// BLoC for managing authentication state
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc({
    required AuthRepository authRepository,
  })  : _authRepository = authRepository,
        super(const AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<TokenExpired>(_onTokenExpired);
    on<CheckAuthStatus>(_onCheckAuthStatus);
  }

  /// Handle login request
  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      print('[AuthBloc] Attempting login for user: ${event.username}');
      
      final loginResponse = await _authRepository.login(
        event.username,
        event.password,
      );

      print('[AuthBloc] Login successful for user: ${event.username}');
      
      emit(Authenticated(
        user: loginResponse.user,
        token: loginResponse.token,
      ));
    } catch (e) {
      print('[AuthBloc] Login failed: $e');
      emit(AuthError(e.toString()));
      
      // Return to unauthenticated state after error
      emit(const Unauthenticated());
    }
  }

  /// Handle registration request
  Future<void> _onRegisterRequested(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      print('[AuthBloc] Attempting registration for user: ${event.username}');
      
      final user = await _authRepository.register(
        event.username,
        event.email,
        event.password,
      );

      // Get the stored token (registration auto-logs in)
      final token = await _authRepository.getStoredToken();
      
      if (token == null) {
        throw Exception('Registration succeeded but token not found');
      }

      print('[AuthBloc] Registration successful for user: ${event.username}');
      
      emit(Authenticated(
        user: user,
        token: token,
      ));
    } catch (e) {
      print('[AuthBloc] Registration failed: $e');
      emit(AuthError(e.toString()));
      
      // Return to unauthenticated state after error
      emit(const Unauthenticated());
    }
  }

  /// Handle logout request
  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      print('[AuthBloc] Logging out user');
      
      await _authRepository.logout();
      
      print('[AuthBloc] Logout successful');
      emit(const Unauthenticated());
    } catch (e) {
      print('[AuthBloc] Logout failed: $e');
      // Still emit unauthenticated even if logout fails
      emit(const Unauthenticated());
    }
  }

  /// Handle token expiration
  Future<void> _onTokenExpired(
    TokenExpired event,
    Emitter<AuthState> emit,
  ) async {
    print('[AuthBloc] Token expired, clearing credentials');
    
    try {
      await _authRepository.logout();
    } catch (e) {
      print('[AuthBloc] Error clearing expired token: $e');
    }
    
    emit(const Unauthenticated());
  }

  /// Check authentication status on app start
  Future<void> _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      print('[AuthBloc] Checking authentication status');
      
      final user = await _authRepository.getCurrentUser();
      
      if (user != null) {
        final token = await _authRepository.getStoredToken();
        
        if (token != null) {
          print('[AuthBloc] User is authenticated: ${user.username}');
          emit(Authenticated(user: user, token: token));
          return;
        }
      }
      
      print('[AuthBloc] User is not authenticated');
      emit(const Unauthenticated());
    } catch (e) {
      print('[AuthBloc] Error checking auth status: $e');
      emit(const Unauthenticated());
    }
  }
}
