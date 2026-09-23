import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/media_item.dart';

class SafeProject {
  final String id;
  final String name;
  final String folderPath;
  final DateTime createdAt;
  List<MediaItem> items;

  SafeProject({
    required this.id,
    required this.name,
    required this.folderPath,
    required this.createdAt,
    this.items = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'folderPath': folderPath,
    'createdAt': createdAt.toIso8601String(),
    'itemCount': items.length,
  };

  factory SafeProject.fromJson(Map<String, dynamic> json) => SafeProject(
    id: json['id'] as String,
    name: json['name'] as String,
    folderPath: json['folderPath'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    items: [],
  );
}

class ProjectManager extends ChangeNotifier {
  static final ProjectManager instance = ProjectManager._internal();

  ProjectManager._internal() {
    _loadSavedProjects();
  }

  final List<SafeProject> _projects = [];
  SafeProject? _activeProject;

  List<SafeProject> get projects => List.unmodifiable(_projects);
  SafeProject? get activeProject => _activeProject;

  void setActiveProject(SafeProject project) {
    _activeProject = project;
    notifyListeners();
  }

  Future<void> _loadSavedProjects() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('saved_projects') ?? [];
      _projects.clear();
      for (final item in list) {
        _projects.add(SafeProject.fromJson(jsonDecode(item)));
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _persistProjects() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _projects.map((p) => jsonEncode(p.toJson())).toList();
      await prefs.setStringList('saved_projects', list);
    } catch (_) {}
  }

  Future<SafeProject?> pickFolderAndCreateProject() async {
    try {
      final selectedDirectory = await FilePicker.getDirectoryPath();
      if (selectedDirectory == null) return null;

      final dir = Directory(selectedDirectory);
      final dirName = dir.uri.pathSegments.isNotEmpty
          ? dir.uri.pathSegments.where((s) => s.isNotEmpty).last
          : 'Safe Media Session';

      final project = SafeProject(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: dirName,
        folderPath: selectedDirectory,
        createdAt: DateTime.now(),
      );

      final mediaFiles = <MediaItem>[];
      if (dir.existsSync()) {
        final entries = dir.listSync();
        for (final entry in entries) {
          if (entry is File) {
            final filename = entry.uri.pathSegments.last;
            final type = MediaItem.detectType(filename);
            if (type != MediaType.unknown) {
              mediaFiles.add(
                MediaItem(
                  id: entry.path,
                  path: entry.path,
                  name: filename,
                  size: entry.lengthSync(),
                  type: type,
                  mimeType: 'media',
                ),
              );
            }
          }
        }
      }

      project.items = mediaFiles;
      _projects.insert(0, project);
      _activeProject = project;
      await _persistProjects();
      notifyListeners();
      return project;
    } catch (e) {
      return null;
    }
  }

  Future<SafeProject?> pickFilesAndCreateProject() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.any,
      );
      if (files.isEmpty) return null;

      final project = SafeProject(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'Selected Files Session (${files.length})',
        folderPath: 'Custom Selection',
        createdAt: DateTime.now(),
      );

      final mediaFiles = <MediaItem>[];
      for (final f in files) {
        if (f.path != null) {
          final type = MediaItem.detectType(f.name);
          mediaFiles.add(
            MediaItem(
              id: f.path!,
              path: f.path!,
              name: f.name,
              size: f.lengthSync() ?? 0,
              type: type,
              mimeType: 'media',
            ),
          );
        }
      }

      project.items = mediaFiles;
      _projects.insert(0, project);
      _activeProject = project;
      await _persistProjects();
      notifyListeners();
      return project;
    } catch (_) {
      return null;
    }
  }

  /// Pick multiple images directly for sandboxed gallery viewing.
  Future<List<MediaItem>> pickMultipleImages() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg', 'webp', 'gif', 'bmp'],
      );
      if (files.isEmpty) return [];

      final items = <MediaItem>[];
      for (final f in files) {
        if (f.path != null) {
          items.add(
            MediaItem(
              id: f.path!,
              path: f.path!,
              name: f.name,
              size: f.lengthSync() ?? 0,
              type: MediaType.image,
              mimeType: 'image/${f.extension ?? 'png'}',
            ),
          );
        }
      }
      return items;
    } catch (_) {
      return [];
    }
  }

  /// Pick multiple videos directly for sandboxed playlist playback.
  Future<List<MediaItem>> pickMultipleVideos() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp4', 'mkv', 'avi', 'mov', 'webm', 'flv', 'wmv', 'm4v', 'ts', '3gp'],
      );
      if (files.isEmpty) return [];

      final items = <MediaItem>[];
      for (final f in files) {
        if (f.path != null) {
          items.add(
            MediaItem(
              id: f.path!,
              path: f.path!,
              name: f.name,
              size: f.lengthSync() ?? 0,
              type: MediaType.video,
              mimeType: 'video/${f.extension ?? 'mp4'}',
            ),
          );
        }
      }
      return items;
    } catch (_) {
      return [];
    }
  }

  void addSampleProject() {
    final sample = SafeProject(
      id: 'sample_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Sample Safe Session (Images & Videos)',
      folderPath: 'assets/samples & assets/icon',
      createdAt: DateTime.now(),
      items: [
        MediaItem(
          id: 'sample_icon_128',
          path: 'assets/icon/export_128x128.png',
          name: 'export_128x128.png',
          size: 8010,
          type: MediaType.image,
          mimeType: 'image/png',
        ),
        MediaItem(
          id: 'sample_icon_256',
          path: 'assets/icon/export_256x256.png',
          name: 'export_256x256.png',
          size: 16738,
          type: MediaType.image,
          mimeType: 'image/png',
        ),
        MediaItem(
          id: 'sample_icon_512',
          path: 'assets/icon/export_512x512.png',
          name: 'export_512x512.png',
          size: 32265,
          type: MediaType.image,
          mimeType: 'image/png',
        ),
        MediaItem(
          id: 'sample_icon_1024',
          path: 'assets/icon/export_1024x1024.png',
          name: 'export_1024x1024.png',
          size: 67842,
          type: MediaType.image,
          mimeType: 'image/png',
        ),
        MediaItem(
          id: 'sample_video_1',
          path: 'assets/samples/sample_video_1.mp4',
          name: 'sample_video_1.mp4',
          size: 32768,
          type: MediaType.video,
          mimeType: 'video/mp4',
        ),
        MediaItem(
          id: 'sample_video_2',
          path: 'assets/samples/sample_video_2.mp4',
          name: 'sample_video_2.mp4',
          size: 32768,
          type: MediaType.video,
          mimeType: 'video/mp4',
        ),
        MediaItem(
          id: 'sample_video_3',
          path: 'assets/samples/sample_video_3.mp4',
          name: 'sample_video_3.mp4',
          size: 32768,
          type: MediaType.video,
          mimeType: 'video/mp4',
        ),
      ],
    );

    _projects.insert(0, sample);
    _activeProject = sample;
    _persistProjects();
    notifyListeners();
  }
}

