import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_html/html.dart' as html;

class FileSaverUtil {
  /// Saves the given [bytes] as a file with the specified [fileName].
  /// On Web, it triggers a browser download.
  /// On Mobile, it saves the file to the app's documents directory.
  static Future<String?> saveFile({
    required Uint8List bytes,
    required String fileName,
    String? mimeType,
  }) async {
    if (kIsWeb) {
      return _saveFileWeb(bytes, fileName, mimeType);
    } else {
      return _saveFileMobile(bytes, fileName);
    }
  }

  static Future<String?> _saveFileWeb(
    Uint8List bytes,
    String fileName,
    String? mimeType,
  ) async {
    try {
      final blob = html.Blob([bytes], mimeType ?? 'application/octet-stream');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..click();
      html.Url.revokeObjectUrl(url);
      return fileName; // Return filename as acknowledgment
    } catch (e) {
      debugPrint('Error saving file on Web: $e');
      return null;
    }
  }

  static Future<String?> _saveFileMobile(Uint8List bytes, String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(bytes);
      return filePath;
    } catch (e) {
      debugPrint('Error saving file on Mobile: $e');
      return null;
    }
  }
}
