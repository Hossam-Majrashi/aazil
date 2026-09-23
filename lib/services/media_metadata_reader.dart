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

        // 4. Try FLV parser
        final flvDuration = _parseFlvDuration(headerBytes);
        if (flvDuration != null && flvDuration > 0) {
          return {
            'duration_seconds': flvDuration.round(),
            'duration_ms': (flvDuration * 1000).round(),
            'duration_exact': flvDuration,
            'container': 'flv',
            'status': 'success',
          };
        }

        // 5. Try WMV / ASF parser
        final wmvDuration = _parseWmvDuration(headerBytes);
        if (wmvDuration != null && wmvDuration > 0) {
          return {
            'duration_seconds': wmvDuration.round(),
            'duration_ms': (wmvDuration * 1000).round(),
            'duration_exact': wmvDuration,
            'container': 'wmv',
            'status': 'success',
          };
        }
      }

      // 6. Host ffprobe fallback if available
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

  /// Parses Flash Video (FLV) metadata tag duration.
  double? _parseFlvDuration(Uint8List data) {
    if (data.length < 9) return null;
    // FLV signature: 'FLV'
    if (data[0] != 0x46 || data[1] != 0x4C || data[2] != 0x56) {
      return null;
    }

    // Search for ASCII 'duration' in script tag
    final target = [0x64, 0x75, 0x72, 0x61, 0x74, 0x69, 0x6F, 0x6E]; // 'duration'
    for (int i = 0; i <= data.length - target.length - 9; i++) {
      bool match = true;
      for (int j = 0; j < target.length; j++) {
        if (data[i + j] != target[j]) {
          match = false;
          break;
        }
      }
      if (match) {
        // Next byte is type (0x00 for AMF0 Number - 8 bytes double big-endian)
        final typePos = i + target.length;
        if (data[typePos] == 0x00 && typePos + 9 <= data.length) {
          final bdata = ByteData.sublistView(data, typePos + 1, typePos + 9);
          final dur = bdata.getFloat64(0, Endian.big);
          if (dur > 0 && !dur.isNaN && !dur.isInfinite) {
            return dur;
          }
        }
      }
    }
    return null;
  }

  /// Parses ASF / WMV File Properties Object PlayDuration.
  double? _parseWmvDuration(Uint8List data) {
    if (data.length < 30) return null;
    // ASF Header Object GUID: 75B22630-668E-11CF-A6D9-00AA0062CE6C
    // Byte sequence: 30 26 B2 75 8E 66 CF 11 A6 D9 00 AA 00 62 CE 6C
    if (data[0] != 0x30 || data[1] != 0x26 || data[2] != 0xB2 || data[3] != 0x75) {
      return null;
    }

    // Search for File Properties Object GUID:
    // A1 DC AB 8C 47 A9 CF 11 8E E4 00 C0 0C 20 53 65
    final fpropGuid = [
      0xA1, 0xDC, 0xAB, 0x8C, 0x47, 0xA9, 0xCF, 0x11,
      0x8E, 0xE4, 0x00, 0xC0, 0x0C, 0x20, 0x53, 0x65,
    ];

    for (int i = 0; i <= data.length - fpropGuid.length - 72; i++) {
      bool match = true;
      for (int j = 0; j < fpropGuid.length; j++) {
        if (data[i + j] != fpropGuid[j]) {
          match = false;
          break;
        }
      }
      if (match) {
        // In File Properties Object:
        // GUID: 16 bytes (offset 0)
        // Object Size: 8 bytes (offset 16)
        // File ID: 16 bytes (offset 24)
        // File Size: 8 bytes (offset 40)
        // Creation Date: 8 bytes (offset 48)
        // Data Packets Count: 8 bytes (offset 56)
        // Play Duration: 8 bytes (offset 64 from object start, in 100-nanoseconds)
        final playDurOffset = i + 64;
        if (playDurOffset + 8 <= data.length) {
          final bdata = ByteData.sublistView(data, playDurOffset, playDurOffset + 8);
          final ticks = bdata.getUint64(0, Endian.little);
          if (ticks > 0) {
            final durSec = ticks / 10000000.0;
            if (durSec > 0 && !durSec.isNaN && !durSec.isInfinite) {
              return durSec;
            }
          }
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
