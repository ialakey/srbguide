import 'package:flutter/material.dart';
import 'package:srbguide/app_localizations.dart';
import 'package:srbguide/screens/author.dart';
import 'package:srbguide/screens/calculator.dart';
import 'package:srbguide/screens/guide.dart';
import 'package:srbguide/screens/map.dart';
import 'package:srbguide/screens/settings.dart';
import 'package:srbguide/screens/tg_chats.dart';
import 'package:srbguide/screens/white_cardboard.dart';
import 'package:srbguide/service/url_launcher_helper.dart';
import 'package:srbguide/widget/drawer/drawer_header.dart';

import '../themed/themed_icon.dart';

class AppDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          CustomDrawerHeader(
            appName: AppLocalizations.of(context)!.translate('app_name'),
            imagePath: 'assets/serbia.png',
          ),
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(width: 1.0, color: Colors.grey)
              ),
            ),
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              children: [
                ListTile(
                  leading: ThemedIcon(
                    iconPath: 'assets/icons_24x24/time-check.png',
                    size: 24.0,
                  ),
                  title: Text(AppLocalizations.of(context)!.translate('calculator_visarun')),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => VisaFreeCalculatorScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: ThemedIcon(
                    iconPath: 'assets/icons_24x24/edit.png',
                    size: 24.0,
                  ),
                  title: Text(AppLocalizations.of(context)!.translate('create_whiteboard')),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CreateWhiteCardboardScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: ThemedIcon(
                    iconPath: 'assets/icons_24x24/coins.png',
                    size: 24.0,
                  ),
                  title: Text(AppLocalizations.of(context)!.translate('flat_tax_calculator')),
                  onTap: () {
                    UrlLauncherHelper.launchURL('https://eporezi.purs.gov.rs/kalkulator-pausalnog-poreza-i-doprinosa.html');
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border(
                  bottom: BorderSide(width: 1.0, color: Colors.grey)
              ),
            ),
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              children: [
                ListTile(
                  leading:
                  ThemedIcon(
                    iconPath: 'assets/icons_24x24/map-marker.png',
                    size: 24.0,
                  ),
                  title: Text(AppLocalizations.of(context)!.translate('maps')),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => MapScreen()),
                    );
                  },
                ),
                ListTile(
                  leading:
                  ThemedIcon(
                    iconPath: 'assets/icons_24x24/search-alt.png',
                    size: 24.0,
                  ),
                  title: Text(AppLocalizations.of(context)!.translate('guide')),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => GuideScreen()),
                    );
                  },
                ),
                ListTile(
                  leading:
                  ThemedIcon(
                    iconPath: 'assets/icons_24x24/users.png',
                    size: 24.0,
                  ),
                  title: Text(AppLocalizations.of(context)!.translate('tg_chats')),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => TgChatScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
          ListTile(
            leading:
            ThemedIcon(
              iconPath: 'assets/icons_24x24/settings.png',
              size: 24.0,
            ),
            title: Text(AppLocalizations.of(context)!.translate('settings')),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsScreen()),
              );
            },
          ),
          ListTile(
            leading:
            ThemedIcon(
              iconPath: 'assets/icons_24x24/diamond.png',
              size: 24.0,
            ),
            title: Text(AppLocalizations.of(context)!.translate('author')),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AuthorScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}