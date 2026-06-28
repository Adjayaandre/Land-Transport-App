import 'auth_model.dart';

enum AuthStatus {
  initial,          // Pertama kali app dibuka
  loading,          // Sedang cek sesi / proses login
  authenticated,    // Sudah login
  unauthenticated,  // Belum login
  error,            // Terjadi error
}

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;

  const AuthState._({
    required this.status,
    this.user,
    this.errorMessage,
  });

  const AuthState.initial()
      : this._(status: AuthStatus.initial);

  const AuthState.loading()
      : this._(status: AuthStatus.loading);

  const AuthState.authenticated(UserModel user)
      : this._(status: AuthStatus.authenticated, user: user);

  const AuthState.unauthenticated()
      : this._(status: AuthStatus.unauthenticated);

  AuthState.error(String message)
      : this._(status: AuthStatus.error, errorMessage: message);

  bool get isLoading       => status == AuthStatus.loading;
  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isInitial       => status == AuthStatus.initial;
}