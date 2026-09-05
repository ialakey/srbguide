import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  static const String _key = 'selectedLanguage';
  static const List<String> supported = <String>['ru', 'en'];

  SharedPreferences? _prefs;
  Locale _selectedLocale = const Locale('ru', '');

  Locale get selectedLocale => _selectedLocale;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final String? saved = _prefs?.getString(_key);
    _selectedLocale = Locale(
      saved != null && supported.contains(saved) ? saved : _deviceDefault(),
      '',
    );
    notifyListeners();
  }

  /// The guide itself is written in Russian, so Russian is the default unless
  /// the device is explicitly set to a language we also ship (English).
  String _deviceDefault() {
    final String system =
        PlatformDispatcher.instance.locale.languageCode.toLowerCase();
    return system == 'en' ? 'en' : 'ru';
  }

  void updateLocale(Locale newLocale) {
    if (!supported.contains(newLocale.languageCode)) return;
    _selectedLocale = newLocale;
    _prefs?.setString(_key, newLocale.languageCode);
    notifyListeners();
  }
}
