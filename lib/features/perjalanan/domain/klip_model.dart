class KlipPerjalanan {
  final String id;
  final String idKendaraan;
  final String? dibuat_oleh;
  final String status; // 'aktif' | 'tutup'
  final double? odometerTutup;
  final String? fotoNotaUrl;
  final String? fotoNotaPath;
  final DateTime dibuatPada;
  final DateTime? ditutupPada;

  const KlipPerjalanan({
    required this.id,
    required this.idKendaraan,
    this.dibuat_oleh,
    required this.status,
    this.odometerTutup,
    this.fotoNotaUrl,
    this.fotoNotaPath,
    required this.dibuatPada,
    this.ditutupPada,
  });

  bool get isAktif => status == 'aktif';

  factory KlipPerjalanan.fromJson(Map<String, dynamic> j) => KlipPerjalanan(
        id:            j['id']             as String,
        idKendaraan:   j['id_kendaraan']   as String,
        dibuat_oleh:   j['dibuat_oleh']    as String?,
        status:        j['status']         as String? ?? 'aktif',
        odometerTutup: (j['odometer_tutup'] as num?)?.toDouble(),
        fotoNotaUrl:   j['foto_nota_url']  as String?,
        fotoNotaPath:  j['foto_nota_path'] as String?,
        dibuatPada:    DateTime.parse(j['dibuat_pada'] as String),
        ditutupPada:   j['ditutup_pada'] != null
            ? DateTime.parse(j['ditutup_pada'] as String)
            : null,
      );
}