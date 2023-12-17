import 'package:flutter/material.dart';
import 'package:srbguide/screens/author.dart';
import 'package:srbguide/screens/calculator.dart';
import 'package:srbguide/screens/map.dart';
import 'package:srbguide/screens/serbia_guide.dart';
import 'package:srbguide/screens/settings.dart';
import 'package:srbguide/screens/tg_chats.dart';
import 'package:srbguide/screens/white_cardboard.dart';
import 'package:srbguide/service/url_launcher_helper.dart';

import 'themed_icon.dart';

class AppDrawer extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 40.0,
                  backgroundColor: Colors.transparent,
                  child: ClipOval(
                    child: Image.asset(
                      'assets/serbia.png',
                      fit: BoxFit.cover,
                      width: 80.0,
                      height: 80.0,
                    ),
                  ),
                ),
                SizedBox(height: 10.0),
                Text("Serbia Guide", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          ListTile(
            leading:
            ThemedIcon(
              lightIcon: 'assets/icons_24x24/time-check.png',
              darkIcon: 'assets/icons_24x24/time-check.png',
              size: 24.0,
            ),
            title: Text('Калькулятор визарана'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => VisaFreeCalculatorScreen()),
              );
            },
          ),
          ListTile(
            leading:
            ThemedIcon(
              lightIcon: 'assets/icons_24x24/edit.png',
              darkIcon: 'assets/icons_24x24/edit.png',
              size: 24.0,
            ),
            title: Text('Создание белого картона'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CreateWhiteCardboardScreen()),
              );
            },
          ),
          ListTile(
            leading:
            ThemedIcon(
              lightIcon: 'assets/icons_24x24/coins.png',
              darkIcon: 'assets/icons_24x24/coins.png',
              size: 24.0,
            ),
            title: Text('Калькулятор паушального налога'),
            onTap: () {
              UrlLauncherHelper.launchURL('https://eporezi.purs.gov.rs/kalkulator-pausalnog-poreza-i-doprinosa.html');
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading:
            ThemedIcon(
              lightIcon: 'assets/icons_24x24/map-marker.png',
              darkIcon: 'assets/icons_24x24/map-marker.png',
              size: 24.0,
            ),
            title: Text('Карты'),
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
              lightIcon: 'assets/icons_24x24/search-alt.png',
              darkIcon: 'assets/icons_24x24/search-alt.png',
              size: 24.0,
            ),
            title: Text('Гайд'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SerbiaGuideScreen()),
              );
            },
          ),
          // ListTile(
          //   leading:
          //   ThemedIcon(
          //     lightIcon: 'assets/icons_24x24/physics.png',
          //     darkIcon: 'assets/icons_24x24/physics.png',
          //     size: 24.0,
          //   ),
          //   title: Text('Полезности'),
          //   onTap: () {
          //     onNavItemTapped(4);
          //     Navigator.pop(context);
          //   },
          // ),
          ListTile(
            leading:
            ThemedIcon(
              lightIcon: 'assets/icons_24x24/users.png',
              darkIcon: 'assets/icons_24x24/users.png',
              size: 24.0,
            ),
            title: Text('Телеграм чаты'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TgChatScreen()),
              );
            },
          ),
          ListTile(
            leading:
            ThemedIcon(
              lightIcon: 'assets/icons_24x24/settings.png',
              darkIcon: 'assets/icons_24x24/settings.png',
              size: 24.0,
            ),
            title: Text('Настройки'),
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
              lightIcon: 'assets/icons_24x24/diamond.png',
              darkIcon: 'assets/icons_24x24/diamond.png',
              size: 24.0,
            ),
            title: Text('Автор'),
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