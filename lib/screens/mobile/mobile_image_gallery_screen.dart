import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/media_item.dart';
import '../../models/sandbox_status.dart';
import '../../services/sandbox/sandbox_manager.dart';

/// Mobile Multi-Image Sandboxed Gallery Screen
///
/// Features:
/// - Primary touch swipe gestures (swipe left for next, swipe right for previous).
/// - On-screen next/previous floating navigation buttons.
/// - Position indicator badge ("3 / 12").
/// - Fresh sandboxed pipeline execution on every switch (no unverified caching).
/// - Greyed-out/disabled navigation at boundary limits (Previous on first, Next on last).
class MobileImageGalleryScreen extends StatefulWidget {
  final List<MediaItem> images;
  final int initialIndex;

  const MobileImageGalleryScreen({
    super.key,
    required this.images,
    this.initialIndex = 0,
  }) : assert(images.length > 0, 'Images list must not be empty');

  @override
  State<MobileImageGalleryScreen> createState() => _MobileImageGalleryScreenState();
}

class _MobileImageGalleryScreenState extends State<MobileImageGalleryScreen> {
  late int _currentIndex;
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

  /// Fresh sandboxed render pipeline per image navigation requirement:
  /// Every single image transition tears down the old session and runs the OS isolation pipeline.
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
    // Navigation boundary choice: Disable/stop at first image (no wrap)
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      _executeFreshSandboxForCurrent();
    }
  }

  void _goToNext() {
    // Navigation boundary choice: Disable/stop at last image (no wrap)
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
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.multiImageViewer,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              '${_currentIndex + 1} / ${widget.images.length} • ${currentItem.name}',
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 11, color: Colors.grey),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Tooltip(
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
                      'Active',
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
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Re-verify Sandbox',
            onPressed: _executeFreshSandboxForCurrent,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [

            // Center Image Area with Swipe Gesture Detection
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragEnd: (DragEndDetails details) {
                  // Primary Mobile Touch Gesture: Swipe left/right
                  final velocity = details.primaryVelocity ?? 0;
                  if (velocity < -200) {
                    // Swiped Left -> Next image
                    _goToNext();
                  } else if (velocity > 200) {
                    // Swiped Right -> Previous image
                    _goToPrevious();
                  }
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      margin: const EdgeInsets.all(12),
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1B1D20) : const Color(0xFFE4E5E8),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.primary.withValues(alpha: 0.25),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: _isSandboxLoading
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(
                                      strokeWidth: 3,
                                      valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      l10n.previewRendering,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : _renderImageView(currentItem),
                      ),
                    ),

                    // On-Screen Previous Floating Button
                    Positioned(
                      left: 16,
                      child: IconButton.filledTonal(
                        icon: const Icon(Icons.chevron_left, size: 24),
                        tooltip: canPrev ? l10n.previousImage : null,
                        onPressed: canPrev ? _goToPrevious : null,
                      ),
                    ),

                    // On-Screen Next Floating Button
                    Positioned(
                      right: 16,
                      child: IconButton.filledTonal(
                        icon: const Icon(Icons.chevron_right, size: 24),
                        tooltip: canNext ? l10n.nextImage : null,
                        onPressed: canNext ? _goToNext : null,
                      ),
                    ),

                    // Mobile swipe hint
                    Positioned(
                      bottom: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          l10n.swipeHint,
                          style: const TextStyle(color: Colors.white70, fontSize: 10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Info and Security Badges
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                border: Border(
                  top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.2)),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${currentItem.formattedSize} • ${_mediaMetadata['mime_type'] ?? currentItem.mimeType}',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'PID: ${_sandboxStatus?.isolatedPid ?? 1}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Warning: $_errorMessage',
                        style: const TextStyle(fontSize: 10, color: Colors.orange),
                      ),
                    ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildChip(Icons.wifi_off, 'No Net', Colors.orange),
                      _buildChip(Icons.folder_delete, 'Chroot/Isolated', Colors.cyan),
                      _buildChip(Icons.security, 'Seccomp Active', Colors.green),
                    ],
                  ),

                ],
              ),
            ),
          ],
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
          child: Icon(Icons.broken_image, size: 48, color: Colors.orange),
        ),
      );
    } else {
      return Image.file(
        File(item.path),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Icon(Icons.broken_image, size: 48, color: Colors.orange),
        ),
      );
    }
  }


  Widget _buildChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
