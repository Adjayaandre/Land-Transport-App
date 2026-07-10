import 'export_mode.dart';
import 'file_saver_io.dart' if (dart.library.html) 'file_saver_web.dart'
    as impl;

export 'export_mode.dart';

/// Abstraksi penyimpanan/pembagian file yang aman untuk Android, iOS, dan Web.
/// Implementasi konkret dipilih otomatis oleh compiler lewat conditional
/// import (file_saver_io.dart untuk mobile/desktop, file_saver_web.dart
/// untuk web) sehingga tidak ada kode dart:io atau dart:html yang
/// "bocor" ke platform yang tidak mendukungnya.
class FileSaver {
  static Future<String?> saveOrShare({
    required List<int> bytes,
    required String fileName,
    required String mimeType,
    required ExportMode mode,
    String? shareSubject,
  }) {
    return impl.saveOrShareBytesImpl(
      bytes: bytes,
      fileName: fileName,
      mimeType: mimeType,
      download: mode == ExportMode.download,
      shareSubject: shareSubject,
    );
  }

  static Future<void> openFile(String path) => impl.openFileImpl(path);

  /// Apakah tombol "Buka" perlu ditampilkan.
  /// false di web karena browser sudah otomatis menyimpan filenya sendiri.
  static bool get canOpenFile => impl.canOpenFileImpl;
}