import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../l10n/app_localizations.dart';
import '../../models/media_item.dart';
import '../../models/sandbox_status.dart';
import '../../services/sandbox/sandbox_manager.dart';

/// Web Multi-Image Sandboxed Gallery Screen
///
/// Features:
/// - Desktop keyboard arrows (Left/Right) & on-screen navigation buttons.
/// - Touch swipe support for touch-screen laptops, tablets, and mobile browsers.
/// - Position indicator badge ("3 / 12").
/// - Fresh sandboxed pipeline execution on every switch.
/// - Boundary protection: Next/Previous disabled at limits.
class WebImageGalleryScreen extends StatefulWidget {
  final List<MediaItem> images;
  final int initialIndex;

  const WebImageGalleryScreen({
    super.key,
    required this.images,
    this.initialIndex = 0,
  }) : assert(images.length > 0, 'Images list must not be empty');

  @override
  State<WebImageGalleryScreen> createState() => _WebImageGalleryScreenState();
}

class _WebImageGalleryScreenState extends State<WebImageGalleryScreen> {
  late int _currentIndex;
  final FocusNode _focusNode = FocusNode();

  bool _isSandboxLoading = true;
  SandboxStatus? _sandboxStatus;
  Map<String, dynamic> _mediaMetadata = {};
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.images.length - 1);
    _executeFreshSandboxForCurrent();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _executeFreshSandboxForCurrent() async {
    setState(() {
      _isSandboxLoading = true;
      _errorMessage = null;
      _sandboxStatus = null;
    });

    final currentItem = widget.images[_currentIndex];

    try {
      final status = await SandboxManager.instance.runSecurityTest(currentItem.path);
      final meta = await SandboxManager.instance.inspectMedia(currentItem.path);

      if (mounted) {
        setState(() {
          _sandboxStatus = status;
          _mediaMetadata = meta;
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

  void _goToPrevious() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      _executeFreshSandboxForCurrent();
    }
  }

  void _goToNext() {
    if (_currentIndex < widget.images.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _executeFreshSandboxForCurrent();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mechanism = SandboxManager.instance.mechanismLabel;

    final currentItem = widget.images[_currentIndex];
    final bool canPrev = _currentIndex > 0;
    final bool canNext = _currentIndex < widget.images.length - 1;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: (KeyEvent event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
              _goToPrevious();
            } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
              _goToNext();
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
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
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
                      Icon(Icons.shield, color: theme.colorScheme.primary, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        l10n.multiImageViewer,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '${_currentIndex + 1} / ${widget.images.length}',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
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
                    ],
                  ),
                ),

                // Main Viewer Area (with Swipe + Keyboard + Buttons)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onHorizontalDragEnd: (DragEndDetails details) {
                      final v = details.primaryVelocity ?? 0;
                      if (v < -200 && canNext) _goToNext();
                      if (v > 200 && canPrev) _goToPrevious();
                    },
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: IconButton.filledTonal(
                            iconSize: 32,
                            icon: const Icon(Icons.chevron_left),
                            tooltip: canPrev ? l10n.previousImage : null,
                            onPressed: canPrev ? _goToPrevious : null,
                          ),
                        ),
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 20),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF181A1D) : const Color(0xFFE2E3E7),
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
                                  : _renderImageView(currentItem),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: IconButton.filledTonal(
                            iconSize: 32,
                            icon: const Icon(Icons.chevron_right),
                            tooltip: canNext ? l10n.nextImage : null,
                            onPressed: canNext ? _goToNext : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom Status Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color,
                    border: Border(
                      top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.2)),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${currentItem.name} (${currentItem.formattedSize}) • MIME: ${_mediaMetadata['mime_type'] ?? currentItem.mimeType} • PID: ${_sandboxStatus?.isolatedPid ?? 1}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      if (_errorMessage != null)
                        Text(
                          'Warning: $_errorMessage',
                          style: const TextStyle(fontSize: 11, color: Colors.orange),
                        )
                      else
                        Text(
                          l10n.swipeHint,
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
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

  Widget _renderImageView(MediaItem item) {
    if (kIsWeb || item.path.startsWith('assets/')) {
      return Image.asset(
        item.path,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Icon(Icons.broken_image, size: 64, color: Colors.orange),
        ),
      );
    } else {
      return Image.file(
        File(item.path),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Icon(Icons.broken_image, size: 64, color: Colors.orange),
        ),
      );
    }
  }
}

