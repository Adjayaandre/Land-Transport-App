import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/file_saver.dart';

class PerjalananPdfService {
  static Future<String?> exportTripPdf(
    Map<String, dynamic> trip,
    Map<String, dynamic>? kendaraan, {
    ExportMode mode = ExportMode.bagikan,
  }) async {
    final pdf = pw.Document();

    final nomorPolisi = kendaraan?['nomor_polisi'] as String? ?? '-';
    final kendaraanDetail = [
      kendaraan?['merek'],
      kendaraan?['model'],
      kendaraan?['warna'],
    ].where((e) => e != null && '$e'.isNotEmpty).join(' ');
    final kendaraanStr = kendaraanDetail.isNotEmpty
        ? '$nomorPolisi ($kendaraanDetail)'
        : nomorPolisi;

    // Ambil detail perjalanan dari tabel perjalanan untuk memastikan kolom deskripsi terbaca (berjaga-jaga jika view ringkasan_perjalanan tidak menyertakannya)
    final detailPerjalanan = await Supabase.instance.client
        .from('perjalanan')
        .select('deskripsi, odometer_akhir, waktu_jemput, waktu_tiba, titik_jemput, titik_tujuan, pic, nama_kapal')
        .eq('id', trip['id'] as String)
        .maybeSingle();

    final deskripsiStr = detailPerjalanan?['deskripsi'] as String? ?? trip['deskripsi'] as String? ?? '-';
    final odometerAkhir = detailPerjalanan?['odometer_akhir'] ?? trip['odometer_akhir'];
    final waktuJemput = _fmtTime(detailPerjalanan?['waktu_jemput'] as String? ?? trip['waktu_jemput'] as String?);
    final waktuTiba = _fmtTime(detailPerjalanan?['waktu_tiba'] as String? ?? trip['waktu_tiba'] as String?);
    final titikJemput = detailPerjalanan?['titik_jemput'] as String? ?? trip['titik_jemput'] as String? ?? '-';
    final titikTujuan = detailPerjalanan?['titik_tujuan'] as String? ?? trip['titik_tujuan'] as String? ?? '-';
    final pic = detailPerjalanan?['pic'] as String? ?? trip['pic'] as String? ?? '-';
    final namaKapal = detailPerjalanan?['nama_kapal'] as String? ?? trip['nama_kapal'] as String? ?? '-';

    // Ambil tanda tangan dari database
    final signatures = await Supabase.instance.client
        .from('tanda_tangan')
        .select('jenis, url_file, path_file, nama_penanda')
        .eq('id_perjalanan', trip['id'] as String);

    final driverSig = signatures.where((s) => s['jenis'] == 'driver').firstOrNull;
    final picSig = signatures.where((s) => s['jenis'] == 'pic').firstOrNull;

    String? extractPath(Map<String, dynamic> sig) {
      if (sig['path_file'] != null) return sig['path_file'] as String;
      final url = sig['url_file'] as String?;
      if (url != null && url.contains('tanda-tangan/')) {
        return url.split('tanda-tangan/').last;
      }
      return null;
    }

    pw.Widget driverWidget = pw.SizedBox(width: 100, height: 50);
    pw.Widget picWidget = pw.SizedBox(width: 100, height: 50);

    String driverLabel = 'Driver';
    String picLabel = 'Customer / PIC';

    if (signatures.isEmpty) {
      driverLabel = 'Driver (Data Kosong)';
      picLabel = 'Customer / PIC (Data Kosong)';
    } else {
      try {
        final path = driverSig != null ? extractPath(driverSig) : null;
        if (path != null) {
          final bytes = await Supabase.instance.client.storage.from('tanda-tangan').download(path);
          driverWidget = pw.Container(width: 100, height: 50, child: pw.Image(pw.MemoryImage(bytes)));
        } else {
          driverLabel = 'Driver (Path Kosong)';
        }
      } catch (e) {
        driverLabel = 'Driver (Gagal Unduh)';
        debugPrint('Gagal mendownload gambar driver: $e');
      }

      try {
        final path = picSig != null ? extractPath(picSig) : null;
        if (path != null) {
          final bytes = await Supabase.instance.client.storage.from('tanda-tangan').download(path);
          picWidget = pw.Container(width: 100, height: 50, child: pw.Image(pw.MemoryImage(bytes)));
        } else {
          picLabel = 'Customer / PIC (Path Kosong)';
        }
      } catch (e) {
        picLabel = 'Customer / PIC (Gagal Unduh)';
        debugPrint('Gagal mendownload gambar pic: $e');
      }
    }

    // Nomor Form (Bisa diambil dari awalan ID perjalanan agar unik)
    final shortId = (trip['id'] as String).substring(0, 5).toUpperCase();
    final nomorForm = 'LT / SIS / $shortId';

    // Format Tanggal
    final tanggalStr = _fmtDate(trip['tanggal'] as String?);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ── HEADER ────────────────────────────────────────────────────────
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'PT. SNEPAC INDO SERVICE',
                        style: pw.TextStyle(
                            fontSize: 16, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        'Badan Usaha Pelabuhan',
                        style: pw.TextStyle(fontSize: 10),
                      ),
                      pw.Text(
                        'Jl. Duyung Komp. Ruko Jodoh Centre Point,\nBlok C No. 9 (Lt. II), Sei Jodoh, Batam 29453',
                        style: pw.TextStyle(fontSize: 9),
                      ),
                    ],
                  ),
                  pw.Text(
                    'No.: $nomorForm',
                    style: pw.TextStyle(
                        fontSize: 12, fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
              pw.SizedBox(height: 24),
              pw.Center(
                child: pw.Text(
                  'LAND TRANSPORT',
                  style: pw.TextStyle(
                      fontSize: 18, fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline),
                ),
              ),
              pw.SizedBox(height: 20),
              
              // ── INFO UTAMA ──────────────────────────────────────────────────
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.RichText(
                    text: pw.TextSpan(
                      text: 'Tanggal : ',
                      style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                      children: [
                        pw.TextSpan(text: tanggalStr, style: pw.TextStyle(fontWeight: pw.FontWeight.normal)),
                      ]
                    )
                  ),
                  pw.RichText(
                    text: pw.TextSpan(
                      text: 'Kendaraan : ',
                      style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                      children: [
                        pw.TextSpan(text: kendaraanStr, style: pw.TextStyle(fontWeight: pw.FontWeight.normal)),
                      ]
                    )
                  ),
                ]
              ),
              pw.SizedBox(height: 12),
              
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black, width: 1),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Column(
                  children: [
                    _buildRow('PIC', pic, 'Vessel (Kapal)', namaKapal),
                    pw.SizedBox(height: 8),
                    _buildRow('Waktu Jemput', waktuJemput, 'Titik Jemput', titikJemput),
                    pw.SizedBox(height: 8),
                    _buildRow('Waktu Tiba', waktuTiba, 'Titik Tujuan', titikTujuan),
                  ]
                ),
              ),
              pw.SizedBox(height: 20),

              // ── TABEL DESKRIPSI & ODOMETER ─────────────────────────────────
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.black, width: 1),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(1),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Deskripsi', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11), textAlign: pw.TextAlign.center),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Odometer Akhir', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11), textAlign: pw.TextAlign.center),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Container(
                        constraints: const pw.BoxConstraints(minHeight: 120),
                        padding: const pw.EdgeInsets.all(12),
                        alignment: pw.Alignment.topLeft,
                        child: pw.Text(deskripsiStr, style: const pw.TextStyle(fontSize: 11)),
                      ),
                      pw.Container(
                        constraints: const pw.BoxConstraints(minHeight: 120),
                        padding: const pw.EdgeInsets.all(12),
                        alignment: pw.Alignment.topCenter,
                        child: pw.Text(
                          odometerAkhir != null ? '$odometerAkhir KM' : '-', 
                          style: const pw.TextStyle(fontSize: 11), textAlign: pw.TextAlign.center
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              pw.Spacer(),

              // ── TANDA TANGAN ────────────────────────────────────────────────
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text(driverLabel, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                      pw.SizedBox(height: 10),
                      driverWidget,
                      pw.SizedBox(height: 10),
                      pw.Text('( ${driverSig?['nama_penanda'] ?? trip['nama_driver'] ?? '......................'} )', style: const pw.TextStyle(fontSize: 11)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text(picLabel, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                      pw.SizedBox(height: 10),
                      picWidget,
                      pw.SizedBox(height: 10),
                      pw.Text('( ${picSig?['nama_penanda'] ?? trip['pic'] ?? '......................'} )', style: const pw.TextStyle(fontSize: 11)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
            ],
          );
        },
      ),
    );

    // ── Simpan & Share ──────────────────────────────────────────────────────
    final bytes = await pdf.save();
    final now = DateTime.now();
    final fileName = 'Form_Perjalanan_${shortId}_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}.pdf';
    const mimeType = 'application/pdf';

    return FileSaver.saveOrShare(
      bytes: bytes,
      fileName: fileName,
      mimeType: mimeType,
      mode: mode,
      shareSubject: 'Form Perjalanan LTMS - $shortId',
    );
  }

  static pw.Widget _buildRow(String label1, String value1, String label2, String value2) {
    return pw.Row(
      children: [
        pw.Expanded(
          flex: 1,
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.SizedBox(width: 80, child: pw.Text('$label1 ', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold))),
              pw.Text(': ', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              pw.Expanded(child: pw.Text(value1, style: const pw.TextStyle(fontSize: 10))),
            ],
          ),
        ),
        pw.SizedBox(width: 10),
        pw.Expanded(
          flex: 1,
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.SizedBox(width: 80, child: pw.Text('$label2 ', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold))),
              pw.Text(': ', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              pw.Expanded(child: pw.Text(value2, style: const pw.TextStyle(fontSize: 10))),
            ],
          ),
        ),
      ]
    );
  }

  static String _fmtTime(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    try {
      // Tangani format "HH:mm:ss", "HH:mm", atau ISO datetime lengkap
      if (raw.contains('T') || raw.contains(' ')) {
        final d = DateTime.parse(raw).toLocal();
        return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
      }
      final parts = raw.split(':');
      if (parts.length >= 2) {
        return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
      }
      return raw;
    } catch (_) {
      return raw;
    }
  }

  static String _fmtDate(String? raw) {
    if (raw == null) return '-';
    try {
      final d = DateTime.parse(raw).toLocal();
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) {
      return raw;
    }
  }
}