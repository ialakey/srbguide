import 'package:flutter/material.dart';

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
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                  child: CircleAvatar(
                  radius: 40.0,
                    backgroundImage: AssetImage('assets/serbia.png'),
                  ),
                ),
                  SizedBox(height: 10.0),
                  Text("Serbia guide")
                ],
              ),
            ),
          ),
          ExpansionTile(
            title: Text("Сервисы"),
            leading: Icon(Icons.android),
            children: [
              ListTile(
                leading: Icon(Icons.access_alarm),
                title: Text('Калькулятор визарана'),
                onTap: () {
                  onNavItemTapped(0);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.create),
                title: Text('Создание белого картона'),
                onTap: () {
                  onNavItemTapped(1);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.calculate),
                title: Text('Калькулятор паушального налога'),
                onTap: () {
                  onNavItemTapped(2);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          ExpansionTile(
            leading: Icon(Icons.map),
            title: Text('Карты'),
            children: [
              ListTile(
                leading: Icon(Icons.account_balance),
                title: Text('Обменники'),
                onTap: () {
                  onNavItemTapped(4);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.smoke_free),
                title: Text('Не курящие/Курящие'),
                onTap: () {
                  onNavItemTapped(4);
                  Navigator.pop(context);
                    },
                  ),
              ListTile(
                leading: Icon(Icons.local_cafe),
                title: Text('Русские заведения'),
                onTap: () {
                  onNavItemTapped(4);
                  Navigator.pop(context);
                },
              ),
                ],
              ),
          ExpansionTile(
            title: Text("База знаний"),
            leading: Icon(Icons.library_books),
            children: [
              ListTile(
                leading: Icon(Icons.note),
                title: Text('SRB.GUIDE'),
                onTap: () {
                  onNavItemTapped(3);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.telegram_outlined),
                title: Text('Телеграм чаты'),
                onTap: () {
                  onNavItemTapped(5);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('Настройки'),
            onTap: () {
              onNavItemTapped(2);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.account_circle),
            title: Text('Автор'),
            onTap: () {
              onNavItemTapped(2);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}