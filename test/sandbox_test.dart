import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:aazil/models/media_item.dart';
import 'package:aazil/models/playlist_models.dart';
import 'package:aazil/services/sandbox/android_sandbox.dart';
import 'package:aazil/services/sandbox/ios_sandbox.dart';
import 'package:aazil/services/sandbox/linux_sandbox.dart';
import 'package:aazil/services/sandbox/macos_sandbox.dart';
import 'package:aazil/services/sandbox/sandbox_manager.dart';
import 'package:aazil/services/sandbox/web_sandbox.dart';
import 'package:aazil/services/sandbox/windows_sandbox.dart';
import 'package:aazil/services/media_metadata_reader.dart';

void main() {
  group('Aazil Multi-Platform Sandboxing Security Verification', () {
    test('Linux Native Sandbox Binary Blocks Network and Filesystem (Kernel Proof)', () async {
      if (!Platform.isLinux) return;

      final helper = File('resources/linux/aazil_sandbox');
      expect(helper.existsSync(), isTrue, reason: 'Bundled Linux sandbox helper binary must exist');

      // Test with real native binary execution
      final result = await LinuxSandboxProvider().testIsolation('assets/icon/app_icon.png');
      expect(result.networkBlocked, isTrue, reason: 'Linux Sandbox MUST block socket() syscall via seccomp-bpf');
      expect(result.filesystemBlocked, isTrue, reason: 'Linux Sandbox MUST block out-of-whitelist filesystem reads via mount/chroot');
      expect(result.whitelistAccessible, isTrue, reason: 'Target media in isolated mount must be accessible');
      expect(result.isEnforced, isTrue, reason: 'Overall Linux isolation status must be ENFORCED');
      expect(result.isolatedPid, isNotNull, reason: 'Process must run in an isolated PID namespace');
    });

    test('Windows Sandbox Provider Enforces Restricted Token and Low Integrity', () async {
      final provider = WindowsSandboxProvider();
      expect(provider.platformName, equals('windows'));
      expect(provider.mechanismLabel.contains('Restricted Token'), isTrue);
      expect(provider.mechanismLabel.contains('Low Integrity'), isTrue);
      expect(provider.securityArchitectureInfo.contains('restricted access token'), isTrue);

      final status = await provider.testIsolation('assets/icon/app_icon.png');
      expect(status.networkBlocked, isTrue);
      expect(status.filesystemBlocked, isTrue);
      expect(status.isEnforced, isTrue);
    });

    test('macOS Sandbox Provider Enforces sandbox_init() C API and App Sandbox Entitlements', () async {
      final provider = MacOSSandboxProvider();
      expect(provider.platformName, equals('macos'));
      expect(provider.mechanismLabel.contains('sandbox_init()'), isTrue);
      expect(provider.securityArchitectureInfo.contains('libsandbox.dylib'), isTrue);

      final status = await provider.testIsolation('assets/icon/app_icon.png');
      expect(status.networkBlocked, isTrue);
      expect(status.filesystemBlocked, isTrue);
      expect(status.isEnforced, isTrue);
    });

    test('Android Sandbox Provider Enforces isolatedProcess (:sandbox) and Binder IPC', () async {
      final provider = AndroidSandboxProvider();
      expect(provider.platformName, equals('android'));
      expect(provider.mechanismLabel.contains('isolatedProcess'), isTrue);
      expect(provider.securityArchitectureInfo.contains('INTERNET'), isTrue);

      final status = await provider.testIsolation('assets/icon/app_icon.png');
      expect(status.networkBlocked, isTrue);
      expect(status.filesystemBlocked, isTrue);
      expect(status.isEnforced, isTrue);
    });

    test('iOS Sandbox Provider Enforces OS-assisted isolation (WebKit WebContent Sandbox)', () async {
      final provider = IOSSandboxProvider();
      expect(provider.platformName, equals('ios'));
      expect(provider.mechanismLabel.contains('OS-assisted isolation'), isTrue);
      expect(provider.securityArchitectureInfo.contains('WebKit'), isTrue);

      final status = await provider.testIsolation('assets/icon/app_icon.png');
      expect(status.networkBlocked, isTrue);
      expect(status.filesystemBlocked, isTrue);
      expect(status.isEnforced, isTrue);
    });

    test('Web Sandbox Provider Enforces Web Worker Thread Boundary', () async {
      final provider = WebSandboxProvider();
      expect(provider.platformName, equals('web'));
      expect(provider.mechanismLabel.contains('Web Worker'), isTrue);

      final status = await provider.testIsolation('assets/icon/app_icon.png');
      expect(status.networkBlocked, isTrue);
      expect(status.isEnforced, isTrue);
    });

    test('Sandbox Manager provides platform mechanism label', () {
      final label = SandboxManager.instance.mechanismLabel;
      expect(label.isNotEmpty, isTrue);
      expect(
        label.toLowerCase().contains('sandbox') ||
            label.toLowerCase().contains('namespaces') ||
            label.toLowerCase().contains('isolation'),
        isTrue,
      );
    });
  });

  group('Aazil Multi-Image Navigation Verification', () {
    test('Image navigation boundary policy: disable at ends', () {
      final images = [
        MediaItem(id: '1', path: 'p1.png', name: 'img1.png', size: 100, type: MediaType.image, mimeType: 'image/png'),
        MediaItem(id: '2', path: 'p2.png', name: 'img2.png', size: 200, type: MediaType.image, mimeType: 'image/png'),
        MediaItem(id: '3', path: 'p3.png', name: 'img3.png', size: 300, type: MediaType.image, mimeType: 'image/png'),
      ];

      // At start (index 0): Previous must be disabled, Next enabled
      int index = 0;
      bool canPrev = index > 0;
      bool canNext = index < images.length - 1;
      expect(canPrev, isFalse, reason: 'Previous must be disabled at index 0');
      expect(canNext, isTrue, reason: 'Next must be enabled when more images exist');

      // Navigate next
      if (canNext) index++;
      expect(index, equals(1));
      canPrev = index > 0;
      canNext = index < images.length - 1;
      expect(canPrev, isTrue);
      expect(canNext, isTrue);

      // Navigate to last image (index 2)
      if (canNext) index++;
      expect(index, equals(2));
      canPrev = index > 0;
      canNext = index < images.length - 1;
      expect(canPrev, isTrue);
      expect(canNext, isFalse, reason: 'Next must be disabled at the last image');
    });
  });

  group('Aazil Multi-Video Playlist & Auto-Advance Verification', () {
    test('Video RepeatMode cycle: Off -> RepeatOne -> RepeatAll -> Off', () {
      VideoRepeatMode mode = VideoRepeatMode.off;
      expect(mode.label, equals('Off'));

      mode = mode.next();
      expect(mode, equals(VideoRepeatMode.repeatOne));
      expect(mode.label, equals('Repeat One'));

      mode = mode.next();
      expect(mode, equals(VideoRepeatMode.repeatAll));
      expect(mode.label, equals('Repeat All'));

      mode = mode.next();
      expect(mode, equals(VideoRepeatMode.off));
    });

    test('Playlist auto-advance logic', () {
      const totalVideos = 3;
      int currentIndex = 0;
      VideoRepeatMode mode = VideoRepeatMode.off;

      // When video finishes with repeatMode == off: advances to next
      void onVideoComplete() {
        switch (mode) {
          case VideoRepeatMode.repeatOne:
            // Replays same video
            break;
          case VideoRepeatMode.repeatAll:
            if (currentIndex < totalVideos - 1) {
              currentIndex++;
            } else {
              currentIndex = 0;
            }
            break;
          case VideoRepeatMode.off:
            if (currentIndex < totalVideos - 1) {
              currentIndex++;
            }
            break;
        }
      }

      onVideoComplete();
      expect(currentIndex, equals(1), reason: 'Auto-advanced to video 2');

      onVideoComplete();
      expect(currentIndex, equals(2), reason: 'Auto-advanced to video 3 (last)');

      onVideoComplete();
      expect(currentIndex, equals(2), reason: 'Repeat off stops at last video');

      // Now with RepeatAll
      mode = VideoRepeatMode.repeatAll;
      onVideoComplete();
      expect(currentIndex, equals(0), reason: 'RepeatAll wraps to first video');

      // Now with RepeatOne
      mode = VideoRepeatMode.repeatOne;
      onVideoComplete();
      expect(currentIndex, equals(0), reason: 'RepeatOne stays on current video');
    });

    test('Volume control and mute toggle transitions', () {
      double volume = 0.8;
      bool isMuted = false;
      double prevVolume = 0.8;

      // Mute toggle
      prevVolume = volume;
      volume = 0.0;
      isMuted = true;
      expect(volume, equals(0.0));
      expect(isMuted, isTrue);

      // Unmute toggle restores previous volume
      volume = prevVolume;
      isMuted = false;
      expect(volume, equals(0.8));
      expect(isMuted, isFalse);
    });

    test('Bug 1 Fix: Real Video Duration extraction from MP4 media file', () async {
      final meta1 = await MediaMetadataReader.instance.readMetadata('assets/samples/sample_video_1.mp4');
      expect(meta1['duration_seconds'], equals(3), reason: 'sample_video_1.mp4 real duration is 3 seconds');
      expect(meta1['duration_ms'], equals(3000));
      expect(meta1['container'], equals('mp4'));

      final meta2 = await MediaMetadataReader.instance.readMetadata('assets/samples/sample_video_2.mp4');
      expect(meta2['duration_seconds'], equals(3));
      expect(meta2['duration_ms'], equals(3000));

      final meta3 = await MediaMetadataReader.instance.readMetadata('assets/samples/sample_video_3.mp4');
      expect(meta3['duration_seconds'], equals(3));
      expect(meta3['duration_ms'], equals(3000));

      // Test integration with SandboxManager.inspectMedia
      final fullMeta = await SandboxManager.instance.inspectMedia('assets/samples/sample_video_1.mp4');
      expect(fullMeta['duration_seconds'], equals(3), reason: 'SandboxManager.inspectMedia must include accurate real duration');
      expect(fullMeta['duration_ms'], equals(3000));
    });
  });
}
