import 'package:excel/excel.dart';
import '../../../shared/file_saver.dart';

class PerjalananExportService {
  static Future<String?> exportToExcel(
    List<Map<String, dynamic>> klips, {
    ExportMode mode = ExportMode.bagikan,
  }) async {
    final excel = Excel.createExcel();
    excel.rename('Sheet1', 'Riwayat Perjalanan');
    final sheet = excel['Riwayat Perjalanan'];

    // ── Styles ────────────────────────────────────────────
    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#1E3A8A'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      fontSize: 11,
      fontFamily: getFontFamily(FontFamily.Arial),
      textWrapping: TextWrapping.WrapText,
    );

    final subHeaderStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#E8F0FE'),
      fontSize: 10,
      fontFamily: getFontFamily(FontFamily.Arial),
    );

    final dataStyle = CellStyle(
      fontSize: 10,
      fontFamily: getFontFamily(FontFamily.Arial),
      verticalAlign: VerticalAlign.Center,
    );

    final dataAltStyle = CellStyle(
      fontSize: 10,
      fontFamily: getFontFamily(FontFamily.Arial),
      verticalAlign: VerticalAlign.Center,
      backgroundColorHex: ExcelColor.fromHexString('#F8FAFF'),
    );

    final titleStyle = CellStyle(
      bold: true,
      fontSize: 14,
      fontFamily: getFontFamily(FontFamily.Arial),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      backgroundColorHex: ExcelColor.fromHexString('#1E3A8A'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
    );

    final subtitleStyle = CellStyle(
      fontSize: 10,
      fontFamily: getFontFamily(FontFamily.Arial),
      horizontalAlign: HorizontalAlign.Center,
      fontColorHex: ExcelColor.fromHexString('#666666'),
    );

    // ── Judul ─────────────────────────────────────────────
    sheet.merge(
      CellIndex.indexByString('A1'),
      CellIndex.indexByString('M1'),
    );
    final titleCell = sheet.cell(CellIndex.indexByString('A1'));
    titleCell.value = TextCellValue('RIWAYAT PERJALANAN LTMS');
    titleCell.cellStyle = titleStyle;
    sheet.setRowHeight(0, 30);

    final now = DateTime.now();
    sheet.merge(
      CellIndex.indexByString('A2'),
      CellIndex.indexByString('M2'),
    );
    final dateCell = sheet.cell(CellIndex.indexByString('A2'));
    dateCell.value = TextCellValue(
        'Diekspor pada: ${_fmt(now.toIso8601String())}');
    dateCell.cellStyle = subtitleStyle;
    sheet.setRowHeight(1, 20);
    sheet.setRowHeight(2, 8);

    // ── Header kolom ──────────────────────────────────────
    final headers = [
      'No', 'Tanggal', 'Nomor Polisi', 'Kendaraan', 'Driver',
      'PIC', 'Nama Kapal', 'Titik Jemput', 'Titik Tujuan',
      'Waktu Jemput', 'Waktu Tiba', 'Odometer (KM)', 'Penumpang',
    ];

    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 3));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = headerStyle;
    }
    sheet.setRowHeight(3, 36);

    // ── Data ──────────────────────────────────────────────
    int rowIdx = 4;
    int no = 1;
    bool alt = false;

    for (final klip in klips) {
      final kendaraan = klip['kendaraan'] as Map<String, dynamic>?;
      final nomorPolisi = kendaraan?['nomor_polisi'] as String? ?? '-';
      final merekModel = [kendaraan?['merek'], kendaraan?['model']]
          .where((e) => e != null && '$e'.isNotEmpty)
          .join(' ');

      final perjalananList =
          (klip['perjalanan'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      if (perjalananList.isEmpty) continue;

      // Sub-header klip
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIdx),
        CellIndex.indexByColumnRow(
            columnIndex: headers.length - 1, rowIndex: rowIdx),
      );
      final klipCell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIdx));
      final status = klip['status'] == 'aktif' ? 'AKTIF' : 'SELESAI';
      final dibuat = _fmt(klip['dibuat_pada'] as String?);
      final ditutup = klip['ditutup_pada'] != null
          ? _fmt(klip['ditutup_pada'] as String?)
          : '-';
      klipCell.value = TextCellValue(
          'Klip $nomorPolisi — $status | Mulai: $dibuat | Selesai: $ditutup');
      klipCell.cellStyle = subHeaderStyle;
      sheet.setRowHeight(rowIdx, 20);
      rowIdx++;
      alt = false;

      for (final trip in perjalananList) {
        final style = alt ? dataAltStyle : dataStyle;
        final penumpang =
            (trip['penumpang'] as List?)?.map((e) => e.toString()).join(', ') ??
                '-';

        final rowData = [
          IntCellValue(no),
          TextCellValue(trip['tanggal'] as String? ?? '-'),
          TextCellValue(nomorPolisi),
          TextCellValue(merekModel),
          TextCellValue(trip['nama_driver'] as String? ?? '-'),
          TextCellValue(trip['pic'] as String? ?? '-'),
          TextCellValue(trip['nama_kapal'] as String? ?? '-'),
          TextCellValue(trip['titik_jemput'] as String? ?? '-'),
          TextCellValue(trip['titik_tujuan'] as String? ?? '-'),
          TextCellValue(trip['waktu_jemput'] as String? ?? '-'),
          TextCellValue(trip['waktu_tiba'] as String? ?? '-'),
          trip['odometer_akhir'] != null
              ? DoubleCellValue((trip['odometer_akhir'] as num).toDouble())
              : TextCellValue('-'),
          TextCellValue(penumpang),
        ];

        for (var c = 0; c < rowData.length; c++) {
          final cell = sheet.cell(
              CellIndex.indexByColumnRow(columnIndex: c, rowIndex: rowIdx));
          cell.value = rowData[c];
          cell.cellStyle = style;
        }

        sheet.setRowHeight(rowIdx, 22);
        rowIdx++;
        no++;
        alt = !alt;
      }
    }

    // ── Lebar kolom ───────────────────────────────────────
    final colWidths = [
      6.0, 12.0, 14.0, 18.0, 18.0, 16.0, 16.0,
      20.0, 20.0, 12.0, 12.0, 14.0, 30.0,
    ];
    for (var i = 0; i < colWidths.length; i++) {
      sheet.setColumnWidth(i, colWidths[i]);
    }

    // ── Simpan & share ────────────────────────────────────
    final bytes = excel.encode();
    if (bytes == null) throw Exception('Gagal membuat file Excel');

    final fileName =
        'Riwayat_Perjalanan_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}.xlsx';
    const mimeType =
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

    return FileSaver.saveOrShare(
      bytes: bytes,
      fileName: fileName,
      mimeType: mimeType,
      mode: mode,
      shareSubject: 'Riwayat Perjalanan LTMS',
    );
  }

  static String _fmt(String? raw) {
    if (raw == null) return '-';
    try {
      final d = DateTime.parse(raw).toLocal();
      return '${d.day.toString().padLeft(2, '0')}/'
          '${d.month.toString().padLeft(2, '0')}/'
          '${d.year}';
    } catch (_) {
      return raw;
    }
  }
}