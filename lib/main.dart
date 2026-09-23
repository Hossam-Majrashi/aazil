import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'l10n/app_localizations.dart';
import 'screens/adaptive_screen_helper.dart';
import 'theme/app_theme.dart';
import 'theme/locale_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;
  runApp(AazilApp(onboardingComplete: onboardingComplete));
}

class AazilApp extends StatefulWidget {
  final bool onboardingComplete;

  const AazilApp({super.key, this.onboardingComplete = false});

  @override
  State<AazilApp> createState() => _AazilAppState();
}

class _AazilAppState extends State<AazilApp> {
  final ThemeController _themeController = ThemeController.instance;
  final LocaleController _localeController = LocaleController.instance;

  @override
  void initState() {
    super.initState();
    _themeController.addListener(_onStateChange);
    _localeController.addListener(_onStateChange);
  }

  @override
  void dispose() {
    _themeController.removeListener(_onStateChange);
    _localeController.removeListener(_onStateChange);
    super.dispose();
  }

  void _onStateChange() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aazil (عازل)',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeController.themeMode,
      locale: _localeController.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: widget.onboardingComplete
          ? AdaptiveScreenHelper.getHomeScreen()
          : AdaptiveScreenHelper.getSplashScreen(),
    );
  }
}
