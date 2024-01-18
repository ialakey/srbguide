import 'package:flutter/material.dart';
import 'package:srbguide/localization/app_localizations.dart';
import 'package:srbguide/screens/calculator.dart';
import 'package:srbguide/service/url_launcher_helper.dart';
import 'package:srbguide/widget/themed/themed_icon.dart';

import 'white_cardboard.dart';

class ServiceScreen extends StatefulWidget {
  @override
  _ServiceScreenState createState() => _ServiceScreenState();
}

class _ServiceScreenState extends State<ServiceScreen> {
  int _selectedIndex = 0;

  static List<Widget> _widgetOptions = <Widget>[
    VisaFreeCalculatorScreen(),
    CreateWhiteCardboardScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: ThemedIcon(
              iconPath: 'assets/icons_24x24/calendar-clock.png',
              size: 24.0,
            ),
            label: AppLocalizations.of(context)!.translate('calculator_visarun'),
          ),
          BottomNavigationBarItem(
            icon: ThemedIcon(
              iconPath: 'assets/icons_24x24/edit.png',
              size: 24.0,
            ),
            label: AppLocalizations.of(context)!.translate('create_whiteboard'),
          ),
          BottomNavigationBarItem(
            icon: ThemedIcon(
              iconPath: 'assets/icons_24x24/coins.png',
              size: 24.0,
            ),
            label: AppLocalizations.of(context)!.translate('flat_tax_calculator'),
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (index == 2) {
            UrlLauncherHelper.launchURL('https://eporezi.purs.gov.rs/kalkulator-pausalnog-poreza-i-doprinosa.html');
          }  else {
            _onItemTapped(index);
          }
        },
      ),
    );
  }
}