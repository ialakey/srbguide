import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:srbguide/data/guide_repository.dart';
import 'package:srbguide/localization/app_localizations.dart';
import 'package:srbguide/provider/language_provider.dart';
import 'package:srbguide/screens/app_shell.dart';
import 'package:srbguide/service/exchange_rate_service.dart';
import 'package:srbguide/service/notification_service.dart';
import 'package:srbguide/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru', null);

  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final bool isDarkMode = prefs.getBool('isDarkMode') ?? false;
  final int initialTab = prefs.getInt('mainTabIndex') ?? 0;

  final LanguageProvider languageProvider = LanguageProvider();
  await languageProvider.init();

  // Warm the guide cache while the first frame is being built; the bundle is a
  // couple of megabytes and this keeps the guide tab instant.
  unawaited(GuideRepository.instance.load());
  unawaited(ExchangeRateService.refreshSummary());
  unawaited(NotificationService.instance.init());

  runApp(
    ChangeNotifierProvider<LanguageProvider>.value(
      value: languageProvider,
      child: MainScreen(
        initialThemeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
        initialTab: initialTab,
      ),
    ),
  );
}

class MainScreen extends StatefulWidget {
  final ThemeMode initialThemeMode;
  final int initialTab;

  const MainScreen({
    super.key,
    required this.initialThemeMode,
    this.initialTab = 0,
  });

  @override
  State<MainScreen> createState() => MainScreenState();

  static MainScreenState? of(BuildContext context) =>
      context.findAncestorStateOfType<MainScreenState>();
}

class MainScreenState extends State<MainScreen> {
  late ThemeMode _themeMode = widget.initialThemeMode;

  ThemeMode get themeMode => _themeMode;

  Future<void> setThemeMode(ThemeMode themeMode) async {
    setState(() => _themeMode = themeMode);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', themeMode == ThemeMode.dark);
  }

  @override
  Widget build(BuildContext context) {
    final LanguageProvider languageProvider =
        Provider.of<LanguageProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const <Locale>[
        Locale('en', ''),
        Locale('ru', ''),
      ],
      locale: languageProvider.selectedLocale,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: _themeMode,
      home: AppShell(initialIndex: widget.initialTab),
    );
  }
}
