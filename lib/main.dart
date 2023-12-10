import 'package:flutter/material.dart';

import 'screens/white_cardboard.dart';
import 'widget/bottom_navigation.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Information Form',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
        home: Scaffold(
        body: InformationForm(),
        bottomNavigationBar: CustomBottomNavigationBar(),
      )
    );
  }
}


