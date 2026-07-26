class UserModel {
  final String id;
  final String name;      // dari kolom: nama_lengkap
  final String email;     // dari Supabase Auth
  final String role;      // dari kolom: peran
  final String? avatarUrl;
  final bool aktif;        // dari kolom: aktif (soft-delete flag)

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.avatarUrl,
    this.aktif = true,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id:        json['id']           as String,
      name:      (json['nama_lengkap'] ?? json['name'] ?? 'Pengguna') as String,
      email:     (json['email']        ?? '') as String,
      role:      (json['peran']        ?? json['role'] ?? 'driver') as String,
      avatarUrl: json['avatar_url']    as String?,
      aktif:     (json['aktif'] as bool?) ?? true,
    );
  }

  /// Nama tampilan: prioritas name → prefix email → fallback.
  String get displayName {
    final n = name.trim();
    if (n.isNotEmpty &&
        n.toLowerCase() != 'pengguna' &&
        n.toLowerCase() != 'pengguna baru') {
      return n;
    }
    final e = email.trim();
    if (e.contains('@')) {
      final local = e.split('@').first.trim();
      if (local.isNotEmpty) return local;
    }
    return n.isNotEmpty ? n : 'Pengguna';
  }

  String get peranLabel {
    switch (role) {
      case 'admin':      return 'Administrator';
      case 'superadmin': return 'Super Admin';
      case 'driver':     return 'Driver';
      case 'karyawan':   return 'Karyawan';
      default:           return role;
    }
  }
}