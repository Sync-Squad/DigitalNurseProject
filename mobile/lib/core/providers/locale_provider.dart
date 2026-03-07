import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider with ChangeNotifier {
  static const String _localeKey = 'app_locale';
  static const String _defaultLocale = 'en';

  Locale _locale = const Locale(_defaultLocale);
  bool _isInitialized = false;

  Locale get locale => _locale;
  bool get isInitialized => _isInitialized;
  String get localeCode => _locale.languageCode;

  LocaleProvider() {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLocaleCode = prefs.getString(_localeKey);

      if (savedLocaleCode != null && _isValidLocale(savedLocaleCode)) {
        _locale = Locale(savedLocaleCode);
      } else {
        _locale = const Locale(_defaultLocale);
      }

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      _locale = const Locale(_defaultLocale);
      _isInitialized = true;
      notifyListeners();
    }
  }

  bool _isValidLocale(String localeCode) {
    return localeCode == 'en' || localeCode == 'ur';
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale || !_isValidLocale(locale.languageCode)) return;

    _locale = locale;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localeKey, locale.languageCode);
    } catch (e) {
      debugPrint('Failed to save locale: $e');
    }
  }

  Future<void> setLocaleFromCode(String localeCode) async {
    if (!_isValidLocale(localeCode)) return;
    await setLocale(Locale(localeCode));
  }

  // Convenience methods
  Future<void> setEnglish() => setLocaleFromCode('en');
  Future<void> setUrdu() => setLocaleFromCode('ur');

  // Get locale display name
  String get localeDisplayName {
    switch (_locale.languageCode) {
      case 'en':
        return 'English';
      case 'ur':
        return 'اردو';
      default:
        return 'English';
    }
  }

  // Get all available locales for UI selection
  List<LocaleOption> get localeOptions => [
    LocaleOption(locale: const Locale('en'), name: 'English', code: 'en'),
    LocaleOption(locale: const Locale('ur'), name: 'اردو', code: 'ur'),
  ];
}

class LocaleOption {
  final Locale locale;
  final String name;
  final String code;

  const LocaleOption({
    required this.locale,
    required this.name,
    required this.code,
  });
}
