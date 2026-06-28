class UserModel {
  final String id;
  final String name;      // dari kolom: nama_lengkap
  final String email;     // dari Supabase Auth
  final String role;      // dari kolom: peran
  final String? avatarUrl;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.avatarUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id:        json['id']           as String,
      // DB pakai 'nama_lengkap', fallback ke 'name' untuk kompatibilitas
      name:      (json['nama_lengkap'] ?? json['name'] ?? 'Pengguna') as String,
      email:     (json['email']        ?? '') as String,
      // DB pakai 'peran', fallback ke 'role'
      role:      (json['peran']        ?? json['role'] ?? 'driver') as String,
      avatarUrl: json['avatar_url']    as String?,
    );
  }

  String get peranLabel {
    switch (role) {
      case 'admin':      return 'Administrator';
      case 'supervisor': return 'Supervisor';
      case 'driver':     return 'Driver';
      case 'karyawan':   return 'Karyawan';
      default:           return role;
    }
  }
}