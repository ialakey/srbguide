import 'package:flutter/material.dart';

class DrawerScreen extends StatelessWidget {

  final Function(int, String) onNavItemTapped;

  DrawerScreen({required this.onNavItemTapped});

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
            title: Text('Калькулятор визарана'),
            onTap: () {
              Navigator.pop(context);
              //onTap('VisaFreeCalculator');
            },
          ),
          ListTile(
            title: Text('Создание белого картона'),
            onTap: () {
              Navigator.pop(context);
              //onTap('InformationForm');
            },
          ),
        ],
      ),
    );
  }
}