import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:bird_watching_mobile/presentation/blocs/auth/auth.dart';
import 'package:bird_watching_mobile/data/repositories/auth_repository.dart';
import 'package:bird_watching_mobile/data/models/user.dart';

import 'auth_bloc_test.mocks.dart';

@GenerateMocks([AuthRepository])
void main() {
  late MockAuthRepository mockAuthRepository;
  late AuthBloc authBloc;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    authBloc = AuthBloc(authRepository: mockAuthRepository);
  });

  tearDown(() {
    authBloc.close();
  });

  group('AuthBloc', () {
    final testUser = User(
      id: 'test-id',
      username: 'testuser',
      email: 'test@example.com',
      createdAt: DateTime.now(),
    );

    final testLoginResponse = LoginResponse(
      user: testUser,
      token: 'test-token',
    );

    test('initial state is AuthInitial', () {
      expect(authBloc.state, equals(const AuthInitial()));
    });

    group('LoginRequested', () {
      test('emits [AuthLoading, Authenticated] when login succeeds', () async {
        // Arrange
        when(mockAuthRepository.login('testuser', 'password'))
            .thenAnswer((_) async => testLoginResponse);

        // Assert
        expectLater(
          authBloc.stream,
          emitsInOrder([
            const AuthLoading(),
            Authenticated(user: testUser, token: 'test-token'),
          ]),
        );

        // Act
        authBloc.add(const LoginRequested(
          username: 'testuser',
          password: 'password',
        ));
      });

      test('emits [AuthLoading, AuthError, Unauthenticated] when login fails',
          () async {
        // Arrange
        when(mockAuthRepository.login('testuser', 'wrongpassword'))
            .thenThrow(Exception('Invalid credentials'));

        // Assert
        expectLater(
          authBloc.stream,
          emitsInOrder([
            const AuthLoading(),
            isA<AuthError>(),
            const Unauthenticated(),
          ]),
        );

        // Act
        authBloc.add(const LoginRequested(
          username: 'testuser',
          password: 'wrongpassword',
        ));
      });
    });

    group('RegisterRequested', () {
      test('emits [AuthLoading, Authenticated] when registration succeeds',
          () async {
        // Arrange
        when(mockAuthRepository.register('newuser', 'new@example.com', 'password'))
            .thenAnswer((_) async => testUser);
        when(mockAuthRepository.getStoredToken())
            .thenAnswer((_) async => 'test-token');

        // Assert
        expectLater(
          authBloc.stream,
          emitsInOrder([
            const AuthLoading(),
            Authenticated(user: testUser, token: 'test-token'),
          ]),
        );

        // Act
        authBloc.add(const RegisterRequested(
          username: 'newuser',
          email: 'new@example.com',
          password: 'password',
        ));
      });

      test('emits [AuthLoading, AuthError, Unauthenticated] when registration fails',
          () async {
        // Arrange
        when(mockAuthRepository.register('existinguser', 'existing@example.com', 'password'))
            .thenThrow(Exception('Username already exists'));

        // Assert
        expectLater(
          authBloc.stream,
          emitsInOrder([
            const AuthLoading(),
            isA<AuthError>(),
            const Unauthenticated(),
          ]),
        );

        // Act
        authBloc.add(const RegisterRequested(
          username: 'existinguser',
          email: 'existing@example.com',
          password: 'password',
        ));
      });
    });

    group('LogoutRequested', () {
      test('emits [Unauthenticated] when logout succeeds', () async {
        // Arrange
        when(mockAuthRepository.logout()).thenAnswer((_) async => {});

        // Assert
        expectLater(
          authBloc.stream,
          emits(const Unauthenticated()),
        );

        // Act
        authBloc.add(const LogoutRequested());
      });

      test('emits [Unauthenticated] even when logout fails', () async {
        // Arrange
        when(mockAuthRepository.logout()).thenThrow(Exception('Logout error'));

        // Assert
        expectLater(
          authBloc.stream,
          emits(const Unauthenticated()),
        );

        // Act
        authBloc.add(const LogoutRequested());
      });
    });

    group('TokenExpired', () {
      test('emits [Unauthenticated] and clears credentials', () async {
        // Arrange
        when(mockAuthRepository.logout()).thenAnswer((_) async => {});

        // Assert
        expectLater(
          authBloc.stream,
          emits(const Unauthenticated()),
        );

        // Act
        authBloc.add(const TokenExpired());

        // Verify logout was called
        await Future.delayed(const Duration(milliseconds: 100));
        verify(mockAuthRepository.logout()).called(1);
      });
    });

    group('CheckAuthStatus', () {
      test('emits [AuthLoading, Authenticated] when user is authenticated',
          () async {
        // Arrange
        when(mockAuthRepository.getCurrentUser())
            .thenAnswer((_) async => testUser);
        when(mockAuthRepository.getStoredToken())
            .thenAnswer((_) async => 'test-token');

        // Assert
        expectLater(
          authBloc.stream,
          emitsInOrder([
            const AuthLoading(),
            Authenticated(user: testUser, token: 'test-token'),
          ]),
        );

        // Act
        authBloc.add(const CheckAuthStatus());
      });

      test('emits [AuthLoading, Unauthenticated] when user is not authenticated',
          () async {
        // Arrange
        when(mockAuthRepository.getCurrentUser()).thenAnswer((_) async => null);

        // Assert
        expectLater(
          authBloc.stream,
          emitsInOrder([
            const AuthLoading(),
            const Unauthenticated(),
          ]),
        );

        // Act
        authBloc.add(const CheckAuthStatus());
      });
    });
  });
}
