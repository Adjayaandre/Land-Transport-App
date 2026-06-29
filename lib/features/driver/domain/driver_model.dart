class DriverModel {
  final String id;
  final String nama;
  final String email;

  const DriverModel({
    required this.id,
    required this.nama,
    required this.email,
  });

  DriverModel copyWith({
    String? id,
    String? nama,
    String? email,
  }) {
    return DriverModel(
      id: id ?? this.id,
      nama: nama ?? this.nama,
      email: email ?? this.email,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nama': nama,
        'email': email,
      };

  factory DriverModel.fromJson(Map<String, dynamic> json) {
    return DriverModel(
      id: json['id'] as String,
      nama: json['nama'] as String,
      email: json['email'] as String,
    );
  }
}
