import 'dart:typed_data';

enum MediaType { image, video, audio, unknown }

class MediaItem {
  final String id;
  final String path;
  final String name;
  final int size;
  final MediaType type;
  final String mimeType;
  final Uint8List? previewBytes;
  final Map<String, dynamic> metadata;

  MediaItem({
    required this.id,
    required this.path,
    required this.name,
    required this.size,
    required this.type,
    required this.mimeType,
    this.previewBytes,
    this.metadata = const {},
  });

  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  static MediaType detectType(String filename, [String mime = '']) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.bmp') ||
        mime.startsWith('image/')) {
      return MediaType.image;
    }
    if (lower.endsWith('.mp4') ||
        lower.endsWith('.mkv') ||
        lower.endsWith('.webm') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.avi') ||
        mime.startsWith('video/')) {
      return MediaType.video;
    }
    if (lower.endsWith('.mp3') ||
        lower.endsWith('.wav') ||
        lower.endsWith('.ogg') ||
        lower.endsWith('.m4a') ||
        mime.startsWith('audio/')) {
      return MediaType.audio;
    }
    return MediaType.unknown;
  }
}
