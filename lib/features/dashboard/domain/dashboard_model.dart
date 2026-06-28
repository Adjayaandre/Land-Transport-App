class DashboardStats {
  final int totalPerjalanan;
  final int perjalananHariIni;

  const DashboardStats({
    required this.totalPerjalanan,
    required this.perjalananHariIni,
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
  final bool dokumenLengkap;

  const PerjalananSingkat({
    required this.id,
    required this.namaDriver,
    required this.nomorPolisi,
    required this.titikJemput,
    required this.titikTujuan,
    required this.tanggal,
    this.pic,
    this.namaKapal,
    required this.dokumenLengkap,
  });

  factory PerjalananSingkat.fromJson(Map<String, dynamic> j) =>
      PerjalananSingkat(
        id:             j['id']             as String,
        namaDriver:     j['nama_driver']     as String? ?? '-',
        nomorPolisi:    j['nomor_polisi']    as String? ?? '-',
        titikJemput:    j['titik_jemput']    as String? ?? '-',
        titikTujuan:    j['titik_tujuan']    as String? ?? '-',
        tanggal:        j['tanggal']         as String? ?? '-',
        pic:            j['pic']             as String?,
        namaKapal:      j['nama_kapal']      as String?,
        dokumenLengkap: j['dokumen_lengkap'] as bool?   ?? false,
      );
}