import 'package:flutter/material.dart';
import 'package:srbguide/service/url_launcher_helper.dart';

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
            leading: Image.asset('assets/icons_24x24/time-check.png'),
            title: Text('Калькулятор визарана'),
            onTap: () {
              onNavItemTapped(0);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Image.asset('assets/icons_24x24/edit.png'),
            title: Text('Создание белого картона'),
            onTap: () {
              onNavItemTapped(1);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Image.asset('assets/icons_24x24/coins.png'),
            title: Text('Калькулятор паушального налога'),
            onTap: () {
              onNavItemTapped(2);
              Navigator.pop(context);
            },
          ),
          ExpansionTile(
            leading: Image.asset('assets/icons_24x24/map-marker.png'),
            title: Text('Карты'),
            children: [
              ListTile(
                leading: Image.asset('assets/icons_24x24/usd.png'),
                title: Text('Обменники'),
                onTap: () {
                  UrlLauncherHelper.launchURL('https://www.google.com/maps/search/exchange');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Image.asset('assets/icons_24x24/do-not-enter.png'),
                title: Text('Не курящие/Курящие'),
                onTap: () {
                  UrlLauncherHelper.launchURL('https://lokalibezdima.rs');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Image.asset('assets/icons_24x24/tea.png'),
                title: Text('Русские заведения'),
                onTap: () {
                  UrlLauncherHelper.launchURL('https://www.google.com/maps/d/u/0/viewer?mid=12l4BVYg_FV0d9CMeEWEtnJDQioL9804&ll=45.23992208501285%2C19.854860046985962&z=13');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          ExpansionTile(
            title: Text("База знаний"),
            leading: Image.asset('assets/icons_24x24/graduation-cap.png'),
            children: [
              ListTile(
                leading: Image.asset('assets/icons_24x24/spreadsheet.png'),
                title: Text('SRB.GUIDE'),
                onTap: () {
                  onNavItemTapped(3);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Image.asset('assets/icons_24x24/users.png'),
                title: Text('Телеграм чаты'),
                onTap: () {
                  onNavItemTapped(4);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          ListTile(
            leading: Image.asset('assets/icons_24x24/settings.png'),
            title: Text('Настройки'),
            onTap: () {
              onNavItemTapped(5);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Image.asset('assets/icons_24x24/diamond.png'),
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