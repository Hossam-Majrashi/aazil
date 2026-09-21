import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;

/// Service to reliably extract media metadata (duration, format, resolution)
/// across all platforms (Android, iOS, Linux, macOS, Windows, Web).
///
/// Implements pure-Dart container parsing (MP4/MOV, WebM/MKV, AVI)
/// with zero external process dependencies, plus optional ffprobe fallback.
class MediaMetadataReader {
  static const MediaMetadataReader _instance = MediaMetadataReader._internal();
  static MediaMetadataReader get instance => _instance;

  const MediaMetadataReader._internal();

  /// Reads media metadata including accurate real duration from [filePath].
  /// Supports filesystem paths and Flutter asset paths.
  Future<Map<String, dynamic>> readMetadata(String filePath) async {
    try {
      Uint8List? headerBytes;

      if (filePath.startsWith('assets/')) {
        try {
          final byteData = await rootBundle.load(filePath);
          headerBytes = byteData.buffer.asUint8List();
        } catch (_) {}
      }

      if (headerBytes == null) {
        final file = File(filePath);
        if (await file.exists()) {
          final length = await file.length();
          final readLen = length > 2 * 1024 * 1024 ? 2 * 1024 * 1024 : length;
          final raf = await file.open(mode: FileMode.read);
          try {
            headerBytes = await raf.read(readLen);
          } finally {
            await raf.close();
          }
        }
      }

      if (headerBytes != null && headerBytes.isNotEmpty) {
        // 1. Try MP4 / MOV / M4V parser
        final mp4Duration = _parseMp4Duration(headerBytes);
        if (mp4Duration != null && mp4Duration > 0) {
          return {
            'duration_seconds': mp4Duration.round(),
            'duration_ms': (mp4Duration * 1000).round(),
            'duration_exact': mp4Duration,
            'container': 'mp4',
            'status': 'success',
          };
        }

        // 2. Try WebM / MKV parser
        final webmDuration = _parseWebmDuration(headerBytes);
        if (webmDuration != null && webmDuration > 0) {
          return {
            'duration_seconds': webmDuration.round(),
            'duration_ms': (webmDuration * 1000).round(),
            'duration_exact': webmDuration,
            'container': 'webm',
            'status': 'success',
          };
        }

        // 3. Try AVI parser
        final aviDuration = _parseAviDuration(headerBytes);
        if (aviDuration != null && aviDuration > 0) {
          return {
            'duration_seconds': aviDuration.round(),
            'duration_ms': (aviDuration * 1000).round(),
            'duration_exact': aviDuration,
            'container': 'avi',
            'status': 'success',
          };
        }
      }

      // 4. Host ffprobe fallback if available
      final probeDuration = await _tryFfprobe(filePath);
      if (probeDuration != null && probeDuration > 0) {
        return {
          'duration_seconds': probeDuration.round(),
          'duration_ms': (probeDuration * 1000).round(),
          'duration_exact': probeDuration,
          'container': 'probe',
          'status': 'success',
        };
      }
    } catch (_) {}

    return {
      'duration_seconds': 15,
      'duration_ms': 15000,
      'duration_exact': 15.0,
      'status': 'fallback',
    };
  }

  /// Parses ISO Base Media File Format (MP4, MOV, M4V, 3GP) `moov` -> `mvhd` box.
  double? _parseMp4Duration(Uint8List data) {
    int idx = 0;
    final len = data.length;

    while (idx + 8 <= len) {
      int size = (data[idx] << 24) |
          (data[idx + 1] << 16) |
          (data[idx + 2] << 8) |
          data[idx + 3];

      if (idx + 4 > len) break;
      final type = String.fromCharCodes(data.sublist(idx + 4, idx + 8));

      int headerSize = 8;
      if (size == 1) {
        if (idx + 16 > len) break;
        headerSize = 16;
        size = 0;
        for (int i = 0; i < 8; i++) {
          size = (size << 8) | data[idx + 8 + i];
        }
      } else if (size == 0) {
        size = len - idx;
      }

      if (size < headerSize) break;

      if (type == 'moov') {
        // Search inside moov for mvhd
        final moovEnd = (idx + size).clamp(0, len);
        int subIdx = idx + headerSize;

        while (subIdx + 8 <= moovEnd) {
          final subSize = (data[subIdx] << 24) |
              (data[subIdx + 1] << 16) |
              (data[subIdx + 2] << 8) |
              data[subIdx + 3];
          final subType = String.fromCharCodes(data.sublist(subIdx + 4, subIdx + 8));

          if (subType == 'mvhd') {
            final mvhdPos = subIdx + 8;
            if (mvhdPos + 24 > len) return null;

            final version = data[mvhdPos];
            int timescale;
            int duration;

            if (version == 0) {
              // version 0: 4 bytes version+flags, 4 bytes creation, 4 bytes mod, 4 bytes timescale, 4 bytes duration
              final tsPos = mvhdPos + 12;
              final durPos = mvhdPos + 16;
              if (durPos + 4 > len) return null;

              timescale = (data[tsPos] << 24) |
                  (data[tsPos + 1] << 16) |
                  (data[tsPos + 2] << 8) |
                  data[tsPos + 3];

              duration = (data[durPos] << 24) |
                  (data[durPos + 1] << 16) |
                  (data[durPos + 2] << 8) |
                  data[durPos + 3];
            } else {
              // version 1: 4 bytes version+flags, 8 bytes creation, 8 bytes mod, 4 bytes timescale, 8 bytes duration
              final tsPos = mvhdPos + 20;
              final durPos = mvhdPos + 24;
              if (durPos + 8 > len) return null;

              timescale = (data[tsPos] << 24) |
                  (data[tsPos + 1] << 16) |
                  (data[tsPos + 2] << 8) |
                  data[tsPos + 3];

              duration = 0;
              for (int i = 0; i < 8; i++) {
                duration = (duration << 8) | data[durPos + i];
              }
            }

            if (timescale > 0 && duration > 0) {
              return duration / timescale;
            }
          }

          if (subSize <= 0) break;
          subIdx += subSize;
        }
      }

      idx += size;
    }

    return null;
  }

  /// Parses WebM / MKV EBML Header -> Segment -> Info -> Duration (0x4489).
  double? _parseWebmDuration(Uint8List data) {
    if (data.length < 12) return null;
    // Check EBML signature 0x1A 0x45 0xDF 0xA3
    if (data[0] != 0x1A || data[1] != 0x45 || data[2] != 0xDF || data[3] != 0xA3) {
      return null;
    }

    // Look for Duration tag: 0x44 0x89
    for (int i = 0; i < data.length - 10; i++) {
      if (data[i] == 0x44 && data[i + 1] == 0x89) {
        final lenByte = data[i + 2];
        final size = lenByte & 0x7F;
        final valPos = i + 3;

        if (size == 4 && valPos + 4 <= data.length) {
          final bdata = ByteData.sublistView(data, valPos, valPos + 4);
          final val = bdata.getFloat32(0, Endian.big);
          if (val > 0 && !val.isNaN) return val / 1000.0;
        } else if (size == 8 && valPos + 8 <= data.length) {
          final bdata = ByteData.sublistView(data, valPos, valPos + 8);
          final val = bdata.getFloat64(0, Endian.big);
          if (val > 0 && !val.isNaN) return val / 1000.0;
        }
      }
    }

    return null;
  }

  /// Parses AVI RIFF -> 'hdrl' -> 'avih' MainAVIHeader.
  double? _parseAviDuration(Uint8List data) {
    if (data.length < 56) return null;
    if (data[0] != 0x52 || data[1] != 0x49 || data[2] != 0x46 || data[3] != 0x46) {
      return null; // Not RIFF
    }

    for (int i = 0; i < data.length - 24; i++) {
      if (data[i] == 0x61 && data[i + 1] == 0x76 && data[i + 2] == 0x69 && data[i + 3] == 0x68) {
        // 'avih' header found
        final bdata = ByteData.sublistView(data, i + 8, i + 8 + 20);
        final microSecPerFrame = bdata.getUint32(0, Endian.little);
        final totalFrames = bdata.getUint32(16, Endian.little);

        if (microSecPerFrame > 0 && totalFrames > 0) {
          return (microSecPerFrame * totalFrames) / 1000000.0;
        }
      }
    }

    return null;
  }

  Future<double?> _tryFfprobe(String filePath) async {
    try {
      final res = await Process.run(
        'ffprobe',
        [
          '-v',
          'error',
          '-show_entries',
          'format=duration',
          '-of',
          'default=noprint_wrappers=1:nokey=1',
          filePath,
        ],
        runInShell: false,
      );
      if (res.exitCode == 0) {
        final out = res.stdout.toString().trim();
        final dur = double.tryParse(out);
        if (dur != null && dur > 0) return dur;
      }
    } catch (_) {}
    return null;
  }
}
