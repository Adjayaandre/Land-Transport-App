import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_filex/open_filex.dart';

Future<String?> saveOrShareBytesImpl({
  required List<int> bytes,
  required String fileName,
  required String mimeType,
  required bool download,
  String? shareSubject,
}) async {
  if (download) {
    Directory? dir;
    if (Platform.isAndroid) {
      dir = await getDownloadsDirectory();
      dir ??= Directory('/storage/emulated/0/Download');
      if (!await dir.exists()) await dir.create(recursive: true);
    } else {
      dir = await getApplicationDocumentsDirectory();
    }
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);
    return file.path;
  } else {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: mimeType)],
      subject: shareSubject,
    );
    return null;
  }
}

Future<void> openFileImpl(String path) async {
  await OpenFilex.open(path);
}

const bool canOpenFileImpl = true;