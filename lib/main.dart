import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/author.dart';
import 'screens/calculator.dart';
import 'screens/calculator_tax.dart';
import 'screens/exchange.dart';
import 'screens/russian_places.dart';
import 'screens/serbia_guide.dart';
import 'screens/settings.dart';
import 'screens/smokers_lounge.dart';
import 'screens/tg_chats.dart';
import 'screens/white_cardboard.dart';
import 'widget/drawer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  int _selectedNavItem = 0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: _themeMode,
      home: Scaffold(
        appBar: AppBar(
          title: Text("Serbia guide"),
        ),
        drawer: DrawerScreen(
          onNavItemTapped: (index) {
            setState(() {
              _selectedNavItem = index;
            });
          },
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedNavItem) {
      case 0:
        return VisaFreeCalculator();
      case 1:
        return InformationForm();
      case 2:
        return CalculatorTaxScreen();
      case 3:
        return SerbiaGuideScreen();
      case 4:
        return RussianPlacesScreen();
      case 5:
        return TgChatScreen();
      case 6:
        return AuthorScreen();
      case 7:
        return SmokersLoungeScreen();
      case 8:
        return ExchangePlacesScreen();
      case 9:
        return SettingsScreen();
      default:
        return InformationForm();
    }
  }
}


