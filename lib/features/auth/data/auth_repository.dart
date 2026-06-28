import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/auth_model.dart';

class AuthRepository {
  final _client = Supabase.instance.client;

  Future<AuthResponse> login(String email, String password) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    if (response.session == null || response.user == null) {
      throw const AuthException('Login gagal. Periksa email dan kata sandi.');
    }
    return response;
  }

  Future<void> logout() async {
    await _client.auth.signOut();
  }

  // ← Diperbaiki: nama tabel 'pengguna' sesuai schema database kita
  Future<UserModel?> fetchUserProfile() async {
    final authUser = _client.auth.currentUser;
    if (authUser == null) return null;

    try {
      final data = await _client
          .from('pengguna')
          .select('id, nama_lengkap, peran, aktif')
          .eq('id', authUser.id)
          .maybeSingle();

      if (data != null) {
        // Email ada di Supabase Auth, bukan di tabel pengguna
        data['email'] = authUser.email ?? '';
        return UserModel.fromJson(data);
      }
      return _userFromAuth(authUser);
    } catch (_) {
      return _userFromAuth(authUser);
    }
  }

  bool get hasActiveSession => _client.auth.currentSession != null;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  UserModel _userFromAuth(User authUser) {
    return UserModel(
      id:    authUser.id,
      name:  authUser.userMetadata?['nama_lengkap'] ??
             authUser.email?.split('@').first ?? 'Pengguna',
      email: authUser.email ?? '',
      role:  authUser.userMetadata?['peran'] ?? 'driver',
    );
  }
}