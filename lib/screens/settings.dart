import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quickalert/quickalert.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:srbguide/app_localizations.dart';
import 'package:srbguide/helper/text_size_dialog.dart';
import 'package:srbguide/language_provider.dart';
import 'package:srbguide/main.dart';
import 'package:srbguide/widget/app_bar.dart';
import 'package:srbguide/widget/drawer.dart';
import 'package:srbguide/widget/themed_icon.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  SharedPreferences? _prefs;
  bool _isDarkMode = false;
  double _currentTextSize = 18.0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadSavedTextSize();
    Provider.of<LanguageProvider>(context, listen: false).init();
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
      title: '${AppLocalizations.of(context)!.translate('cleared')}!',
    );
  }

  _showDialog() {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.confirm,
      title: AppLocalizations.of(context)!.translate('confirmation'),
      text: AppLocalizations.of(context)!.translate('confirm_clear_data'),
      showConfirmBtn: true,
      confirmBtnText: AppLocalizations.of(context)!.translate('yes'),
      cancelBtnText: AppLocalizations.of(context)!.translate('no'),
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

  Future<void> _saveTextSize(double textSize) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('textSize', textSize);
  }

  Future<double> _loadTextSize() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('textSize') ?? 18.0;
  }

  Future<void> _loadSavedTextSize() async {
    double savedTextSize = await _loadTextSize();
    setState(() {
      _currentTextSize = savedTextSize;
    });
  }

  void _setTextSize(double value) {
    setState(() {
      _currentTextSize = value;
    });
    _saveTextSize(value);
  }

  _changeTextSize() {
    DialogHelper.showTextSizeDialog(
      context,
      _currentTextSize,
      _setTextSize,
    );
  }

  //TODO почему то загружаются по всей видимости все экраны когда меняю тему (слишком медленно)
  @override
  Widget build(BuildContext context) {
    //String buttonText = _isDarkMode ? AppLocalizations.of(context)!.translate('light_theme') : AppLocalizations.of(context)!.translate('dark_theme');

    return Scaffold(
      appBar:
      CustomAppBar(
        title: AppLocalizations.of(context)!.translate('settings'),
      ),
      drawer: AppDrawer(),
      body: _prefs == null
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildCard(
              AppLocalizations.of(context)!.translate('change_size_text'),
              ThemedIcon(
                lightIcon: 'assets/icons_24x24/letter-case.png',
                darkIcon: 'assets/icons_24x24/letter-case.png',
                size: 24.0,
              ),
              _changeTextSize,
            ),
            SizedBox(height: 18),
            // _buildCard(
            //   buttonText,
            //   ThemedIcon(
            //     lightIcon: 'assets/icons_24x24/moon-stars.png',
            //     darkIcon: 'assets/icons_24x24/sun.png',
            //     size: 24.0,
            //   ),
            //   _toggleTheme,
            // ),
            // SizedBox(height: 20),
            _buildLanguageCard(context),
            SizedBox(height: 18),
            _buildCard(
              AppLocalizations.of(context)!.translate('clear_data'),
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

  Widget _buildLanguageCard(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: () => _showLanguageDialog(context, languageProvider),
        child: Padding(
          padding: EdgeInsets.all(12.0),
          child: Row(
            children: [
              SizedBox(width: 10),
              Text(
                AppLocalizations.of(context)!.translate('change_language'),
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(width: 10),
              ThemedIcon(
                lightIcon: 'assets/icons_24x24/globe.png',
                darkIcon: 'assets/icons_24x24/globe.png',
                size: 24.0,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, LanguageProvider languageProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.translate('select_language'),),
          content: SingleChildScrollView(
            child: Column(
              children: [
                _buildLanguageOption(context, languageProvider, AppLocalizations.of(context)!.translate('english'), Locale('en', '')),
                _buildLanguageOption(context, languageProvider, AppLocalizations.of(context)!.translate('russian'), Locale('ru', '')),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(BuildContext context, LanguageProvider languageProvider, String languageName, Locale locale) {
    return ListTile(
      title: Text(languageName),
      onTap: () {
        languageProvider.updateLocale(locale);
        Navigator.of(context).pop();
      },
    );
  }
}