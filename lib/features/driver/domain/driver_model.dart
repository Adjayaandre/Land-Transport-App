class DriverModel {
  final String id;
  final String nama;
  final String email;
  final String peran;
  final bool aktif;

  const DriverModel({
    required this.id,
    required this.nama,
    required this.email,
    required this.peran,
    required this.aktif,
  });

  String get peranLabel {
    switch (peran) {
      case 'superadmin': return 'Super Admin';
      case 'admin':      return 'Admin';
      case 'supervisor': return 'Supervisor';
      case 'driver':     return 'Driver';
      case 'karyawan':   return 'Karyawan';
      default:           return peran;
    }
  }

  DriverModel copyWith({
    String? id,
    String? nama,
    String? email,
    String? peran,
    bool? aktif,
  }) {
    return DriverModel(
      id:    id    ?? this.id,
      nama:  nama  ?? this.nama,
      email: email ?? this.email,
      peran: peran ?? this.peran,
      aktif: aktif ?? this.aktif,
    );
  }

  Map<String, dynamic> toJson() => {
        'id':    id,
        'nama_lengkap': nama,
        'email': email,
        'peran': peran,
        'aktif': aktif,
      };

  factory DriverModel.fromJson(Map<String, dynamic> json) {
    return DriverModel(
      id:    json['id']            as String,
      nama:  (json['nama_lengkap'] ?? json['nama'] ?? '-') as String,
      email: (json['email']        ?? '') as String,
      peran: (json['peran']        ?? 'driver') as String,
      aktif: (json['aktif']        ?? true) as bool,
    );
  }
}