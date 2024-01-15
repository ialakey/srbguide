import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:srbguide/localization/app_localizations.dart';
import 'package:srbguide/dialogs/text_size_dialog.dart';
import 'package:srbguide/provider/language_provider.dart';
import 'package:srbguide/service/url_launcher_helper.dart';
import 'package:srbguide/widget/app_bar.dart';
import 'package:srbguide/dialogs/confirm.dart';
import 'package:srbguide/dialogs/success.dart';
import 'package:srbguide/widget/drawer/drawer.dart';
import 'package:srbguide/widget/themed/themed_icon.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  SharedPreferences? _prefs;
  double _currentTextSize = 13.0;
  String _selectedScreen = 'VisaFreeCalculatorScreen';

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadSavedTextSize();
    _loadSelectedScreen();
    Provider.of<LanguageProvider>(context, listen: false).init();
  }

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> _clearSharedPreferences() async {
    await _prefs?.clear();
    CustomSuccessDialog.show(
      context: context,
      title: '${AppLocalizations.of(context)!.translate('cleared')}!',
    );
  }

  _showDialog() {
    CustomConfirmationDialog.show(
      context: context,
      title: AppLocalizations.of(context)!.translate('confirmation'),
      text: AppLocalizations.of(context)!.translate('confirm_clear_data'),
      iconPath: 'assets/gifs_24x24/warning.gif',
      confirmBtnText: AppLocalizations.of(context)!.translate('yes'),
      cancelBtnText: AppLocalizations.of(context)!.translate('no'),
      onConfirmBtnTap: () {
        _clearSharedPreferences();
        Navigator.of(context).pop();
      },
      onCancelBtnTap: () {
        Navigator.of(context).pop();
      },
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

  _setTextSize(double value) {
    setState(() {
      _currentTextSize = value;
    });
    _saveTextSize(value);
  }

  _changeTextSize() {
    DialogHelper.show(
      context,
      _currentTextSize,
      _setTextSize,
    );
  }

  _openPrivacyPolicy() {
    UrlLauncherHelper.launchURL('https://github.com/ialakey/privacy_policy');
  }

  Future<void> _loadSelectedScreen() async {
    _prefs = await SharedPreferences.getInstance();
    String savedScreen = _prefs?.getString('selectedScreen') ?? 'VisaFreeCalculatorScreen';
    setState(() {
      _selectedScreen = savedScreen;
    });
  }

  _saveSelectedScreen(String screen) async {
    setState(() {
      _selectedScreen = screen;
    });
    await _prefs?.setString('selectedScreen', screen);
  }

  void _showScreenDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.translate('main_screen')),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SingleChildScrollView(
                child: Column(
                  children: [
                    _buildScreenOption(context, 'VisaFreeCalculatorScreen', AppLocalizations.of(context)!.translate('calculator_visarun')),
                    _buildScreenOption(context, 'CreateWhiteCardboardScreen', AppLocalizations.of(context)!.translate('create_whiteboard')),
                    _buildScreenOption(context, 'GuideScreen', AppLocalizations.of(context)!.translate('guide')),
                    _buildScreenOption(context, 'TgChatScreen', AppLocalizations.of(context)!.translate('tg_chats')),
                    _buildScreenOption(context, 'MapScreen', AppLocalizations.of(context)!.translate('maps')),
                    _buildScreenOption(context, 'ExchangeRateScreen', AppLocalizations.of(context)!.translate('exchange_rate')),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
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
            _buildSectionHeader(AppLocalizations.of(context)!.translate('settings')),
            _buildLanguageCard(context),
            _buildCard(
              AppLocalizations.of(context)!.translate('main_screen'),
              ThemedIcon(
                iconPath: 'assets/icons_24x24/eye.png',
                size: 24.0,
              ),
              () => _showScreenDialog(context),
            ),
            _buildSectionHeader(AppLocalizations.of(context)!.translate('guide')),
            _buildCard(
              AppLocalizations.of(context)!.translate('change_size_text'),
              ThemedIcon(
                iconPath: 'assets/icons_24x24/text.png',
                size: 24.0,
              ),
              _changeTextSize,
            ),
            _buildSectionHeader(AppLocalizations.of(context)!.translate('data')),
            _buildCard(
              AppLocalizations.of(context)!.translate('clear_data'),
              ThemedIcon(
                iconPath: 'assets/icons_24x24/trash.png',
                size: 24.0,
              ),
              _showDialog,
            ),
            _buildCard(
              AppLocalizations.of(context)!.translate('privacy_policy'),
              ThemedIcon(
                iconPath: 'assets/icons_24x24/shield-check.png',
                size: 24.0,
              ),
              _openPrivacyPolicy,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
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
                iconPath: 'assets/icons_24x24/globe.png',
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

  _showLanguageDialog(BuildContext context, LanguageProvider languageProvider) {
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

  Widget _buildScreenOption(BuildContext context, String screen, String screenName) {
    return RadioListTile<String>(
      title: Text(screenName),
      value: screen,
      groupValue: _selectedScreen,
      onChanged: (String? value) {
        if (value != null) {
          _saveSelectedScreen(value);
          Navigator.of(context).pop();
        }
      },
    );
  }
}