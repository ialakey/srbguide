import 'package:flutter/material.dart';

import 'screens/calculator.dart';
import 'screens/calculator_tax.dart';
import 'screens/serbia_guide.dart';
import 'screens/white_cardboard.dart';
import 'widget/bottom_navigation.dart';
import 'widget/drawer.dart';

void main() {
  runApp(MainScreen());
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedNavItem = 0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text("Serbia guide"),
        ),
        drawer: DrawerScreen(
          onNavItemTapped: (index) {
            setState(() {
              _selectedNavItem = index;
            });
            Navigator.pop(context);
          },
          mainContext: context,
        ),
        body: _buildBody(),
        // bottomNavigationBar: CustomBottomNavigationBar(
        //   onItemTapped: (index) {
        //     setState(() {
        //       _selectedNavItem = index;
        //     });
        //   },
        // ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedNavItem) {
      case 0:
        return VisaFreeCalculator();
      case 1:
        return InformationForm();
      case 2:
        return CalculatorTaxScreen();
      case 3:
        return SerbiaGuideScreen();
      default:
        return InformationForm();
    }
  }
}


