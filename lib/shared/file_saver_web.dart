import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

Future<String?> saveOrShareBytesImpl({
  required List<int> bytes,
  required String fileName,
  required String mimeType,
  required bool download,
  String? shareSubject,
}) async {
  // Di web, "download" maupun "bagikan" sama-sama diwujudkan sebagai
  // download langsung ke folder Downloads browser milik pengguna.
  final blob = html.Blob([Uint8List.fromList(bytes)], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();
  html.Url.revokeObjectUrl(url);
  return null; // Web tidak memiliki path lokal yang bisa diakses balik
}

Future<void> openFileImpl(String path) async {
  // Tidak diperlukan di web: file sudah otomatis tersimpan oleh browser
}

const bool canOpenFileImpl = false;