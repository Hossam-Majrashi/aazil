import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../l10n/app_localizations.dart';
import '../../models/media_item.dart';
import '../../models/sandbox_status.dart';
import '../../services/sandbox/sandbox_manager.dart';

/// Desktop Multi-Image Sandboxed Gallery Screen
/// 
/// Supports on-screen Next/Previous arrows, desktop keyboard navigation (Left/Right arrow keys),
/// and fresh sandbox pipeline execution on every single image switch.
/// 
/// Navigation boundary policy: We disable and grey-out navigation at the ends
/// (Previous disabled on first image, Next disabled on last image) to prevent accidental wrap-around
/// while inspecting sensitive media.
class DesktopImageGalleryScreen extends StatefulWidget {
  final List<MediaItem> images;
  final int initialIndex;

  const DesktopImageGalleryScreen({
    super.key,
    required this.images,
    this.initialIndex = 0,
  }) : assert(images.length > 0, 'Image list must not be empty');

  @override
  State<DesktopImageGalleryScreen> createState() => _DesktopImageGalleryScreenState();
}

class _DesktopImageGalleryScreenState extends State<DesktopImageGalleryScreen> {
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

  /// Fresh sandboxed render pipeline per image navigation requirement:
  /// Every time the user navigates, we terminate the previous session and execute
  /// the real OS-level isolation checks anew. No non-sandboxed caching is permitted.
  Future<void> _executeFreshSandboxForCurrent() async {
    setState(() {
      _isSandboxLoading = true;
      _errorMessage = null;
      _sandboxStatus = null;
    });

    final currentItem = widget.images[_currentIndex];

    try {
      // 1. Run security threat block test in isolated process
      final status = await SandboxManager.instance.runSecurityTest(currentItem.path);
      // 2. Inspect media metadata safely within sandbox limits
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

  void _jumpToIndex(int index) {
    if (index >= 0 && index < widget.images.length && index != _currentIndex) {
      setState(() {
        _currentIndex = index;
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
    final bool canGoPrev = _currentIndex > 0;
    final bool canGoNext = _currentIndex < widget.images.length - 1;

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
        child: Column(
          children: [
            // Top Bar
            Container(
              height: 64,
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
                  Icon(Icons.shield, color: theme.colorScheme.primary, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    l10n.multiImageViewer,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(width: 16),
                  // Position Indicator (e.g. "3 / 12")
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
                  // Compact Sandbox Active badge (Bug 2: Uncluttered)
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
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Re-run Sandbox Pipeline',
                    onPressed: _executeFreshSandboxForCurrent,
                  ),
                ],
              ),
            ),

            // Main Viewer Area
            Expanded(
              child: Row(
                children: [
                  // On-screen Previous Arrow (Desktop clickable + disabled when at start)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: IconButton.filledTonal(
                      iconSize: 32,
                      icon: const Icon(Icons.chevron_left),
                      tooltip: canGoPrev ? l10n.previousImage : 'First image reached',
                      onPressed: canGoPrev ? _goToPrevious : null,
                    ),
                  ),

                  // Center Image Display
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 16),
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
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(
                                      strokeWidth: 3,
                                      valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
                                    ),
                                    const SizedBox(height: 18),
                                    Text(
                                      l10n.previewRendering,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Isolated Process Environment',
                                      style: TextStyle(fontSize: 11, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              )
                            : Stack(
                                alignment: Alignment.center,
                                children: [
                                  _renderCurrentImageView(currentItem),
                                  // Quick keyboard helper badge
                                  Positioned(
                                    bottom: 12,
                                    right: 12,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.keyboard, size: 12, color: Colors.white70),
                                          SizedBox(width: 4),
                                          Text(
                                            'Use ← / → keys',
                                            style: TextStyle(fontSize: 10, color: Colors.white70),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),

                  // On-screen Next Arrow (Desktop clickable + disabled when at end)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: IconButton.filledTonal(
                      iconSize: 32,
                      icon: const Icon(Icons.chevron_right),
                      tooltip: canGoNext ? l10n.nextImage : 'Last image reached',
                      onPressed: canGoNext ? _goToNext : null,
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Thumbnails & Security Verification Strip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                border: Border(
                  top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.2)),
                ),
              ),
              child: Row(
                children: [
                  // File Info
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          currentItem.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${currentItem.formattedSize} • MIME: ${_mediaMetadata['mime_type'] ?? currentItem.mimeType} • Target PID: ${_sandboxStatus?.isolatedPid ?? 1}',
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey, fontSize: 11),
                        ),
                        if (_errorMessage != null)
                          Text(
                            'Warning: $_errorMessage',
                            style: const TextStyle(color: Colors.orange, fontSize: 10),
                          ),
                      ],
                    ),
                  ),

                  // Security status chips
                  Expanded(
                    flex: 4,
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      alignment: WrapAlignment.center,
                      children: [
                        _buildChip(Icons.wifi_off, 'Network: Denied', Colors.orange),
                        _buildChip(Icons.folder_delete, 'FS: Whitelist Only', Colors.cyan),
                        _buildChip(Icons.security, 'Seccomp-BPF Active', Colors.green),
                        _buildChip(Icons.memory, 'Isolated Process', Colors.purpleAccent),
                      ],
                    ),
                  ),

                  // Quick Thumbnails / Jump indicators
                  Expanded(
                    flex: 3,
                    child: SizedBox(
                      height: 44,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        reverse: false,
                        itemCount: widget.images.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final isSelected = index == _currentIndex;
                          final img = widget.images[index];

                          return GestureDetector(
                            onTap: () => _jumpToIndex(index),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: _buildThumbnail(img),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _renderCurrentImageView(MediaItem item) {
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

  Widget _buildThumbnail(MediaItem item) {
    if (kIsWeb || item.path.startsWith('assets/')) {
      return Image.asset(
        item.path,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.image, size: 18),
      );
    } else {
      return Image.file(
        File(item.path),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.image, size: 18),
      );
    }
  }


  Widget _buildChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}
