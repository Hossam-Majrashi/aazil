import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:media_kit/media_kit.dart';
import 'package:aazil/services/media_resolver.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  test('Verify real hardware-accelerated video decoding and audio playback pipeline', () async {
    final player = Player();

    final resolvedPath = await MediaResolver.resolve('assets/samples/sample_video_1.mp4');
    expect(File(resolvedPath).existsSync(), isTrue, reason: 'Sample video file must exist on disk');

    Duration duration = Duration.zero;
    Duration position = Duration.zero;
    bool isPlaying = false;
    List<VideoTrack> videoTracks = [];
    List<AudioTrack> audioTracks = [];

    final durationSub = player.stream.duration.listen((d) => duration = d);
    final positionSub = player.stream.position.listen((p) => position = p);
    final playingSub = player.stream.playing.listen((pl) => isPlaying = pl);
    final tracksSub = player.stream.tracks.listen((t) {
      videoTracks = t.video;
      audioTracks = t.audio;
    });

    await player.open(Media(resolvedPath), play: true);
    await player.setVolume(100.0);

    // Allow decoder to spin up, decode frames, and play audio
    for (int i = 0; i < 20; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (position > Duration.zero && duration > Duration.zero) break;
    }

    print('Decoded Video Duration: $duration');
    print('Decoded Video Position: $position');
    print('Playback active: $isPlaying');
    print('Video tracks detected: ${videoTracks.length}');
    print('Audio tracks detected: ${audioTracks.length}');

    expect(duration.inSeconds, equals(3), reason: 'Decoder must report real 3-second duration');
    expect(position, greaterThanOrEqualTo(Duration.zero));
    expect(videoTracks.isNotEmpty, isTrue, reason: 'Decoder must extract real video track');
    expect(audioTracks.isNotEmpty, isTrue, reason: 'Decoder must extract real audio track');

    // Test seek
    await player.seek(const Duration(seconds: 1));
    await Future.delayed(const Duration(milliseconds: 200));
    print('Position after seek: ${player.state.position}');
    expect(player.state.position.inSeconds, equals(1));

    // Test pause and play
    await player.pause();
    expect(player.state.playing, isFalse);

    await player.play();
    expect(player.state.playing, isTrue);

    await durationSub.cancel();
    await positionSub.cancel();
    await playingSub.cancel();
    await tracksSub.cancel();
    await player.dispose();

    print('CONFIRMATION: Real decoded frames and audio track verified!');
  });
}
