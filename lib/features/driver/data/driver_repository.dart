import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/driver_model.dart';

class DriverRepository {
  static const _emailCacheKey = 'driver_email_cache';
  static const _createDriverFunction = 'create-driver';
  final _client = Supabase.instance.client;

  Future<Map<String, String>> _loadEmailCache() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_emailCacheKey);
    if (raw == null || raw.isEmpty) return {};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((key, value) => MapEntry(key, value as String));
  }

  Future<void> _saveEmailCache(Map<String, String> cache) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_emailCacheKey, jsonEncode(cache));
  }

  Future<void> _cacheEmail(String id, String email) async {
    final cache = await _loadEmailCache();
    cache[id] = email;
    await _saveEmailCache(cache);
  }

  Future<void> _removeCachedEmail(String id) async {
    final cache = await _loadEmailCache();
    cache.remove(id);
    await _saveEmailCache(cache);
  }

  Future<List<DriverModel>> getAll() async {
    final emailCache = await _loadEmailCache();
    final data = await _client
        .from('pengguna')
        .select('id, nama_lengkap, peran')
        .eq('peran', 'driver')
        .order('nama_lengkap');

    return (data as List).map((row) {
      final id = row['id'] as String;
      return DriverModel(
        id: id,
        nama: (row['nama_lengkap'] as String?) ?? '-',
        email: emailCache[id] ?? '',
      );
    }).toList();
  }

  Future<DriverModel?> getById(String id) async {
    final data = await _client
        .from('pengguna')
        .select('id, nama_lengkap, peran')
        .eq('id', id)
        .eq('peran', 'driver')
        .maybeSingle();

    if (data == null) return null;

    final emailCache = await _loadEmailCache();
    return DriverModel(
      id: data['id'] as String,
      nama: (data['nama_lengkap'] as String?) ?? '-',
      email: emailCache[id] ?? '',
    );
  }

  /// Mendaftarkan driver via Edge Function (jika ada) atau signUp.
  Future<DriverModel> create({
    required String nama,
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedNama = nama.trim();

    final viaEdge = await _tryCreateViaEdgeFunction(
      nama: normalizedNama,
      email: normalizedEmail,
      password: password,
    );
    if (viaEdge != null) return viaEdge;

    return _createViaSignUp(
      nama: normalizedNama,
      email: normalizedEmail,
      password: password,
    );
  }

  Future<DriverModel?> _tryCreateViaEdgeFunction({
    required String nama,
    required String email,
    required String password,
  }) async {
    try {
      return await _createViaEdgeFunction(
        nama: nama,
        email: email,
        password: password,
      );
    } on FunctionException catch (e) {
      if (_shouldFallbackToSignUp(e)) return null;
      throw AuthException(_extractFunctionError(e));
    } on AuthException catch (e) {
      if (_isEdgeFunctionUnavailable(e.message)) return null;
      rethrow;
    } catch (_) {
      return null;
    }
  }

  bool _shouldFallbackToSignUp(FunctionException e) {
    final status = e.status;
    return status == 404 || status == 502 || status == 503;
  }

  bool _isEdgeFunctionUnavailable(String message) {
    final lower = message.toLowerCase();
    return lower.contains('404') ||
        lower.contains('not found') ||
        lower.contains('function not found');
  }

  String _extractFunctionError(FunctionException e) {
    final details = e.details;
    if (details is Map && details['error'] is String) {
      return details['error'] as String;
    }
    if (details is String && details.isNotEmpty) {
      try {
        final decoded = jsonDecode(details) as Map<String, dynamic>;
        if (decoded['error'] is String) return decoded['error'] as String;
      } catch (_) {
        return details;
      }
    }
    return e.reasonPhrase ?? 'Gagal membuat akun driver.';
  }

  Future<DriverModel> _createViaEdgeFunction({
    required String nama,
    required String email,
    required String password,
  }) async {
    final response = await _client.functions.invoke(
      _createDriverFunction,
      body: {
        'nama': nama,
        'email': email,
        'password': password,
      },
    );

    final status = response.status;
    final data = response.data;

    if (status != 200) {
      if (data is Map && data['error'] is String) {
        throw AuthException(data['error'] as String);
      }
      throw AuthException('Gagal membuat akun driver (HTTP $status).');
    }

    if (data is! Map) {
      throw const AuthException('Respons server tidak valid.');
    }

    final id = data['id'] as String?;
    if (id == null || id.isEmpty) {
      throw const AuthException('Gagal membuat akun driver.');
    }

    await _cacheEmail(id, email);
    return DriverModel(
      id: id,
      nama: (data['nama'] as String?) ?? nama,
      email: (data['email'] as String?) ?? email,
    );
  }

  Future<DriverModel> _createViaSignUp({
    required String nama,
    required String email,
    required String password,
  }) async {
    final adminSession = _client.auth.currentSession;
    if (adminSession == null) {
      throw const AuthException('Sesi admin tidak valid. Silakan login ulang.');
    }

    final adminRefreshToken = adminSession.refreshToken;
    if (adminRefreshToken == null || adminRefreshToken.isEmpty) {
      throw const AuthException(
        'Sesi admin tidak valid. Silakan login ulang.',
      );
    }

    AuthResponse signUpResponse;
    try {
      signUpResponse = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'nama_lengkap': nama,
          'peran': 'driver',
        },
      );
    } on AuthException catch (e) {
      throw AuthException(_mapSignUpError(e.message));
    }

    final user = signUpResponse.user;
    if (user == null) {
      throw const AuthException('Gagal mendaftarkan akun driver.');
    }

    if (signUpResponse.session == null) {
      throw const AuthException(
        'Akun driver dibuat tetapi belum bisa login. '
        'Pastikan "Confirm email" sudah dinonaktifkan di Supabase Auth.',
      );
    }

    try {
      await _client.auth.setSession(adminRefreshToken);
    } on AuthException {
      throw const AuthException(
        'Akun driver dibuat, tetapi sesi admin terputus. '
        'Silakan login ulang sebagai superadmin.',
      );
    }

    await _ensurePenggunaProfile(userId: user.id, nama: nama);
    await _cacheEmail(user.id, email);

    return DriverModel(id: user.id, nama: nama, email: email);
  }

  Future<void> _ensurePenggunaProfile({
    required String userId,
    required String nama,
  }) async {
    try {
      final existing = await _client
          .from('pengguna')
          .select('id')
          .eq('id', userId)
          .maybeSingle();

      if (existing != null) return;

      await _client.from('pengguna').insert({
        'id': userId,
        'nama_lengkap': nama,
        'peran': 'driver',
        'aktif': true,
      });
    } on PostgrestException catch (e) {
      if (e.code == '23505') return;
      throw AuthException(
        'Akun auth dibuat, tetapi profil driver gagal disimpan: ${e.message}. '
        'Jalankan migrasi SQL di supabase/migrations/20240630_driver_auth_setup.sql.',
      );
    }
  }

  String _mapSignUpError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('already registered') ||
        lower.contains('already been registered')) {
      return 'Email sudah terdaftar.';
    }
    if (lower.contains('password')) {
      return 'Password tidak memenuhi persyaratan Supabase.';
    }
    return message;
  }

  Future<DriverModel> update({
    required String id,
    required String nama,
    required String email,
  }) async {
    await _client.from('pengguna').update({
      'nama_lengkap': nama,
    }).eq('id', id).eq('peran', 'driver');

    await _cacheEmail(id, email.trim().toLowerCase());
    return DriverModel(id: id, nama: nama, email: email.trim().toLowerCase());
  }

  Future<void> delete(String id) async {
    await _client.from('pengguna').delete().eq('id', id).eq('peran', 'driver');
    await _removeCachedEmail(id);
  }
}
