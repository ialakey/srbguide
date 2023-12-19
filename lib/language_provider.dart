import 'package:flutter/material.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _selectedLocale = const Locale('ru', '');

  Locale get selectedLocale => _selectedLocale;

  void updateLocale(Locale newLocale) {
    _selectedLocale = newLocale;
    notifyListeners();
  }
}