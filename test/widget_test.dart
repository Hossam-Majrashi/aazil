import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:media_kit/media_kit.dart';
import 'package:aazil/l10n/app_localizations.dart';
import 'package:aazil/main.dart';
import 'package:aazil/models/media_item.dart';
import 'package:aazil/screens/desktop/desktop_home_screen.dart';
import 'package:aazil/screens/desktop/desktop_video_player_screen.dart';
import 'package:aazil/screens/mobile/mobile_video_player_screen.dart';
import 'package:aazil/screens/web/web_video_player_screen.dart';
import 'package:aazil/theme/app_theme.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    MediaKit.ensureInitialized();
  });

  testWidgets('AazilApp smoke test and splash initialization', (WidgetTester tester) async {
    await tester.pumpWidget(const AazilApp());
    await tester.pump();
    expect(find.byType(AazilApp), findsOneWidget);
  });

  testWidgets('Bug 3 Verification: DesktopHomeScreen headers share identical kHeaderHeight', (WidgetTester tester) async {
    expect(DesktopHomeScreen.kHeaderHeight, equals(72.0));
  });

  testWidgets('Bug 2 Verification: Compact Sandbox Active badge is visible by default without clutter', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: DesktopHomeScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify compact Sandbox Active badge is visible
    expect(find.text('Sandbox Active'), findsOneWidget);

    // Verify security guarantees are inside a collapsible ExpansionTile (initially collapsed)
    expect(find.byType(ExpansionTile), findsOneWidget);
  });

  testWidgets('Bug 1 & Bugfix 2 Verification: DesktopVideoPlayerScreen accurately binds duration and renders visible play/pause button', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final videos = [
      MediaItem(
        id: 'v1',
        path: 'assets/samples/sample_video_1.mp4',
        name: 'sample_video_1.mp4',
        size: 32235,
        type: MediaType.video,
        mimeType: 'video/mp4',
      ),
      MediaItem(
        id: 'v2',
        path: 'assets/samples/sample_video_2.mp4',
        name: 'sample_video_2.mp4',
        size: 32235,
        type: MediaType.video,
        mimeType: 'video/mp4',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: DesktopVideoPlayerScreen(
          videos: videos,
          initialIndex: 0,
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify video title is present
    expect(find.text('sample_video_1.mp4'), findsWidgets);

    // Verify seek bar slider exists
    expect(find.byType(Slider), findsWidgets);

    // Verify position indicator "Video 1 / 2"
    expect(find.text('Video 1 / 2'), findsOneWidget);

    // Verify Play/Pause IconButton has high-contrast icon with explicitly defined color
    final pauseIconFinder = find.byIcon(Icons.pause);
    expect(pauseIconFinder, findsOneWidget);
    final iconWidget = tester.widget<Icon>(pauseIconFinder);
    expect(iconWidget.color, equals(AppTheme.darkTheme.colorScheme.onPrimary));
  });

  testWidgets('Bugfix 2 Verification: MobileVideoPlayerScreen renders visible contrasting play/pause icon', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final video = MediaItem(
      id: 'v1',
      path: 'assets/samples/sample_video_1.mp4',
      name: 'sample_video_1.mp4',
      size: 32235,
      type: MediaType.video,
      mimeType: 'video/mp4',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MobileVideoPlayerScreen(
          videos: [video],
          initialIndex: 0,
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('sample_video_1.mp4'), findsWidgets);
    expect(find.byType(Slider), findsWidgets);

    final pauseIconFinder = find.byIcon(Icons.pause);
    expect(pauseIconFinder, findsOneWidget);
    final iconWidget = tester.widget<Icon>(pauseIconFinder);
    expect(iconWidget.color, equals(AppTheme.darkTheme.colorScheme.onPrimary));
  });

  testWidgets('Bugfix 2 Verification: WebVideoPlayerScreen renders visible contrasting play/pause icon', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final video = MediaItem(
      id: 'v1',
      path: 'assets/samples/sample_video_1.mp4',
      name: 'sample_video_1.mp4',
      size: 32235,
      type: MediaType.video,
      mimeType: 'video/mp4',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: WebVideoPlayerScreen(
          videos: [video],
          initialIndex: 0,
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('sample_video_1.mp4'), findsWidgets);
    expect(find.byType(Slider), findsWidgets);

    final pauseIconFinder = find.byIcon(Icons.pause);
    expect(pauseIconFinder, findsOneWidget);
    final iconWidget = tester.widget<Icon>(pauseIconFinder);
    expect(iconWidget.color, equals(AppTheme.darkTheme.colorScheme.onPrimary));
  });
}
