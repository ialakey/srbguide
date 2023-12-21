import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  late SharedPreferences _prefs;
  late Locale _selectedLocale;

  Locale get selectedLocale => _selectedLocale;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    String? savedLanguage = _prefs.getString('selectedLanguage');
    _selectedLocale = savedLanguage != null ? Locale(savedLanguage) : const Locale('en', ''); // Default to 'en' if no language is saved
    notifyListeners();
  }

  void updateLocale(Locale newLocale) {
    _selectedLocale = newLocale;
    _prefs.setString('selectedLanguage', newLocale.languageCode);
    notifyListeners();
  }
}