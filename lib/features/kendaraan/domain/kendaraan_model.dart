class KendaraanModel {
  final String id;
  final String nomorPlat;
  final String merek;
  final String model;
  final String? warna;
  final double odometerSekarang;
  final bool aktif;
  final String? keterangan;

  const KendaraanModel({
    required this.id,
    required this.nomorPlat,
    required this.merek,
    required this.model,
    this.warna,
    required this.odometerSekarang,
    required this.aktif,
    this.keterangan,
  });

  String get label => '$merek $model ($nomorPlat)';

  KendaraanModel copyWith({
    String? id,
    String? nomorPlat,
    String? merek,
    String? model,
    String? warna,
    double? odometerSekarang,
    bool? aktif,
    String? keterangan,
  }) {
    return KendaraanModel(
      id: id ?? this.id,
      nomorPlat: nomorPlat ?? this.nomorPlat,
      merek: merek ?? this.merek,
      model: model ?? this.model,
      warna: warna ?? this.warna,
      odometerSekarang: odometerSekarang ?? this.odometerSekarang,
      aktif: aktif ?? this.aktif,
      keterangan: keterangan ?? this.keterangan,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nomor_polisi': nomorPlat,
        'merek': merek,
        'model': model,
        if (warna != null) 'warna': warna,
        'odometer_sekarang': odometerSekarang,
        'aktif': aktif,
        if (keterangan != null) 'keterangan': keterangan,
      };

  factory KendaraanModel.fromJson(Map<String, dynamic> json) {
    return KendaraanModel(
      id:               json['id']                as String,
      nomorPlat:        json['nomor_polisi']       as String? ?? '-',
      merek:            json['merek']              as String? ?? '-',
      model:            json['model']              as String? ?? '-',
      warna:            json['warna']              as String?,
      odometerSekarang: (json['odometer_sekarang'] as num?)?.toDouble() ?? 0,
      aktif:            json['aktif']              as bool? ?? true,
      keterangan:       json['keterangan']         as String?,
    );
  }
}