import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/auth_model.dart';

class AuthRepository {
  final _client = Supabase.instance.client;

  Future<User> login(String email, String password) async {
    final response = await _client.auth.signInWithPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );
    if (response.session == null || response.user == null) {
      throw const AuthException('Login gagal. Periksa email dan kata sandi.');
    }

    try {
      await _client.auth.refreshSession();
    } catch (_) {}

    return _client.auth.currentUser ?? response.user!;
  }

  Future<void> logout() async {
    await _client.auth.signOut();
  }

  Future<UserModel?> fetchUserProfile() async {
    final authUser = _client.auth.currentUser;
    if (authUser == null) return null;

    for (var i = 0; i < 2; i++) {
      final user = i == 0 ? authUser : (_client.auth.currentUser ?? authUser);

      final fromRpc = await _fetchViaRpc(user);
      if (fromRpc != null) return fromRpc;

      final fromTable = await _fetchFromTable(user);
      if (fromTable != null) return fromTable;

      final fromMeta = _userFromAuth(user);
      if (fromMeta != null) return fromMeta;

      if (i == 0) {
        try {
          await _client.auth.refreshSession();
        } catch (_) {}
      }
    }

    return null;
  }

  Future<UserModel?> _fetchViaRpc(User authUser) async {
    try {
      final data = await _client.rpc('get_my_profile');
      if (data == null) return null;
      final map = Map<String, dynamic>.from(data as Map);
      final peran = map['peran']?.toString();
      if (peran == null || peran.isEmpty) return null;
      return _toUserModel(map, authUser);
    } catch (_) {
      return null;
    }
  }

  Future<UserModel?> _fetchFromTable(User authUser) async {
    try {
      final data = await _client
          .from('pengguna')
          .select('id, nama_lengkap, peran, aktif')
          .eq('id', authUser.id)
          .maybeSingle();

      if (data == null) return null;

      final peran = data['peran']?.toString();
      if (peran == null || peran.isEmpty) return null;

      return _toUserModel(data, authUser);
    } catch (_) {
      return null;
    }
  }

  UserModel _toUserModel(Map<String, dynamic> data, User authUser) {
    final email = authUser.email ?? data['email']?.toString() ?? '';
    data['email'] = email;
    data['nama_lengkap'] = _resolveName(data, authUser);
    return UserModel.fromJson(data);
  }

  String _resolveName(Map<String, dynamic> data, User authUser) {
    final meta = authUser.userMetadata ?? {};
    final email = authUser.email ?? data['email']?.toString() ?? '';

    final candidates = [
      meta['nama_lengkap'],
      meta['name'],
      meta['full_name'],
      meta['display_name'],
      data['nama_lengkap'],
      data['name'],
      email.isNotEmpty ? email.split('@').first : null,
    ];

    for (final c in candidates) {
      final s = c?.toString().trim();
      if (s != null && s.isNotEmpty) return s;
    }
    return 'Pengguna';
  }

  bool get hasActiveSession => _client.auth.currentSession != null;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  UserModel? _userFromAuth(User authUser) {
    final meta = authUser.userMetadata ?? {};
    final appMeta = authUser.appMetadata;
    final role =
        (meta['peran'] ?? appMeta['peran'] ?? appMeta['role'])?.toString();

    if (role == null || role.isEmpty) return null;

    return UserModel(
      id: authUser.id,
      name: _resolveName({}, authUser),
      email: authUser.email ?? '',
      role: role,
    );
  }
}
