import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/translations.dart';

class LanguageProvider with ChangeNotifier {
  String _languageCode = 'en';

  String get languageCode => _languageCode;

  /// Human-readable name for the current language
  String get languageName {
    const names = {
      'en': 'English',
      'vi': 'Tiếng Việt',
      'zh': 'Chinese',
      'es': 'Spanish',
      'fr': 'French',
      'de': 'German',
      'ja': 'Japanese',
      'ko': 'Korean',
      'pt': 'Portuguese',
      'it': 'Italian',
      'ru': 'Russian',
      'ar': 'Arabic',
      'hi': 'Hindi',
      'th': 'Thai',
      'id': 'Indonesian',
    };
    return names[_languageCode] ?? 'English';
  }

  LanguageProvider() {
    _loadLanguage();
  }

  /// Load saved language from SharedPreferences
  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    _languageCode = prefs.getString('app_language') ?? 'en';
    notifyListeners();
  }

  /// Set language, persist, and notify all listeners so the UI rebuilds
  Future<void> setLanguage(String code) async {
    if (_languageCode == code) return;
    _languageCode = code;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', code);
  }

  /// Translate a key using the current language.
  /// Falls back to English if the key or language is not found.
  String translate(String key) {
    final entry = translations[key];
    if (entry == null) return key; // key not in map → return raw key
    return entry[_languageCode] ?? entry['en'] ?? key;
  }
}
