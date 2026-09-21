import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/media_item.dart';

import 'desktop/desktop_home_screen.dart';
import 'desktop/desktop_image_gallery_screen.dart';
import 'desktop/desktop_language_screen.dart';
import 'desktop/desktop_settings_screen.dart';
import 'desktop/desktop_splash_screen.dart';
import 'desktop/desktop_theme_screen.dart';
import 'desktop/desktop_video_player_screen.dart';

import 'mobile/mobile_home_screen.dart';
import 'mobile/mobile_image_gallery_screen.dart';
import 'mobile/mobile_language_screen.dart';
import 'mobile/mobile_settings_screen.dart';
import 'mobile/mobile_splash_screen.dart';
import 'mobile/mobile_theme_screen.dart';
import 'mobile/mobile_video_player_screen.dart';

import 'web/web_home_screen.dart';
import 'web/web_image_gallery_screen.dart';
import 'web/web_language_screen.dart';
import 'web/web_settings_screen.dart';
import 'web/web_splash_screen.dart';
import 'web/web_theme_screen.dart';
import 'web/web_video_player_screen.dart';

class AdaptiveScreenHelper {
  static bool get isDesktop {
    if (kIsWeb) return false;
    return Platform.isLinux || Platform.isWindows || Platform.isMacOS;
  }

  static bool get isMobile {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  // 1. Splash Screen
  static Widget getSplashScreen() {
    if (kIsWeb) return const WebSplashScreen();
    if (isDesktop) return const DesktopSplashScreen();
    return const MobileSplashScreen();
  }

  // 2. Language Screen
  static Widget getLanguageScreen() {
    if (kIsWeb) return const WebLanguageScreen();
    if (isDesktop) return const DesktopLanguageScreen();
    return const MobileLanguageScreen();
  }

  // 3. Theme Screen
  static Widget getThemeScreen() {
    if (kIsWeb) return const WebThemeScreen();
    if (isDesktop) return const DesktopThemeScreen();
    return const MobileThemeScreen();
  }

  // 4. Home Screen
  static Widget getHomeScreen() {
    if (kIsWeb) return const WebHomeScreen();
    if (isDesktop) return const DesktopHomeScreen();
    return const MobileHomeScreen();
  }

  // 5. Settings Screen
  static Widget getSettingsScreen() {
    if (kIsWeb) return const WebSettingsScreen();
    if (isDesktop) return const DesktopSettingsScreen();
    return const MobileSettingsScreen();
  }

  // 6. Multi-Image Sandboxed Gallery Screen
  static Widget getImageGalleryScreen({
    required List<MediaItem> images,
    int initialIndex = 0,
  }) {
    if (kIsWeb) {
      return WebImageGalleryScreen(images: images, initialIndex: initialIndex);
    }
    if (isDesktop) {
      return DesktopImageGalleryScreen(images: images, initialIndex: initialIndex);
    }
    return MobileImageGalleryScreen(images: images, initialIndex: initialIndex);
  }

  // 7. Multi-Video Sandboxed Playlist Player Screen
  static Widget getVideoPlayerScreen({
    required List<MediaItem> videos,
    int initialIndex = 0,
  }) {
    if (kIsWeb) {
      return WebVideoPlayerScreen(videos: videos, initialIndex: initialIndex);
    }
    if (isDesktop) {
      return DesktopVideoPlayerScreen(videos: videos, initialIndex: initialIndex);
    }
    return MobileVideoPlayerScreen(videos: videos, initialIndex: initialIndex);
  }
}

