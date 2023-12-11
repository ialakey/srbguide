import 'package:flutter/material.dart';

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

void main() {
  runApp(MainScreen(setThemeMode: (ThemeMode ) {  },));
}

class MainScreen extends StatefulWidget {
  final Function(ThemeMode) setThemeMode;

  const MainScreen({Key? key, required this.setThemeMode}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();

  static _MainScreenState? of(BuildContext context) =>
      context.findAncestorStateOfType<_MainScreenState>();
}

class _MainScreenState extends State<MainScreen> {

  ThemeMode _themeMode = ThemeMode.system;

  void setThemeMode(ThemeMode themeMode) {
    setState(() {
      _themeMode = themeMode;
    });
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


