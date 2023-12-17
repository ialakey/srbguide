import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'screens/calculator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru', null);

  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isDarkMode = prefs.getBool('isDarkMode') ?? false;
  ThemeMode initialThemeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;

  runApp(MainScreen(
    initialThemeMode: initialThemeMode,
  ));
}

class MainScreen extends StatefulWidget {
  final ThemeMode initialThemeMode;

  const MainScreen({Key? key, required this.initialThemeMode}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();

  static _MainScreenState? of(BuildContext context) =>
      context.findAncestorStateOfType<_MainScreenState>();
}

class _MainScreenState extends State<MainScreen> {
  late ThemeMode _themeMode;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.initialThemeMode;
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
    return MaterialApp(
      darkTheme: ThemeData.dark(),
      themeMode: _themeMode,
      home: Scaffold(
        body: VisaFreeCalculatorScreen(),
      ),
    );
  }
}
