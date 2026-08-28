import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class ImageHelper {
  /// Compress image from file path and return as bytes
  static Future<List<int>?> compressImage(String imagePath, {int quality = 70}) async {
    try {
      final Uint8List? result = await FlutterImageCompress.compressWithFile(
        imagePath,
        minWidth: 1080,
        minHeight: 1080,
        quality: quality,
      );
      return result;
    } catch (e) {
      debugPrint('Error compressing image: $e');
      return null;
    }
  }

  /// Convert bytes to base64 string for local storage
  static String toBase64(List<int> bytes) {
    return base64Encode(bytes);
  }
}
