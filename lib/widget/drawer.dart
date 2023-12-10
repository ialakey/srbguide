import 'package:flutter/material.dart';

class DrawerScreen extends StatelessWidget {
  final Function(int) onNavItemTapped;
  final BuildContext mainContext;

  DrawerScreen({required this.onNavItemTapped, required this.mainContext});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            child: Text('Serbia guide'),
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
          ),
          ListTile(
            leading: Icon(Icons.access_alarm),
            title: Text('Калькулятор визарана'),
            onTap: () {
              onNavItemTapped(0);
              Navigator.pop(mainContext);
            },
          ),
          ListTile(
            leading: Icon(Icons.create),
            title: Text('Создание белого картона'),
            onTap: () {
              onNavItemTapped(1);
              Navigator.pop(mainContext);
            },
          ),
          ListTile(
            leading: Icon(Icons.calculate),
            title: Text('Калькулятор паушального налога'),
            onTap: () {
              onNavItemTapped(2);
              Navigator.pop(mainContext);
            },
          ),
          ListTile(
            leading: Icon(Icons.note),
            title: Text('SRB.GUIDE'),
            onTap: () {
              onNavItemTapped(3);
              Navigator.pop(mainContext);
            },
          ),
          ListTile(
            leading: Icon(Icons.account_circle),
            title: Text('Автор'),
            onTap: () {
              onNavItemTapped(2);
              Navigator.pop(mainContext);
            },
          ),
        ],
      ),
    );
  }
}