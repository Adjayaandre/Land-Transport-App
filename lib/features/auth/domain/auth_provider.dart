import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../data/auth_repository.dart';
import 'auth_state.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository);
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  StreamSubscription<supabase.AuthState>? _authSubscription;
  bool _isLoggingIn = false;
  bool _suppressNextSignedOut = false;

  AuthNotifier(this._repository) : super(const AuthState.initial()) {
    _authSubscription = _repository.authStateChanges.listen((event) async {
      if (_isLoggingIn) return;

      if (event.event == supabase.AuthChangeEvent.signedOut) {
        if (_suppressNextSignedOut) {
          _suppressNextSignedOut = false;
          return;
        }
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

  Future<void> checkAuthStatus() async {
    state = const AuthState.loading();

    try {
      await Future.delayed(const Duration(milliseconds: 1500));

      if (_repository.hasActiveSession) {
        await _loadCurrentUser();
      } else {
        state = const AuthState.unauthenticated();
      }
    } catch (_) {
      state = const AuthState.unauthenticated();
    }
  }

  Future<void> login(String email, String password) async {
    _isLoggingIn = true;
    state = const AuthState.loading();

    try {
      await _repository.login(email, password);
      await _loadCurrentUser(notifyProfileMissing: true);
    } catch (e) {
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
    } finally {
      _isLoggingIn = false;
    }
  }

  Future<void> refreshProfile() async {
    if (_repository.hasActiveSession) {
      await _loadCurrentUser();
    }
  }

  Future<void> logout() async {
    try {
      await _repository.logout();
    } catch (_) {}
    state = const AuthState.unauthenticated();
  }

  /// Logout paksa dengan pesan khusus, dipakai saat akun tidak diizinkan
  /// mengakses platform tertentu (misal driver mencoba akses web).
  Future<void> logoutWithMessage(String message) async {
    _suppressNextSignedOut = true;
    try {
      await _repository.logout();
    } catch (_) {}
    state = AuthState.error(message);
  }

  void clearError() {
    if (state.status == AuthStatus.error) {
      state = const AuthState.unauthenticated();
    }
  }

  Future<void> _loadCurrentUser({bool notifyProfileMissing = false}) async {
    if (!_repository.hasActiveSession) {
      state = const AuthState.unauthenticated();
      return;
    }

    final user = await _repository.fetchUserProfile();
    if (user != null) {
      // Mengizinkan semua role saat ini agar bisa dites di web
      const allowedWebRoles = {'admin', 'superadmin', 'driver', 'karyawan'};
      if (kIsWeb && !allowedWebRoles.contains(user.role)) {
        _suppressNextSignedOut = true;
        try {
          await _repository.logout();
        } catch (_) {}
        state = AuthState.error(
          'Akun dengan peran "${user.peranLabel}" hanya dapat digunakan '
          'melalui aplikasi mobile. Silakan login menggunakan aplikasi HP Anda.',
        );
        return;
      }
      state = AuthState.authenticated(user);
      return;
    }

    if (notifyProfileMissing) {
      state = AuthState.error(
        'Login berhasil, tetapi profil tidak ditemukan. '
        'Jalankan SQL sync superadmin di Supabase, lalu login ulang.',
      );
      return;
    }

    state = const AuthState.unauthenticated();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}