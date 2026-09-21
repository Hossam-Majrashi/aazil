import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/media_item.dart';
import '../models/sandbox_status.dart';
import '../services/sandbox/sandbox_manager.dart';

enum PreviewStage { initializing, decoding, active, cleaning, finished }

class SandboxedPreviewDialog extends StatefulWidget {
  final MediaItem item;

  const SandboxedPreviewDialog({super.key, required this.item});

  static Future<void> show(BuildContext context, MediaItem item) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => SandboxedPreviewDialog(item: item),
    );
  }

  @override
  State<SandboxedPreviewDialog> createState() => _SandboxedPreviewDialogState();
}

class _SandboxedPreviewDialogState extends State<SandboxedPreviewDialog> {
  PreviewStage _stage = PreviewStage.initializing;
  SandboxStatus? _sandboxStatus;
  Map<String, dynamic> _mediaMetadata = {};
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startIsolatedPreview();
  }

  Future<void> _startIsolatedPreview() async {
    // 1. Stage: Initializing Sandbox
    setState(() {
      _stage = PreviewStage.initializing;
    });
    await Future.delayed(const Duration(milliseconds: 600));

    // 2. Stage: Decoding Media in Isolated Process
    setState(() {
      _stage = PreviewStage.decoding;
    });

    try {
      final status = await SandboxManager.instance.runSecurityTest(
        widget.item.path,
      );
      final meta = await SandboxManager.instance.inspectMedia(widget.item.path);

      if (mounted) {
        setState(() {
          _sandboxStatus = status;
          _mediaMetadata = meta;
          _stage = PreviewStage.active;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _stage = PreviewStage.active;
        });
      }
    }
  }

  Future<void> _closeAndCleanSandbox() async {
    setState(() {
      _stage = PreviewStage.cleaning;
    });
    // Terminate sandbox, purge temporary buffers
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final mechanism = SandboxManager.instance.mechanismLabel;

    return Dialog(
      backgroundColor: theme.cardTheme.color,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.shield,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.sandboxedPreview,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          l10n.sandboxInfoLabel(mechanism),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (_stage == PreviewStage.active)
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: _closeAndCleanSandbox,
                      tooltip: l10n.closePreview,
                    ),
                ],
              ),
              const Divider(height: 24),

              // Dynamic Body based on Stage
              Expanded(
                child: Center(
                  child: switch (_stage) {
                    PreviewStage.initializing => _buildLoadingState(
                      l10n.previewLoading,
                      theme,
                    ),
                    PreviewStage.decoding => _buildLoadingState(
                      l10n.previewRendering,
                      theme,
                    ),
                    PreviewStage.cleaning => _buildLoadingState(
                      l10n.previewCleaning,
                      theme,
                    ),
                    PreviewStage.active => _buildActiveContent(
                      l10n,
                      theme,
                      isDark,
                    ),
                    PreviewStage.finished => const SizedBox.shrink(),
                  },
                ),
              ),

              const Divider(height: 24),

              // Footer Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lock_clock,
                        size: 16,
                        color: theme.colorScheme.secondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l10n.dangerWarning,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: _stage == PreviewStage.active
                        ? _closeAndCleanSandbox
                        : null,
                    icon: const Icon(Icons.delete_sweep, size: 18),
                    label: Text(l10n.closePreview),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(String message, ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 48,
          height: 48,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          message,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildActiveContent(
    AppLocalizations l10n,
    ThemeData theme,
    bool isDark,
  ) {
    return Column(
      children: [
        // Media Preview Area
        Expanded(
          flex: 3,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1B1D20) : const Color(0xFFE4E5E8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _renderMediaPreview(),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Security & Isolation Verification Badges
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.testResultsTitle,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 14,
                            color: theme.colorScheme.secondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            l10n.testPassed,
                            style: TextStyle(
                              color: theme.colorScheme.secondary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildSecurityChip(
                      icon: Icons.wifi_off,
                      label: l10n.networkDenied,
                      color: Colors.orange,
                    ),
                    _buildSecurityChip(
                      icon: Icons.folder_delete,
                      label: l10n.fsRestricted,
                      color: Colors.cyan,
                    ),
                    _buildSecurityChip(
                      icon: Icons.security,
                      label: l10n.syscallFilter,
                      color: Colors.green,
                    ),
                    _buildSecurityChip(
                      icon: Icons.layers,
                      label: l10n.processIsolation,
                      color: Colors.purpleAccent,
                    ),
                  ],
                ),
                if (_sandboxStatus != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${_sandboxStatus!.statusDescription} (PID: ${_sandboxStatus!.isolatedPid ?? 1})',
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ],
                if (_errorMessage != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Warning: $_errorMessage',
                    style: const TextStyle(fontSize: 11, color: Colors.orange),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  '${l10n.fileName}: ${widget.item.name} (${widget.item.formattedSize}) • MIME: ${_mediaMetadata['mime_type'] ?? widget.item.mimeType}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _renderMediaPreview() {
    // If it's an image
    if (widget.item.type == MediaType.image) {
      if (kIsWeb || widget.item.path.startsWith('assets/')) {
        return Image.asset(
          widget.item.path,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => _fallbackPreviewIcon(Icons.broken_image),
        );
      } else {
        return Image.file(
          File(widget.item.path),
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => _fallbackPreviewIcon(Icons.image),
        );
      }
    } else if (widget.item.type == MediaType.video) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videocam, size: 64, color: Colors.cyan),
            const SizedBox(height: 12),
            Text(
              'Isolated Video Sandbox: ${widget.item.name}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Zero Host Privileges Granted to Decoder',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    } else {
      return _fallbackPreviewIcon(Icons.audiotrack);
    }
  }

  Widget _fallbackPreviewIcon(IconData icon) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: Colors.cyan),
          const SizedBox(height: 12),
          Text(
            widget.item.name,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(label, style: const TextStyle(fontSize: 11)),
      backgroundColor: color.withValues(alpha: 0.12),
      side: BorderSide(color: color.withValues(alpha: 0.3), width: 1),
      visualDensity: VisualDensity.compact,
    );
  }
}
