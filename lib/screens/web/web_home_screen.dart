import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/media_item.dart';
import '../../services/project_manager.dart';
import '../../services/sandbox/sandbox_manager.dart';
import '../../widgets/sandboxed_preview_dialog.dart';
import '../adaptive_screen_helper.dart';

class WebHomeScreen extends StatefulWidget {
  const WebHomeScreen({super.key});

  @override
  State<WebHomeScreen> createState() => _WebHomeScreenState();
}

class _WebHomeScreenState extends State<WebHomeScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final projectManager = ProjectManager.instance;
    final mechanism = SandboxManager.instance.mechanismLabel;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(right: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(
                  'assets/icon/export_64x64.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Icon(Icons.shield, color: theme.colorScheme.primary),
                ),
              ),
            ),
            Text(l10n.appName),
          ],
        ),
        actions: [
          // Single most important sandbox-status indicator visible by default
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _showSecurityDialog(context, l10n, theme, mechanism),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: l10n.settings,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AdaptiveScreenHelper.getSettingsScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: AnimatedBuilder(
        animation: projectManager,
        builder: (context, _) {
          final activeProject = projectManager.activeProject;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Action Bar: Prominent primary buttons
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.2)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    activeProject?.name ?? l10n.homeTitle,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    l10n.createProjectDesc,
                                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                            FilledButton.icon(
                              onPressed: () async {
                                final images = await ProjectManager.instance.pickMultipleImages();
                                if (images.isNotEmpty && context.mounted) {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => AdaptiveScreenHelper.getImageGalleryScreen(images: images),
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.photo_library, size: 18),
                              label: Text(l10n.selectImages),
                            ),
                            const SizedBox(width: 10),
                            FilledButton.icon(
                              onPressed: () async {
                                final videos = await ProjectManager.instance.pickMultipleVideos();
                                if (videos.isNotEmpty && context.mounted) {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => AdaptiveScreenHelper.getVideoPlayerScreen(videos: videos),
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.video_library, size: 18),
                              label: Text(l10n.selectVideos),
                            ),
                            const SizedBox(width: 10),
                            OutlinedButton.icon(
                              onPressed: () => _openCreateProjectDialog(context, l10n),
                              icon: const Icon(Icons.add_photo_alternate, size: 18),
                              label: Text(l10n.createProject),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Media Grid or Empty State
                    Expanded(
                      child: activeProject == null || activeProject.items.isEmpty
                          ? _buildEmptyState(context, l10n, theme)
                          : _buildMediaGrid(context, activeProject, theme, l10n),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.folder_open, size: 72, color: theme.colorScheme.primary.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            l10n.noProjectsYet,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.createProjectDesc,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _openCreateProjectDialog(context, l10n),
            icon: const Icon(Icons.add),
            label: Text(l10n.createProject),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaGrid(
    BuildContext context,
    SafeProject project,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = (constraints.maxWidth / 240).clamp(2, 5).toInt();

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.85,
          ),
          itemCount: project.items.length,
          itemBuilder: (context, index) {
            final item = project.items[index];

            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () {
                  _openMediaItem(context, item, project);
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Container(
                        color: theme.brightness == Brightness.dark
                            ? const Color(0xFF1B1D20)
                            : const Color(0xFFE8E9ED),
                        child: Center(
                          child: Icon(
                            item.type == MediaType.image
                                ? Icons.image
                                : (item.type == MediaType.video ? Icons.movie : Icons.audiotrack),
                            size: 48,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(item.formattedSize, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'PREVIEW',
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openCreateProjectDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.createProject),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text(l10n.selectImages),
                subtitle: const Text('Pick multiple images for sandboxed gallery'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final images = await ProjectManager.instance.pickMultipleImages();
                  if (images.isNotEmpty && context.mounted) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AdaptiveScreenHelper.getImageGalleryScreen(images: images),
                      ),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.video_library),
                title: Text(l10n.selectVideos),
                subtitle: const Text('Pick multiple videos for sandboxed playlist'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final videos = await ProjectManager.instance.pickMultipleVideos();
                  if (videos.isNotEmpty && context.mounted) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AdaptiveScreenHelper.getVideoPlayerScreen(videos: videos),
                      ),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.insert_drive_file),
                title: Text(l10n.selectFiles),
                subtitle: const Text('Pick files to analyze securely in safe session'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await ProjectManager.instance.pickFilesAndCreateProject();
                },
              ),
              ListTile(
                leading: const Icon(Icons.auto_awesome),
                title: const Text('Sample Media Session'),
                subtitle: const Text('Load sample images & videos into isolated session'),
                onTap: () {
                  Navigator.pop(ctx);
                  ProjectManager.instance.addSampleProject();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openMediaItem(BuildContext context, MediaItem item, SafeProject? project) {
    if (item.type == MediaType.image) {
      final images = project != null
          ? project.items.where((i) => i.type == MediaType.image).toList()
          : [item];
      final idx = images.indexWhere((i) => i.id == item.id);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AdaptiveScreenHelper.getImageGalleryScreen(
            images: images.isNotEmpty ? images : [item],
            initialIndex: idx >= 0 ? idx : 0,
          ),
        ),
      );
    } else if (item.type == MediaType.video) {
      final videos = project != null
          ? project.items.where((i) => i.type == MediaType.video).toList()
          : [item];
      final idx = videos.indexWhere((i) => i.id == item.id);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AdaptiveScreenHelper.getVideoPlayerScreen(
            videos: videos.isNotEmpty ? videos : [item],
            initialIndex: idx >= 0 ? idx : 0,
          ),
        ),
      );
    } else {
      SandboxedPreviewDialog.show(context, item);
    }
  }

  void _showSecurityDialog(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
    String mechanism,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.shield, color: theme.colorScheme.primary),
              const SizedBox(width: 10),
              const Text('Sandbox Security Details'),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Active',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    l10n.sandboxInfoLabel(mechanism),
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.securityGuarantees,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 10),
                _buildSecurityItem(Icons.wifi_off, l10n.networkDenied, Colors.orange),
                _buildSecurityItem(Icons.folder_off, l10n.fsRestricted, Colors.cyan),
                _buildSecurityItem(Icons.verified, l10n.syscallFilter, Colors.green),
                _buildSecurityItem(Icons.layers, l10n.processIsolation, Colors.purpleAccent),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(ctx);
                final status = await SandboxManager.instance.runSecurityTest();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(status.statusDescription),
                      backgroundColor: Colors.green.shade800,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.verified_user, size: 16),
              label: Text(l10n.testSandboxSecurity),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSecurityItem(IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

