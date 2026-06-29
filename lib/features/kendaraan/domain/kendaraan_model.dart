class KendaraanModel {
  final String id;
  final String tipe;
  final String merk;
  final String model;
  final String tahun;
  final String nomorPlat;

  const KendaraanModel({
    required this.id,
    required this.tipe,
    required this.merk,
    required this.model,
    required this.tahun,
    required this.nomorPlat,
  });

  String get label => '$merk $model ($nomorPlat)';

  KendaraanModel copyWith({
    String? id,
    String? tipe,
    String? merk,
    String? model,
    String? tahun,
    String? nomorPlat,
  }) {
    return KendaraanModel(
      id: id ?? this.id,
      tipe: tipe ?? this.tipe,
      merk: merk ?? this.merk,
      model: model ?? this.model,
      tahun: tahun ?? this.tahun,
      nomorPlat: nomorPlat ?? this.nomorPlat,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'tipe': tipe,
        'merk': merk,
        'model': model,
        'tahun': tahun,
        'nomor_plat': nomorPlat,
      };

  factory KendaraanModel.fromJson(Map<String, dynamic> json) {
    return KendaraanModel(
      id: json['id'] as String,
      tipe: json['tipe'] as String? ?? 'Mobil',
      merk: json['merk'] as String,
      model: json['model'] as String,
      tahun: json['tahun'] as String,
      nomorPlat: json['nomor_plat'] as String,
    );
  }
}
