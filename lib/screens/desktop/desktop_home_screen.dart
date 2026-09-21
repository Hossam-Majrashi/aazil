import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/media_item.dart';
import '../../services/project_manager.dart';
import '../../services/sandbox/sandbox_manager.dart';
import '../../widgets/sandboxed_preview_dialog.dart';
import '../adaptive_screen_helper.dart';

class DesktopHomeScreen extends StatefulWidget {
  static const double kHeaderHeight = 72.0;

  const DesktopHomeScreen({super.key});

  @override
  State<DesktopHomeScreen> createState() => _DesktopHomeScreenState();
}

class _DesktopHomeScreenState extends State<DesktopHomeScreen> {
  static const double kHeaderHeight = DesktopHomeScreen.kHeaderHeight;
  MediaItem? _selectedItem;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final projectManager = ProjectManager.instance;
    final mechanism = SandboxManager.instance.mechanismLabel;

    return Scaffold(
      body: AnimatedBuilder(
        animation: projectManager,
        builder: (context, _) {
          final activeProject = projectManager.activeProject;

          return LayoutBuilder(
            builder: (context, constraints) {
              final showRightPane = constraints.maxWidth > 950;

              return Row(
                children: [
                  // Left Pane: Navigation & Project Sessions
                  _buildSidebar(context, l10n, theme, mechanism, projectManager),

                  // Center Pane: Media Files Workspace
                  Expanded(
                    flex: 6,
                    child: Container(
                      color: theme.scaffoldBackgroundColor,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Top bar (height kHeaderHeight with bottom border aligned to sidebar)
                          _buildTopBar(context, l10n, theme, activeProject),

                          // Workspace Grid / Empty
                          Expanded(
                            child: activeProject == null || activeProject.items.isEmpty
                                ? _buildEmptyWorkspace(l10n, theme)
                                : _buildMediaGrid(context, activeProject, theme, l10n),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Right Pane: Inspector & Security Guarantees
                  if (showRightPane)
                    _buildInspectorPane(context, l10n, theme, mechanism),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSidebar(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
    String mechanism,
    ProjectManager projectManager,
  ) {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: theme.dividerColor.withValues(alpha: 0.2)),
        ),
      ),
      child: Material(
        color: theme.cardTheme.color,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          // App Brand Header (height kHeaderHeight with bottom border aligned to workspace top bar)
          Container(
            height: kHeaderHeight,
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.2), width: 1.0),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.25),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      'assets/icon/export_64x64.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.shield, color: theme.colorScheme.primary, size: 22),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.appName,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                      ),
                      Text(
                        l10n.appSubtitle,
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Action: Create Project
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () => _openCreateProjectDialog(context, l10n, theme),
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: Text(l10n.createProject),
            ),
          ),

          // Sessions List Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              l10n.recentProjects,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                letterSpacing: 0.5,
              ),
            ),
          ),

          // Sessions
          Expanded(
            child: projectManager.projects.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        l10n.noProjectsYet,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: projectManager.projects.length,
                    itemBuilder: (context, index) {
                      final p = projectManager.projects[index];
                      final isActive = projectManager.activeProject?.id == p.id;

                      return ListTile(
                        dense: true,
                        selected: isActive,
                        selectedTileColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                        leading: Icon(
                          Icons.folder,
                          color: isActive ? theme.colorScheme.primary : Colors.grey,
                          size: 20,
                        ),
                        title: Text(
                          p.name,
                          style: TextStyle(
                            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          l10n.mediaFilesCount(p.items.length),
                          style: const TextStyle(fontSize: 11),
                        ),
                        onTap: () {
                          projectManager.setActiveProject(p);
                        },
                      );
                    },
                  ),
          ),

          // Quick sample session loader
          ListTile(
            dense: true,
            leading: const Icon(Icons.auto_awesome, size: 18),
            title: const Text('Load Sample Safe Session', style: TextStyle(fontSize: 12)),
            onTap: () => projectManager.addSampleProject(),
          ),
          const Divider(height: 1),

          // Bottom Settings / Status
          ListTile(
            leading: const Icon(Icons.settings_outlined, size: 20),
            title: Text(l10n.settings, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AdaptiveScreenHelper.getSettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
    ),
  );
}

  Widget _buildTopBar(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
    SafeProject? project,
  ) {
    return Container(
      height: kHeaderHeight,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.2), width: 1.0),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project?.name ?? l10n.homeTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (project != null)
                  Text(
                    '${project.folderPath} • ${l10n.mediaFilesCount(project.items.length)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Primary action buttons: visually dominant and uncluttered
          Flexible(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                    onPressed: () => _openCreateProjectDialog(context, l10n, theme),
                    icon: const Icon(Icons.create_new_folder, size: 18),
                    label: Text(l10n.createProject),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWorkspace(AppLocalizations l10n, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.security, size: 64, color: theme.colorScheme.primary.withValues(alpha: 0.5)),
          const SizedBox(height: 18),
          Text(
            l10n.noProjectsYet,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.createProjectDesc,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            children: [
              ElevatedButton.icon(
                onPressed: () async {
                  final images = await ProjectManager.instance.pickMultipleImages();
                  if (images.isNotEmpty && mounted) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AdaptiveScreenHelper.getImageGalleryScreen(images: images),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.photo_library),
                label: Text(l10n.selectImages),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  final videos = await ProjectManager.instance.pickMultipleVideos();
                  if (videos.isNotEmpty && mounted) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AdaptiveScreenHelper.getVideoPlayerScreen(videos: videos),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.video_library),
                label: Text(l10n.selectVideos),
              ),
              OutlinedButton.icon(
                onPressed: () => _openCreateProjectDialog(context, l10n, theme),
                icon: const Icon(Icons.create_new_folder),
                label: Text(l10n.createProject),
              ),
            ],
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
        final crossAxisCount = (constraints.maxWidth / 220).clamp(2, 6).toInt();

        return GridView.builder(
          padding: const EdgeInsets.all(20),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.82,
          ),
          itemCount: project.items.length,
          itemBuilder: (context, index) {
            final item = project.items[index];
            final isSelected = _selectedItem?.id == item.id;

            return InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                setState(() => _selectedItem = item);
              },
              onDoubleTap: () {
                _openMediaItem(context, item, project);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.dividerColor.withValues(alpha: 0.2),
                    width: isSelected ? 2.5 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.brightness == Brightness.dark
                              ? const Color(0xFF1B1D20)
                              : const Color(0xFFE8E9ED),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                        ),
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
                              Text(
                                item.formattedSize,
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.shield, size: 11, color: theme.colorScheme.primary),
                                    const SizedBox(width: 3),
                                    Text(
                                      'SAFE',
                                      style: TextStyle(
                                        color: theme.colorScheme.primary,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
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

  Widget _buildInspectorPane(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
    String mechanism,
  ) {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: theme.dividerColor.withValues(alpha: 0.2)),
        ),
      ),
      child: Material(
        color: theme.cardTheme.color,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Inspector Header (height kHeaderHeight with bottom border aligned to workspace top bar)
            Container(
              height: kHeaderHeight,
              padding: const EdgeInsets.symmetric(horizontal: 14.0),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.2), width: 1.0),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.shield_outlined, color: theme.colorScheme.primary, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Sandbox Security',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Single most important sandbox-status indicator visible by default
                  _buildCompactSandboxBadge(theme),
                ],
              ),
            ),

            // Inspector Body
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // Compact Status Summary Card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.dividerColor.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.verified_outlined, size: 20, color: theme.colorScheme.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.sandboxInfoLabel(mechanism),
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Zero host network & isolated filesystem',
                                style: TextStyle(fontSize: 10, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Collapsible Detailed Security Status Breakdown (uncluttered on demand)
                  Card(
                    elevation: 0,
                    color: theme.scaffoldBackgroundColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.15)),
                    ),
                    child: Theme(
                      data: theme.copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        initiallyExpanded: false,
                        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        leading: Icon(Icons.security, size: 18, color: theme.colorScheme.primary),
                        title: Text(
                          l10n.securityGuarantees,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        subtitle: const Text(
                          'View isolation breakdown',
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                        children: [
                          _buildSecurityItem(Icons.wifi_off, l10n.networkDenied, Colors.orange),
                          _buildSecurityItem(Icons.folder_off, l10n.fsRestricted, Colors.cyan),
                          _buildSecurityItem(Icons.verified, l10n.syscallFilter, Colors.green),
                          _buildSecurityItem(Icons.layers, l10n.processIsolation, Colors.purpleAccent),
                          const SizedBox(height: 10),
                          ElevatedButton.icon(
                            onPressed: () async {
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
                            icon: const Icon(Icons.verified_user, size: 14),
                            label: Text(l10n.testSandboxSecurity, style: const TextStyle(fontSize: 11)),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  if (_selectedItem != null) ...[
                    const Divider(),
                    Text(
                      l10n.fileDetails,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    Text('${l10n.fileName}: ${_selectedItem!.name}', style: const TextStyle(fontSize: 11)),
                    Text('${l10n.fileSize}: ${_selectedItem!.formattedSize}', style: const TextStyle(fontSize: 11)),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () {
                        final activeProject = ProjectManager.instance.activeProject;
                        _openMediaItem(context, _selectedItem!, activeProject);
                      },
                      icon: const Icon(Icons.play_arrow, size: 16),
                      label: Text(l10n.sandboxedPreview),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactSandboxBadge(ThemeData theme) {
    return Container(
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

  Widget _buildSecurityItem(IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  void _openCreateProjectDialog(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
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
                leading: const Icon(Icons.folder_open),
                title: Text(l10n.openFolder),
                subtitle: const Text('Select a folder to isolate and preview'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await ProjectManager.instance.pickFolderAndCreateProject();
                },
              ),
              ListTile(
                leading: const Icon(Icons.insert_drive_file),
                title: Text(l10n.selectFiles),
                subtitle: const Text('Choose specific media files for safe session'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await ProjectManager.instance.pickFilesAndCreateProject();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

