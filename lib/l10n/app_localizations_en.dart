// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Aazil';

  @override
  String get appSubtitle => 'Sandboxed Media Viewer';

  @override
  String get appDescription =>
      'Securely inspect and play untrusted images and videos inside an OS-level isolated sandbox box. Protect your host device from media exploits and malicious payloads.';

  @override
  String get splashContinue => 'Continue';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get languageSubtitle => 'Choose your preferred language';

  @override
  String get selectTheme => 'Select Theme';

  @override
  String get themeSubtitle => 'Choose application appearance';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get lightMode => 'Light Mode';

  @override
  String get homeTitle => 'Aazil Workspace';

  @override
  String get createProject => 'Create Project';

  @override
  String get createProjectDesc =>
      'Open a folder or select media files to inspect safely inside an isolated sandbox session.';

  @override
  String get settings => 'Settings';

  @override
  String get settingsDesc =>
      'View isolation parameters, sandbox status, and environment diagnostics.';

  @override
  String get about => 'About';

  @override
  String get sandboxStatus => 'Sandbox Engine';

  @override
  String get sandboxActive => 'Active & Enforced';

  @override
  String get securityGuarantees => 'Security Guarantees';

  @override
  String get networkDenied => 'Network Access: DENIED';

  @override
  String get fsRestricted =>
      'Filesystem: RESTRICTED (Whitelisted file copy only)';

  @override
  String get syscallFilter => 'Syscall Filter: SECCOMP-BPF ACTIVE';

  @override
  String get processIsolation =>
      'Process Isolation: UNPRIVILEGED / LOW-INTEGRITY';

  @override
  String get recentProjects => 'Recent Safe Sessions';

  @override
  String get noProjectsYet =>
      'No projects opened yet. Create a new safe session to begin.';

  @override
  String get openFolder => 'Open Folder';

  @override
  String get selectFiles => 'Select Media Files';

  @override
  String mediaFilesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count media files',
      one: '1 media file',
      zero: 'No media files',
    );
    return '$_temp0';
  }

  @override
  String get sandboxedPreview => 'Sandboxed Preview';

  @override
  String get previewLoading => 'Initializing isolated sandbox...';

  @override
  String get previewRendering => 'Decoding media in isolated sandbox...';

  @override
  String get previewCleaning =>
      'Terminating sandbox and purging temporary buffers...';

  @override
  String get previewReady => 'Isolated Render Completed';

  @override
  String get closePreview => 'Close & Destroy Sandbox';

  @override
  String get testSandboxSecurity => 'Run Sandbox Security Test';

  @override
  String get testResultsTitle => 'Isolation Test Results';

  @override
  String get testPassed => 'PASSED (Threat Blocked)';

  @override
  String get testFailed => 'FAILED';

  @override
  String get networkBlockedTest => 'Network Connection Attempt';

  @override
  String get fsBlockedTest => 'Out-of-whitelist File Read Attempt';

  @override
  String get dangerWarning =>
      'Isolated Environment — Zero host access permitted';

  @override
  String get fileDetails => 'File Details';

  @override
  String get fileName => 'File Name';

  @override
  String get fileSize => 'File Size';

  @override
  String get fileType => 'Type';

  @override
  String sandboxInfoLabel(String mechanism) {
    return 'Sandbox: $mechanism';
  }

  @override
  String get selectImages => 'Select Images';

  @override
  String get selectVideos => 'Select Videos';

  @override
  String get multiImageViewer => 'Sandboxed Image Gallery';

  @override
  String get multiVideoPlaylist => 'Sandboxed Video Playlist';

  @override
  String get previousImage => 'Previous Image';

  @override
  String get nextImage => 'Next Image';

  @override
  String get previousVideo => 'Previous Video';

  @override
  String get nextVideo => 'Next Video';

  @override
  String get play => 'Play';

  @override
  String get pause => 'Pause';

  @override
  String get mute => 'Mute';

  @override
  String get unmute => 'Unmute';

  @override
  String get volume => 'Volume';

  @override
  String get repeatMode => 'Repeat Mode';

  @override
  String get repeatOff => 'Repeat: Off';

  @override
  String get repeatOne => 'Repeat: Current Video';

  @override
  String get repeatAll => 'Repeat: All Videos';

  @override
  String get playlist => 'Playlist';

  @override
  String imagePosition(int current, int total) {
    return 'Image $current / $total';
  }

  @override
  String videoPosition(int current, int total) {
    return 'Video $current / $total';
  }

  @override
  String get swipeHint => 'Swipe left/right or use keyboard arrows to navigate';

  @override
  String get developer => 'Developer';
}
