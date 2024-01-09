import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quickalert/quickalert.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:srbguide/app_localizations.dart';
import 'package:srbguide/helper/text_size_dialog.dart';
import 'package:srbguide/language_provider.dart';
import 'package:srbguide/main.dart';
import 'package:srbguide/widget/app_bar.dart';
import 'package:srbguide/widget/drawer/drawer.dart';
import 'package:srbguide/widget/themed_icon.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  SharedPreferences? _prefs;
  bool _isDarkMode = false;
  double _currentTextSize = 13.0;

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
    return prefs.getDouble('textSize') ?? 13.0;
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

  @override
  Widget build(BuildContext context) {
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
            SizedBox(height: 4),
            _buildLanguageCard(context),
            SizedBox(height: 4),
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
              icon,
              SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageCard(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    String languageCode = languageProvider.selectedLocale.languageCode;
    String languageName = '';
    switch (languageCode) {
      case 'ru':
        languageName = AppLocalizations.of(context)!.translate('russian');
        break;
      case 'en':
        languageName = AppLocalizations.of(context)!.translate('english');
        break;
    }

    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: () => _showLanguageDialog(context, languageProvider),
        child: Padding(
          padding: EdgeInsets.all(12.0),
          child: Row(
            children: [
              ThemedIcon(
                lightIcon: 'assets/icons_24x24/globe.png',
                darkIcon: 'assets/icons_24x24/globe.png',
                size: 24.0,
              ),
              SizedBox(width: 12),
              Text(
                AppLocalizations.of(context)!.translate('language'),
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(width: 10),
              Spacer(),
              Text(
                  languageName,
                  style: TextStyle(fontWeight: FontWeight.bold),
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
          title: Text(AppLocalizations.of(context)!.translate('language')),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SingleChildScrollView(
                child: Column(
                  children: [
                    _buildLanguageOption(context, languageProvider, AppLocalizations.of(context)!.translate('english'), Locale('en', ''), setState),
                    _buildLanguageOption(context, languageProvider, AppLocalizations.of(context)!.translate('russian'), Locale('ru', ''), setState),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(BuildContext context, LanguageProvider languageProvider, String languageName, Locale locale, StateSetter setState) {
    return RadioListTile<Locale>(
      title: Text(languageName),
      value: locale,
      groupValue: languageProvider.selectedLocale,
      onChanged: (Locale? value) {
        if (value != null) {
          languageProvider.updateLocale(value);
          Navigator.of(context).pop();
          setState(() {});
        }
      },
    );
  }
}