import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../../l10n/app_localizations.dart';
import '../../models/media_item.dart';
import '../../models/playlist_models.dart';
import '../../models/sandbox_status.dart';
import '../../services/media_resolver.dart';
import '../../services/sandbox/sandbox_manager.dart';

/// Web Multi-Video Sandboxed Playlist Player Screen
///
/// Features:
/// - Real hardware-accelerated video decoding and surface rendering via media_kit.
/// - System audio output routing.
/// - Desktop keyboard controls (Space, Left/Right arrows, M, R, Esc) + Visible on-screen controls.
/// - Touch swipe support for touch laptops, Chromebooks, and tablets in web browsers.
/// - Full controls: Play/Pause with visible contrasting icon, Seek bar, Volume slider + Mute toggle, Repeat modes (Off/One/All).
/// - Auto-advance with fresh sandboxed pipeline launch per video.
/// - Expandable / side playlist panel to select and jump to any video.
class WebVideoPlayerScreen extends StatefulWidget {
  final List<MediaItem> videos;
  final int initialIndex;

  const WebVideoPlayerScreen({
    super.key,
    required this.videos,
    this.initialIndex = 0,
  }) : assert(videos.length > 0, 'Video playlist cannot be empty');

  @override
  State<WebVideoPlayerScreen> createState() => _WebVideoPlayerScreenState();
}

class _WebVideoPlayerScreenState extends State<WebVideoPlayerScreen> {
  late int _currentIndex;
  final FocusNode _focusNode = FocusNode();

  Player? _player;
  VideoController? _controller;

  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration>? _durationSub;
  StreamSubscription<bool>? _playingSub;
  StreamSubscription<bool>? _completedSub;
  StreamSubscription<String>? _errorSub;

  bool _isPlaying = true;
  double _volume = 1.0;
  bool _isMuted = false;
  double _previousVolume = 1.0;
  Duration _position = Duration.zero;
  Duration _duration = const Duration(seconds: 15);
  VideoRepeatMode _repeatMode = VideoRepeatMode.off;

  bool _isSandboxLoading = true;
  SandboxStatus? _sandboxStatus;
  Map<String, dynamic> _mediaMetadata = {};
  String? _errorMessage;
  bool _isPlaylistPanelVisible = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.videos.length - 1);
    _initializePlayer();
    _launchSandboxedVideoPipeline();
  }

  void _initializePlayer() {
    try {
      _player = Player();
      _controller = VideoController(_player!);

      _positionSub = _player!.stream.position.listen((pos) {
        if (mounted) {
          setState(() {
            _position = _duration > Duration.zero && pos > _duration ? _duration : pos;
          });
        }
      });

      _durationSub = _player!.stream.duration.listen((dur) {
        if (mounted && dur > Duration.zero) {
          setState(() {
            _duration = dur;
            if (_position > _duration) {
              _position = _duration;
            }
          });
        }
      });

      _playingSub = _player!.stream.playing.listen((playing) {
        if (mounted) {
          setState(() {
            _isPlaying = playing;
          });
        }
      });

      _completedSub = _player!.stream.completed.listen((completed) {
        if (completed && mounted) {
          _handleVideoCompleted();
        }
      });

      _errorSub = _player!.stream.error.listen((err) {
        if (mounted) {
          setState(() {
            _errorMessage = err;
          });
        }
      });
    } catch (e) {
      debugPrint('Web player initialization fallback: $e');
    }
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _durationSub?.cancel();
    _playingSub?.cancel();
    _completedSub?.cancel();
    _errorSub?.cancel();
    _player?.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _launchSandboxedVideoPipeline() async {
    setState(() {
      _isSandboxLoading = true;
      _errorMessage = null;
      _sandboxStatus = null;
      _position = Duration.zero;
    });

    final currentVideo = widget.videos[_currentIndex];

    try {
      final status = await SandboxManager.instance.runSecurityTest(currentVideo.path);
      final meta = await SandboxManager.instance.inspectMedia(currentVideo.path);
      final resolvedPath = await MediaResolver.resolve(currentVideo.path);

      final durSeconds = (meta['duration_seconds'] as num?)?.toInt() ?? 0;
      final durMs = (meta['duration_ms'] as num?)?.toInt() ?? (durSeconds * 1000);
      final realDuration = durMs > 0 ? Duration(milliseconds: durMs) : const Duration(seconds: 15);

      if (_player != null) {
        await _player!.open(Media(resolvedPath), play: true);
        await _player!.setVolume(_isMuted ? 0.0 : (_volume * 100.0));
      }

      if (mounted) {
        setState(() {
          _sandboxStatus = status;
          _mediaMetadata = meta;
          _duration = realDuration;
          _position = Duration.zero;
          _isPlaying = true;
          _isSandboxLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isSandboxLoading = false;
        });
      }
    }
  }

  void _handleVideoCompleted() {
    switch (_repeatMode) {
      case VideoRepeatMode.repeatOne:
        _player?.seek(Duration.zero);
        _player?.play();
        setState(() {
          _position = Duration.zero;
          _isPlaying = true;
        });
        break;
      case VideoRepeatMode.repeatAll:
        if (_currentIndex < widget.videos.length - 1) {
          _advanceToNextVideo();
        } else {
          _jumpToVideo(0);
        }
        break;
      case VideoRepeatMode.off:
        if (_currentIndex < widget.videos.length - 1) {
          _advanceToNextVideo();
        } else {
          _player?.pause();
          setState(() {
            _isPlaying = false;
            _position = _duration;
          });
        }
        break;
    }
  }

  void _togglePlayPause() {
    if (_player != null) {
      _player!.playOrPause();
    } else {
      setState(() {
        _isPlaying = !_isPlaying;
      });
    }
  }

  void _advanceToNextVideo() {
    if (_currentIndex < widget.videos.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _launchSandboxedVideoPipeline();
    } else if (_repeatMode == VideoRepeatMode.repeatAll) {
      _jumpToVideo(0);
    }
  }

  void _goToPreviousVideo() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      _launchSandboxedVideoPipeline();
    } else if (_repeatMode == VideoRepeatMode.repeatAll) {
      _jumpToVideo(widget.videos.length - 1);
    }
  }

  void _jumpToVideo(int index) {
    if (index >= 0 && index < widget.videos.length && index != _currentIndex) {
      setState(() {
        _currentIndex = index;
      });
      _launchSandboxedVideoPipeline();
    }
  }

  void _seekTo(double valueSeconds) {
    final ms = (valueSeconds * 1000).round();
    final clampedMs = ms.clamp(0, _duration.inMilliseconds);
    final target = Duration(milliseconds: clampedMs);
    setState(() {
      _position = target;
    });
    _player?.seek(target);
  }

  void _toggleMute() {
    setState(() {
      if (_isMuted) {
        _volume = _previousVolume > 0 ? _previousVolume : 1.0;
        _isMuted = false;
      } else {
        _previousVolume = _volume;
        _volume = 0.0;
        _isMuted = true;
      }
    });
    _player?.setVolume(_isMuted ? 0.0 : (_volume * 100.0));
  }

  void _setVolume(double newVolume) {
    setState(() {
      _volume = newVolume;
      _isMuted = newVolume == 0.0;
    });
    _player?.setVolume(_isMuted ? 0.0 : (newVolume * 100.0));
  }

  void _cycleVideoRepeatMode() {
    setState(() {
      _repeatMode = _repeatMode.next();
    });
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mechanism = SandboxManager.instance.mechanismLabel;
    final currentVideo = widget.videos[_currentIndex];

    final bool canPrev = _currentIndex > 0 || _repeatMode == VideoRepeatMode.repeatAll;
    final bool canNext = _currentIndex < widget.videos.length - 1 || _repeatMode == VideoRepeatMode.repeatAll;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: (KeyEvent event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.space) {
              _togglePlayPause();
            } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
              final newPos = _position.inSeconds - 5;
              _seekTo((newPos > 0 ? newPos : 0).toDouble());
            } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
              final newPos = _position.inSeconds + 5;
              _seekTo((newPos < _duration.inSeconds ? newPos : _duration.inSeconds).toDouble());
            } else if (event.logicalKey == LogicalKeyboardKey.keyM) {
              _toggleMute();
            } else if (event.logicalKey == LogicalKeyboardKey.keyR) {
              _cycleVideoRepeatMode();
            } else if (event.logicalKey == LogicalKeyboardKey.escape) {
              Navigator.of(context).maybePop();
            }
          }
        },
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              children: [
                // Top Bar
                Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color,
                    border: Border(
                      bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.2)),
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        tooltip: 'Back',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.video_library, color: theme.colorScheme.primary, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        l10n.multiVideoPlaylist,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(width: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          l10n.videoPosition(_currentIndex + 1, widget.videos.length),
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Tooltip(
                        message: mechanism,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle, size: 12, color: Colors.green),
                              SizedBox(width: 4),
                              Text(
                                'Sandbox Active',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: Icon(
                          _isPlaylistPanelVisible ? Icons.view_sidebar : Icons.view_sidebar_outlined,
                          color: _isPlaylistPanelVisible ? theme.colorScheme.primary : null,
                        ),
                        tooltip: 'Toggle Playlist',
                        onPressed: () {
                          setState(() {
                            _isPlaylistPanelVisible = !_isPlaylistPanelVisible;
                          });
                        },
                      ),
                    ],
                  ),
                ),

                // Video + Playlist (with Touch Swipe gesture support)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onHorizontalDragEnd: (DragEndDetails details) {
                      final v = details.primaryVelocity ?? 0;
                      if (v < -200 && canNext) _advanceToNextVideo();
                      if (v > 200 && canPrev) _goToPreviousVideo();
                    },
                    child: Row(
                      children: [
                        // Video Area
                        Expanded(
                          flex: 7,
                          child: Container(
                            margin: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F1012) : const Color(0xFFDCDDE1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: theme.colorScheme.primary.withValues(alpha: 0.25),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: _isSandboxLoading
                                  ? Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 3,
                                        valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
                                      ),
                                    )
                                  : _buildVideoViewport(currentVideo, theme),
                            ),
                          ),
                        ),

                        // Playlist Panel
                        if (_isPlaylistPanelVisible)
                          Container(
                            width: 300,
                            margin: const EdgeInsets.fromLTRB(0, 16, 16, 16),
                            decoration: BoxDecoration(
                              color: theme.cardTheme.color,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: theme.dividerColor.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.playlist_play, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        l10n.playlist,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      const Spacer(),
                                      Text(
                                        '${widget.videos.length} items',
                                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                                const Divider(height: 1),
                                Expanded(
                                  child: ListView.separated(
                                    itemCount: widget.videos.length,
                                    separatorBuilder: (_, _) => const Divider(height: 1),
                                    itemBuilder: (context, index) {
                                      final video = widget.videos[index];
                                      final isSelected = index == _currentIndex;

                                      return Material(
                                        color: Colors.transparent,
                                        child: ListTile(
                                          dense: true,
                                          selected: isSelected,
                                          selectedTileColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                                          leading: Icon(
                                            isSelected ? Icons.play_circle_fill : Icons.videocam,
                                            color: isSelected ? theme.colorScheme.primary : Colors.grey,
                                          ),
                                          title: Text(
                                            video.name,
                                            style: TextStyle(
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                              fontSize: 13,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          subtitle: Text(video.formattedSize, style: const TextStyle(fontSize: 10)),
                                          onTap: () => _jumpToVideo(index),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Web Bottom Controls Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color,
                    border: Border(
                      top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.2)),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Seek Bar
                      Row(
                        children: [
                          Text(
                            _formatDuration(_position),
                            style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                          ),
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 3,
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                              ),
                              child: Slider(
                                value: _position.inMilliseconds
                                    .clamp(0, _duration.inMilliseconds)
                                    .toDouble() /
                                    1000,
                                min: 0.0,
                                max: (_duration.inMilliseconds / 1000).clamp(0.1, double.infinity),
                                onChanged: (val) => _seekTo(val),
                              ),
                            ),
                          ),
                          Text(
                            _formatDuration(_duration),
                            style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                          ),
                        ],
                      ),

                      // Buttons Row
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.skip_previous),
                            tooltip: l10n.previousVideo,
                            onPressed: canPrev ? _goToPreviousVideo : null,
                          ),
                          // Play / Pause Button with visible high-contrast icon (Bug 2 fix)
                          IconButton.filled(
                            iconSize: 26,
                            style: IconButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                            ),
                            icon: Icon(
                              _isPlaying ? Icons.pause : Icons.play_arrow,
                              color: theme.colorScheme.onPrimary,
                              size: 26,
                            ),
                            tooltip: _isPlaying ? l10n.pause : l10n.play,
                            onPressed: _togglePlayPause,
                          ),
                          IconButton(
                            icon: const Icon(Icons.skip_next),
                            tooltip: l10n.nextVideo,
                            onPressed: canNext ? _advanceToNextVideo : null,
                          ),

                          const SizedBox(width: 16),

                          IconButton(
                            icon: Icon(_isMuted || _volume == 0 ? Icons.volume_off : Icons.volume_up),
                            tooltip: _isMuted ? l10n.unmute : l10n.mute,
                            onPressed: _toggleMute,
                          ),
                          SizedBox(
                            width: 100,
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(trackHeight: 3),
                              child: Slider(
                                value: _volume,
                                min: 0.0,
                                max: 1.0,
                                onChanged: (val) => _setVolume(val),
                              ),
                            ),
                          ),

                          const Spacer(),

                          OutlinedButton.icon(
                            icon: Icon(
                              _repeatMode == VideoRepeatMode.repeatOne
                                  ? Icons.repeat_one
                                  : Icons.repeat,
                              size: 16,
                              color: _repeatMode != VideoRepeatMode.off ? theme.colorScheme.primary : Colors.grey,
                            ),
                            label: Text(
                              _repeatMode.label,
                              style: TextStyle(
                                fontSize: 11,
                                color: _repeatMode != VideoRepeatMode.off ? theme.colorScheme.primary : null,
                              ),
                            ),
                            onPressed: _cycleVideoRepeatMode,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoViewport(MediaItem video, ThemeData theme) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Real hardware-accelerated video decoder surface
          if (_controller != null)
            Video(
              controller: _controller!,
              controls: NoVideoControls,
              fit: BoxFit.contain,
              alignment: Alignment.center,
            )
          else
            _buildFallbackPreview(video, theme),

          // Central Pause Icon Overlay
          if (!_isPlaying && !_isSandboxLoading)
            GestureDetector(
              onTap: _togglePlayPause,
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.6),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.play_arrow,
                  size: 42,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),

          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange),
              ),
              child: Text(
                'Playback warning: $_errorMessage',
                style: const TextStyle(color: Colors.orange, fontSize: 10),
              ),
            ),

          Positioned.fill(
            child: GestureDetector(
              onTap: _togglePlayPause,
              behavior: HitTestBehavior.translucent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackPreview(MediaItem video, ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          _isPlaying ? Icons.movie_creation_outlined : Icons.pause_circle_outline,
          size: 60,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 14),
        Text(
          video.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          'Sandboxed Web Worker Context • PID: ${_sandboxStatus?.isolatedPid ?? 1} • MIME: ${_mediaMetadata['mime_type'] ?? video.mimeType}',
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }
}
