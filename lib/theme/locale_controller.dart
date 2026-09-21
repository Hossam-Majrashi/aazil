import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleController extends ChangeNotifier {
  static final LocaleController instance = LocaleController._internal();

  Locale _locale = const Locale('ar'); // Default to Arabic (RTL)

  LocaleController._internal() {
    _loadLocale();
  }

  Locale get locale => _locale;
  bool get isRtl => _locale.languageCode == 'ar';

  Future<void> _loadLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString('app_locale') ?? 'ar';
      _locale = Locale(code);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> setLocale(Locale newLocale) async {
    _locale = newLocale;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_locale', newLocale.languageCode);
    } catch (_) {}
  }
}
