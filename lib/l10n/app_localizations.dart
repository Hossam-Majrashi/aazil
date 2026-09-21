import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Aazil'**
  String get appName;

  /// No description provided for @appSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sandboxed Media Viewer'**
  String get appSubtitle;

  /// No description provided for @appDescription.
  ///
  /// In en, this message translates to:
  /// **'Securely inspect and play untrusted images and videos inside an OS-level isolated sandbox box. Protect your host device from media exploits and malicious payloads.'**
  String get appDescription;

  /// No description provided for @splashContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get splashContinue;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @languageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred language'**
  String get languageSubtitle;

  /// No description provided for @selectTheme.
  ///
  /// In en, this message translates to:
  /// **'Select Theme'**
  String get selectTheme;

  /// No description provided for @themeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose application appearance'**
  String get themeSubtitle;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get lightMode;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Aazil Workspace'**
  String get homeTitle;

  /// No description provided for @createProject.
  ///
  /// In en, this message translates to:
  /// **'Create Project'**
  String get createProject;

  /// No description provided for @createProjectDesc.
  ///
  /// In en, this message translates to:
  /// **'Open a folder or select media files to inspect safely inside an isolated sandbox session.'**
  String get createProjectDesc;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @settingsDesc.
  ///
  /// In en, this message translates to:
  /// **'View isolation parameters, sandbox status, and environment diagnostics.'**
  String get settingsDesc;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @sandboxStatus.
  ///
  /// In en, this message translates to:
  /// **'Sandbox Engine'**
  String get sandboxStatus;

  /// No description provided for @sandboxActive.
  ///
  /// In en, this message translates to:
  /// **'Active & Enforced'**
  String get sandboxActive;

  /// No description provided for @securityGuarantees.
  ///
  /// In en, this message translates to:
  /// **'Security Guarantees'**
  String get securityGuarantees;

  /// No description provided for @networkDenied.
  ///
  /// In en, this message translates to:
  /// **'Network Access: DENIED'**
  String get networkDenied;

  /// No description provided for @fsRestricted.
  ///
  /// In en, this message translates to:
  /// **'Filesystem: RESTRICTED (Whitelisted file copy only)'**
  String get fsRestricted;

  /// No description provided for @syscallFilter.
  ///
  /// In en, this message translates to:
  /// **'Syscall Filter: SECCOMP-BPF ACTIVE'**
  String get syscallFilter;

  /// No description provided for @processIsolation.
  ///
  /// In en, this message translates to:
  /// **'Process Isolation: UNPRIVILEGED / LOW-INTEGRITY'**
  String get processIsolation;

  /// No description provided for @recentProjects.
  ///
  /// In en, this message translates to:
  /// **'Recent Safe Sessions'**
  String get recentProjects;

  /// No description provided for @noProjectsYet.
  ///
  /// In en, this message translates to:
  /// **'No projects opened yet. Create a new safe session to begin.'**
  String get noProjectsYet;

  /// No description provided for @openFolder.
  ///
  /// In en, this message translates to:
  /// **'Open Folder'**
  String get openFolder;

  /// No description provided for @selectFiles.
  ///
  /// In en, this message translates to:
  /// **'Select Media Files'**
  String get selectFiles;

  /// No description provided for @mediaFilesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No media files} =1{1 media file} other{{count} media files}}'**
  String mediaFilesCount(int count);

  /// No description provided for @sandboxedPreview.
  ///
  /// In en, this message translates to:
  /// **'Sandboxed Preview'**
  String get sandboxedPreview;

  /// No description provided for @previewLoading.
  ///
  /// In en, this message translates to:
  /// **'Initializing isolated sandbox...'**
  String get previewLoading;

  /// No description provided for @previewRendering.
  ///
  /// In en, this message translates to:
  /// **'Decoding media in isolated sandbox...'**
  String get previewRendering;

  /// No description provided for @previewCleaning.
  ///
  /// In en, this message translates to:
  /// **'Terminating sandbox and purging temporary buffers...'**
  String get previewCleaning;

  /// No description provided for @previewReady.
  ///
  /// In en, this message translates to:
  /// **'Isolated Render Completed'**
  String get previewReady;

  /// No description provided for @closePreview.
  ///
  /// In en, this message translates to:
  /// **'Close & Destroy Sandbox'**
  String get closePreview;

  /// No description provided for @testSandboxSecurity.
  ///
  /// In en, this message translates to:
  /// **'Run Sandbox Security Test'**
  String get testSandboxSecurity;

  /// No description provided for @testResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'Isolation Test Results'**
  String get testResultsTitle;

  /// No description provided for @testPassed.
  ///
  /// In en, this message translates to:
  /// **'PASSED (Threat Blocked)'**
  String get testPassed;

  /// No description provided for @testFailed.
  ///
  /// In en, this message translates to:
  /// **'FAILED'**
  String get testFailed;

  /// No description provided for @networkBlockedTest.
  ///
  /// In en, this message translates to:
  /// **'Network Connection Attempt'**
  String get networkBlockedTest;

  /// No description provided for @fsBlockedTest.
  ///
  /// In en, this message translates to:
  /// **'Out-of-whitelist File Read Attempt'**
  String get fsBlockedTest;

  /// No description provided for @dangerWarning.
  ///
  /// In en, this message translates to:
  /// **'Isolated Environment — Zero host access permitted'**
  String get dangerWarning;

  /// No description provided for @fileDetails.
  ///
  /// In en, this message translates to:
  /// **'File Details'**
  String get fileDetails;

  /// No description provided for @fileName.
  ///
  /// In en, this message translates to:
  /// **'File Name'**
  String get fileName;

  /// No description provided for @fileSize.
  ///
  /// In en, this message translates to:
  /// **'File Size'**
  String get fileSize;

  /// No description provided for @fileType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get fileType;

  /// No description provided for @sandboxInfoLabel.
  ///
  /// In en, this message translates to:
  /// **'Sandbox: {mechanism}'**
  String sandboxInfoLabel(String mechanism);

  /// No description provided for @selectImages.
  ///
  /// In en, this message translates to:
  /// **'Select Images'**
  String get selectImages;

  /// No description provided for @selectVideos.
  ///
  /// In en, this message translates to:
  /// **'Select Videos'**
  String get selectVideos;

  /// No description provided for @multiImageViewer.
  ///
  /// In en, this message translates to:
  /// **'Sandboxed Image Gallery'**
  String get multiImageViewer;

  /// No description provided for @multiVideoPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Sandboxed Video Playlist'**
  String get multiVideoPlaylist;

  /// No description provided for @previousImage.
  ///
  /// In en, this message translates to:
  /// **'Previous Image'**
  String get previousImage;

  /// No description provided for @nextImage.
  ///
  /// In en, this message translates to:
  /// **'Next Image'**
  String get nextImage;

  /// No description provided for @previousVideo.
  ///
  /// In en, this message translates to:
  /// **'Previous Video'**
  String get previousVideo;

  /// No description provided for @nextVideo.
  ///
  /// In en, this message translates to:
  /// **'Next Video'**
  String get nextVideo;

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @mute.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get mute;

  /// No description provided for @unmute.
  ///
  /// In en, this message translates to:
  /// **'Unmute'**
  String get unmute;

  /// No description provided for @volume.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get volume;

  /// No description provided for @repeatMode.
  ///
  /// In en, this message translates to:
  /// **'Repeat Mode'**
  String get repeatMode;

  /// No description provided for @repeatOff.
  ///
  /// In en, this message translates to:
  /// **'Repeat: Off'**
  String get repeatOff;

  /// No description provided for @repeatOne.
  ///
  /// In en, this message translates to:
  /// **'Repeat: Current Video'**
  String get repeatOne;

  /// No description provided for @repeatAll.
  ///
  /// In en, this message translates to:
  /// **'Repeat: All Videos'**
  String get repeatAll;

  /// No description provided for @playlist.
  ///
  /// In en, this message translates to:
  /// **'Playlist'**
  String get playlist;

  /// No description provided for @imagePosition.
  ///
  /// In en, this message translates to:
  /// **'Image {current} / {total}'**
  String imagePosition(int current, int total);

  /// No description provided for @videoPosition.
  ///
  /// In en, this message translates to:
  /// **'Video {current} / {total}'**
  String videoPosition(int current, int total);

  /// No description provided for @swipeHint.
  ///
  /// In en, this message translates to:
  /// **'Swipe left/right or use keyboard arrows to navigate'**
  String get swipeHint;

  /// No description provided for @developer.
  ///
  /// In en, this message translates to:
  /// **'Developer'**
  String get developer;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
