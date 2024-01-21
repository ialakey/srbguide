import 'package:flutter/material.dart';
import 'package:srbguide/localization/app_localizations.dart';
import 'package:srbguide/screens/guide.dart';
import 'package:srbguide/screens/guide_favourite.dart';
import 'package:srbguide/widget/themed/themed_icon.dart';

class GuideNavigationScreen extends StatefulWidget {
  @override
  _GuideNavigationScreenState createState() => _GuideNavigationScreenState();
}

class _GuideNavigationScreenState extends State<GuideNavigationScreen> {
  int _selectedIndex = 0;

  static List<Widget> _widgetOptions = <Widget>[
    GuideScreen(),
    GuideFavoritesScreen(),
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
              iconPath: 'assets/icons_24x24/search-alt.png',
              size: 24.0,
            ),
            label: AppLocalizations.of(context)!.translate('guide'),
          ),
          BottomNavigationBarItem(
            icon: ThemedIcon(
              iconPath: 'assets/icons_24x24/bookmark.png',
              size: 24.0,
            ),
            label: AppLocalizations.of(context)!.translate('favourite'),
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: (index) {
          _onItemTapped(index);
        },
      ),
    );
  }
}