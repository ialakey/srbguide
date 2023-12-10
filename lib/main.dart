import 'package:flutter/material.dart';

import 'screens/white_cardboard.dart';
import 'widget/bottom_navigation.dart';
import 'widget/drawer.dart';

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
        appBar: AppBar(
          title: Text("Serbia guide"),
        ),
        endDrawer: DrawerScreen(onNavItemTapped: (int , String ) {  },),
        body: InformationForm(),
        bottomNavigationBar: CustomBottomNavigationBar(),
    )
    );
  }
}


