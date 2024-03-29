import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:srbguide/localization/app_localizations.dart';
import 'package:srbguide/provider/language_provider.dart';

import 'service/parser/promonet_parser.dart';
import 'widget/screen_mapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru', null);

  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isDarkMode = prefs.getBool('isDarkMode') ?? false;
  ThemeMode initialThemeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
  String initialSelectedScreen = prefs.getString('selectedScreen') ?? 'ServiceScreen';

  LanguageProvider languageProvider = LanguageProvider();
  await languageProvider.init();

  runApp(
    ChangeNotifierProvider<LanguageProvider>(
      create: (_) => languageProvider,
      child: MainScreen(
        initialThemeMode: initialThemeMode,
        initialSelectedScreen: initialSelectedScreen,
      ),
    ),
  );
}

class MainScreen extends StatefulWidget {
  final ThemeMode initialThemeMode;
  final String initialSelectedScreen;

  const MainScreen({
    Key? key,
    required this.initialThemeMode,
    required this.initialSelectedScreen
  }) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();

  static _MainScreenState? of(BuildContext context) =>
      context.findAncestorStateOfType<_MainScreenState>();
}

class _MainScreenState extends State<MainScreen> {
  late ThemeMode _themeMode;
  late String _selectedScreen;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.initialThemeMode;
    _selectedScreen = widget.initialSelectedScreen;
    ProMonetParser().getExchangeRateInHeader();
  }

  void setThemeMode(ThemeMode themeMode) async {
    setState(() {
      _themeMode = themeMode;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', themeMode == ThemeMode.dark);
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    return MaterialApp(
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        ...GlobalCupertinoLocalizations.delegates,
      ],
      supportedLocales: [
        Locale('en', ''),
        Locale('ru', ''),
      ],
      darkTheme: ThemeData.dark(),
      themeMode: _themeMode,
      locale: languageProvider.selectedLocale,
      home: Scaffold(
        body: ScreenMapper.getScreen(_selectedScreen),
      ),
    );
  }
}
