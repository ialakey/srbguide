import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:srbguide/main.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  SharedPreferences? _prefs;
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    _isDarkMode = _prefs!.getBool('isDarkMode') ?? false;
    if (mounted) {
      setState(() {});
    }
  }

  void _toggleTheme(bool isDarkMode) {
    setState(() {
      _isDarkMode = isDarkMode;
      _prefs!.setBool('isDarkMode', isDarkMode);
      _updateThemeMode(isDarkMode);
    });
  }

  void _updateThemeMode(bool isDarkMode) {
    ThemeMode newThemeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    _prefs!.setBool('isDarkMode', isDarkMode);
    final mainScreen = MainScreen.of(context);
    mainScreen?.setThemeMode(newThemeMode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Настройки')),
      body: _prefs == null
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SwitchListTile(
              title: Text('Темная тема'),
              value: _isDarkMode,
              onChanged: (value) => _toggleTheme(value),
            ),
          ],
        ),
      ),
    );
  }
}