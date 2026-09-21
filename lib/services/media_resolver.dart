import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Resolves media paths for video and audio playback across all platforms.
///
/// Ensures both filesystem files and bundled assets are converted to
/// valid absolute accessible paths for media decoders.
class MediaResolver {
  static Future<String> resolve(String inputPath) async {
    if (kIsWeb) {
      return inputPath;
    }

    try {
      final file = File(inputPath);
      if (await file.exists()) {
        return file.absolute.path;
      }

      if (inputPath.startsWith('assets/') || !inputPath.contains(Platform.pathSeparator)) {
        final tempDir = await getTemporaryDirectory();
        final baseName = p.basename(inputPath);
        final cachedFile = File('${tempDir.path}/aazil_media_$baseName');
        if (!await cachedFile.exists() || await cachedFile.length() == 0) {
          final assetKey = inputPath.startsWith('assets/') ? inputPath : 'assets/$inputPath';
          final byteData = await rootBundle.load(assetKey);
          await cachedFile.writeAsBytes(byteData.buffer.asUint8List(), flush: true);
        }
        return cachedFile.absolute.path;
      }
    } catch (_) {}

    return inputPath;
  }
}
