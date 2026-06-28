import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../data/auth_repository.dart';
import 'auth_state.dart';

/// Provider untuk AuthRepository (singleton)
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Provider utama untuk state autentikasi
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository);
});

/// StateNotifier yang mengelola state autentikasi
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  StreamSubscription<supabase.AuthState>? _authSubscription;

  AuthNotifier(this._repository) : super(const AuthState.initial()) {
    _authSubscription = _repository.authStateChanges.listen((event) async {
      if (event.event == supabase.AuthChangeEvent.signedOut) {
        state = const AuthState.unauthenticated();
        return;
      }

      if (event.session != null &&
          (event.event == supabase.AuthChangeEvent.signedIn ||
              event.event == supabase.AuthChangeEvent.tokenRefreshed ||
              event.event == supabase.AuthChangeEvent.initialSession)) {
        await _loadCurrentUser();
      }
    });
  }

  /// Cek status autentikasi saat ini (digunakan saat splash screen)
  Future<void> checkAuthStatus() async {
    state = const AuthState.loading();

    try {
      // Delay sedikit agar splash screen terlihat
      await Future.delayed(const Duration(milliseconds: 1500));

      if (_repository.hasActiveSession) {
        await _loadCurrentUser();
      } else {
        state = const AuthState.unauthenticated();
      }
    } catch (e) {
      state = const AuthState.unauthenticated();
    }
  }

  /// Login dengan email dan password
  Future<void> login(String email, String password) async {
    state = const AuthState.loading();

    try {
      await _repository.login(email, password);
      await _loadCurrentUser();
    } catch (e) {
      // Tangkap error spesifik dari Supabase
      String message = 'Terjadi kesalahan. Silakan coba lagi.';

      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('invalid login credentials') ||
          errorStr.contains('invalid_credentials')) {
        message = 'Email atau kata sandi salah.';
      } else if (errorStr.contains('email not confirmed')) {
        message = 'Email belum dikonfirmasi. Cek inbox Anda.';
      } else if (errorStr.contains('too many requests') ||
          errorStr.contains('rate limit')) {
        message = 'Terlalu banyak percobaan. Coba lagi nanti.';
      } else if (errorStr.contains('network') ||
          errorStr.contains('socket') ||
          errorStr.contains('connection')) {
        message = 'Tidak ada koneksi internet.';
      }

      state = AuthState.error(message);
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      await _repository.logout();
    } catch (_) {
      // Tetap logout meskipun gagal di server
    }
    state = const AuthState.unauthenticated();
  }

  /// Reset error state kembali ke unauthenticated
  void clearError() {
    if (state.status == AuthStatus.error) {
      state = const AuthState.unauthenticated();
    }
  }

  Future<void> _loadCurrentUser() async {
    final user = await _repository.fetchUserProfile();
    if (user != null) {
      state = AuthState.authenticated(user);
    } else {
      state = const AuthState.unauthenticated();
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
