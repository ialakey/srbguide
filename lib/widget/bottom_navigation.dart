import 'package:flutter/material.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.favorite),
          label: 'Избранное',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Дом',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: 'Настройки',
        ),
      ],
    );
  }
}