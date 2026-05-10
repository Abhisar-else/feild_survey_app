import 'dart:convert';
import 'package:flutter/foundation.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class FileDownloadHelper {
  static void downloadCsv(String csvData, String fileName) {
    if (kIsWeb) {
      final bytes = utf8.encode(csvData);
      final blob = html.Blob([bytes], 'text/csv');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", "$fileName.csv")
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      // Mobile implementation would require path_provider and file writing
      // which is more complex. Since the user is deploying to web, 
      // we prioritize the web solution.
      debugPrint("CSV Download only supported on Web currently.");
    }
  }
}
