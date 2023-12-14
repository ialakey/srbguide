import 'package:flutter/material.dart';
import 'package:quickalert/quickalert.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:srbguide/main.dart';
import 'package:srbguide/widget/themed_icon.dart';

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

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
      _prefs!.setBool('isDarkMode', _isDarkMode);
      _updateThemeMode(_isDarkMode);
    });
  }

  void _updateThemeMode(bool isDarkMode) {
    ThemeMode newThemeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    _prefs!.setBool('isDarkMode', isDarkMode);
    final mainScreen = MainScreen.of(context);
    mainScreen?.setThemeMode(newThemeMode);
  }

  Future<void> _clearSharedPreferences() async {
    await _prefs?.clear();
    setState(() {
      _isDarkMode = false;
    });
    QuickAlert.show(
      context: context,
      type: QuickAlertType.success,
      title: 'Очищено!',
    );
  }

  _showDialog() {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.confirm,
      title: 'Подтверждение',
      text: 'Вы уверены, что хотите очистить данные?',
      showConfirmBtn: true,
      confirmBtnText: 'Да',
      cancelBtnText: 'Нет',
      onConfirmBtnTap: () {
        _clearSharedPreferences();
        Navigator.of(context).pop();
      },
      onCancelBtnTap: () {
        Navigator.of(context).pop();
      },
      showCancelBtn: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    String buttonText = _isDarkMode ? 'Светлая тема' : 'Темная тема';

    return Scaffold(
      body: _prefs == null
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildCard(
              buttonText,
              ThemedIcon(
                lightIcon: 'assets/icons_24x24/moon-stars.png',
                darkIcon: 'assets/icons_24x24/sun.png',
                size: 24.0,
              ),
              _toggleTheme,
            ),
            SizedBox(height: 20),
            _buildCard(
              'Очистить данные',
              ThemedIcon(
                lightIcon: 'assets/icons_24x24/trash.png',
                darkIcon: 'assets/icons_24x24/trash.png',
                size: 24.0,
              ),
              _showDialog,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(String title, Widget icon, Function() onTap) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(12.0),
          child: Row(
            children: [
              SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(width: 10),
              icon,
            ],
          ),
        ),
      ),
    );
  }
}