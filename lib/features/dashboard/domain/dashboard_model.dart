class DashboardStats {
  final int perjalananHariIni;
  final double totalKmSelesai;

  const DashboardStats({
    required this.perjalananHariIni,
    required this.totalKmSelesai,
  });
}

class PerjalananSingkat {
  final String id;
  final String namaDriver;
  final String nomorPolisi;
  final String titikJemput;
  final String titikTujuan;
  final String tanggal;
  final String? pic;
  final String? namaKapal;
  final String? waktuTiba;
  final List<String> penumpang;
  final double? odometerAkhir;
  final double? jarak;
  final bool selesai;

  const PerjalananSingkat({
    required this.id,
    required this.namaDriver,
    required this.nomorPolisi,
    required this.titikJemput,
    required this.titikTujuan,
    required this.tanggal,
    this.pic,
    this.namaKapal,
    this.waktuTiba,
    this.penumpang = const [],
    this.odometerAkhir,
    this.jarak,
    required this.selesai,
  });

  factory PerjalananSingkat.fromJson(Map<String, dynamic> j) =>
      PerjalananSingkat(
        id:            j['id']            as String,
        namaDriver:    j['nama_driver']   as String? ?? '-',
        nomorPolisi:   j['nomor_polisi']  as String? ?? '-',
        titikJemput:   j['titik_jemput']  as String? ?? '-',
        titikTujuan:   j['titik_tujuan']  as String? ?? '-',
        tanggal:       j['tanggal']       as String? ?? '-',
        pic:           j['pic']           as String?,
        namaKapal:     j['nama_kapal']    as String?,
        waktuTiba:     j['waktu_tiba']    as String?,
        penumpang: (j['penumpang'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        odometerAkhir: (j['odometer_akhir'] as num?)?.toDouble(),
        jarak:         (j['jarak'] as num?)?.toDouble(),
        selesai:       j['selesai'] as bool? ?? false,
      );
}