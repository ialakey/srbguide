import 'package:flutter/material.dart';

import 'themed_icon.dart';

class DrawerScreen extends StatelessWidget {
  final Function(int) onNavItemTapped;

  DrawerScreen({required this.onNavItemTapped});

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
              onNavItemTapped(0);
              Navigator.pop(context);
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
              onNavItemTapped(1);
              Navigator.pop(context);
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
              onNavItemTapped(2);
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
              onNavItemTapped(8);
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
            title: Text('Гайд'),
            onTap: () {
              onNavItemTapped(9);
              Navigator.pop(context);
            },
          ),
          ExpansionTile(
            title: Text("База знаний"),
            leading:
            ThemedIcon(
              lightIcon: 'assets/icons_24x24/graduation-cap.png',
              darkIcon: 'assets/icons_24x24/graduation-cap.png',
              size: 24.0,
            ),
            children: [
              ListTile(
                leading:
                ThemedIcon(
                  lightIcon: 'assets/icons_24x24/spreadsheet.png',
                  darkIcon: 'assets/icons_24x24/spreadsheet.png',
                  size: 24.0,
                ),
                title: Text('SRB.GUIDE'),
                onTap: () {
                  onNavItemTapped(3);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading:
                ThemedIcon(
                  lightIcon: 'assets/icons_24x24/physics.png',
                  darkIcon: 'assets/icons_24x24/physics.png',
                  size: 24.0,
                ),
                title: Text('Полезности'),
                onTap: () {
                  onNavItemTapped(7);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading:
                ThemedIcon(
                  lightIcon: 'assets/icons_24x24/users.png',
                  darkIcon: 'assets/icons_24x24/users.png',
                  size: 24.0,
                ),
                title: Text('Телеграм чаты'),
                onTap: () {
                  onNavItemTapped(4);
                  Navigator.pop(context);
                },
              ),
            ],
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
              onNavItemTapped(5);
              Navigator.pop(context);
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
              onNavItemTapped(6);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}