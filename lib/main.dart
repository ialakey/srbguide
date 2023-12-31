import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'screens/author.dart';
import 'screens/calculator.dart';
import 'screens/calculator_tax.dart';
import 'screens/serbia_guide.dart';
import 'screens/settings.dart';
import 'screens/tg_chats.dart';
import 'screens/useful_links.dart';
import 'screens/white_cardboard.dart';
import 'widget/drawer.dart';
import 'widget/themed_icon.dart';

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

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late ThemeMode _themeMode;
  int _selectedNavItem = 0;

  final List<String> _appBarTitles = [
    'Калькулятор визарана',
    'Создание белого картона',
    'Калькулятор паушального налога',
    'SRB.GUIDE',
    'Телеграм чаты',
    'Настройки',
    'Автор',
    'Полезности',
  ];

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
      theme: ThemeData(
        primaryColor: Colors.lightBlue,
      ),
      darkTheme: ThemeData.dark(),
      themeMode: _themeMode,
      home: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text(_appBarTitles[_selectedNavItem]),
          leading: IconButton(
            icon:
            ThemedIcon(
              lightIcon: 'assets/icons_24x24/burger-menu.png',
              darkIcon: 'assets/icons_24x24/burger-menu.png',
              size: 24.0,
            ),
            onPressed: () =>  _scaffoldKey.currentState?.openDrawer(),
          ),
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
        return TgChatScreen();
      case 5:
        return SettingsScreen();
      case 6:
        return AuthorScreen();
      case 7:
        return UsefulLinksScreen();
      default:
        return VisaFreeCalculator();
    }
  }
}


