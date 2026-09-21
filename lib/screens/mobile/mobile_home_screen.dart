import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/media_item.dart';
import '../../services/project_manager.dart';
import '../../services/sandbox/sandbox_manager.dart';
import '../../widgets/sandboxed_preview_dialog.dart';
import '../adaptive_screen_helper.dart';

class MobileHomeScreen extends StatefulWidget {
  const MobileHomeScreen({super.key});

  @override
  State<MobileHomeScreen> createState() => _MobileHomeScreenState();
}

class _MobileHomeScreenState extends State<MobileHomeScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final projectManager = ProjectManager.instance;
    final activeProject = projectManager.activeProject;
    final mechanism = SandboxManager.instance.mechanismLabel;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 26,
              height: 26,
              margin: const EdgeInsets.only(right: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(
                  'assets/icon/export_64x64.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Icon(Icons.shield, color: theme.colorScheme.primary, size: 22),
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
              onTap: () => _showSecurityDetailsSheet(context, l10n, theme, mechanism),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
          ),
          const SizedBox(width: 4),
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
        ],
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: projectManager,
          builder: (context, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Main Project Content (uncluttered, banner removed)
                Expanded(
                  child: activeProject == null || activeProject.items.isEmpty
                      ? _buildEmptyState(context, l10n, theme)
                      : _buildMediaGrid(context, activeProject, l10n, theme),
                ),

                // Bottom Action Bar: Create Project Entry Points
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color,
                    border: Border(
                      top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.2)),
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton.filledTonal(
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
                        icon: const Icon(Icons.photo_library),
                        tooltip: l10n.selectImages,
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
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
                        icon: const Icon(Icons.video_library),
                        tooltip: l10n.selectVideos,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showCreateProjectSheet(context, l10n, theme),
                          icon: const Icon(Icons.add_photo_alternate, size: 20),
                          label: Text(l10n.createProject),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        onPressed: () {
                          projectManager.addSampleProject();
                        },
                        icon: const Icon(Icons.auto_awesome),
                        tooltip: 'Load Sample Safe Session',
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_open_outlined, size: 64, color: theme.colorScheme.primary.withValues(alpha: 0.6)),
            const SizedBox(height: 18),
            Text(
              l10n.noProjectsYet,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.createProjectDesc,
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => _showCreateProjectSheet(context, l10n, theme),
              icon: const Icon(Icons.create_new_folder),
              label: Text(l10n.createProject),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaGrid(
    BuildContext context,
    SafeProject project,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 480 ? 3 : 2;

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            project.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            l10n.mediaFilesCount(project.items.length),
                            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => _showCreateProjectSheet(context, l10n, theme),
                      tooltip: l10n.createProject,
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(12),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = project.items[index];
                    return _buildMediaCard(context, item, theme, l10n);
                  },
                  childCount: project.items.length,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMediaCard(
    BuildContext context,
    MediaItem item,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        final activeProject = ProjectManager.instance.activeProject;
        _openMediaItem(context, item, activeProject);
      },
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: theme.brightness == Brightness.dark
                      ? const Color(0xFF1B1D20)
                      : const Color(0xFFE6E7EB),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                ),
                child: Center(
                  child: Icon(
                    item.type == MediaType.image
                        ? Icons.image
                        : (item.type == MediaType.video ? Icons.movie : Icons.audiotrack),
                    size: 36,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.formattedSize,
                        style: TextStyle(fontSize: 10, color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'SAFE',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontSize: 9,
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
  }

  void _showCreateProjectSheet(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Material(
            color: theme.cardTheme.color,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.createProject,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.createProjectDesc,
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
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
                    leading: const Icon(Icons.folder),
                    title: Text(l10n.openFolder),
                    subtitle: const Text('Inspect entire directory inside isolated sandbox'),
                    onTap: () async {
                      Navigator.pop(ctx);
                      await ProjectManager.instance.pickFolderAndCreateProject();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.insert_drive_file),
                    title: Text(l10n.selectFiles),
                    subtitle: const Text('Pick individual image and video files'),
                    onTap: () async {
                      Navigator.pop(ctx);
                      await ProjectManager.instance.pickFilesAndCreateProject();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.auto_awesome),
                    title: const Text('Sample Media Session'),
                    subtitle: const Text('Load pre-configured sample files for quick verification'),
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
      },
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

  void _showSecurityDetailsSheet(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
    String mechanism,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(Icons.shield, color: theme.colorScheme.primary, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      'Sandbox Security Details',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Active',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color,
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
                const SizedBox(height: 14),
                Text(
                  l10n.securityGuarantees,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                _buildSecurityItem(Icons.wifi_off, l10n.networkDenied, Colors.orange),
                _buildSecurityItem(Icons.folder_off, l10n.fsRestricted, Colors.cyan),
                _buildSecurityItem(Icons.verified, l10n.syscallFilter, Colors.green),
                _buildSecurityItem(Icons.layers, l10n.processIsolation, Colors.purpleAccent),
                const SizedBox(height: 16),
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
                  icon: const Icon(Icons.verified_user, size: 18),
                  label: Text(l10n.testSandboxSecurity),
                ),
              ],
            ),
          ),
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
              style: const TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

