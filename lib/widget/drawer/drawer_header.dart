import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:srbguide/main.dart';
import 'package:srbguide/screens/calculator.dart';
import 'dart:math';
import 'package:srbguide/service/url_launcher_helper.dart';

import 'package:srbguide/widget/themed/themed_icon2.dart';

class CustomDrawerHeader extends StatefulWidget {
  final String appName;
  final String imagePath;

  const CustomDrawerHeader({
    Key? key,
    required this.appName,
    required this.imagePath,
  }) : super(key: key);

  @override
  _CustomDrawerHeaderState createState() => _CustomDrawerHeaderState();
}

class _CustomDrawerHeaderState extends State<CustomDrawerHeader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late String exchangeRate = '';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400),
    );
    _getExchangeRate();
  }

  _getExchangeRate() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      exchangeRate = prefs.getString('exchangeRate') ?? '';
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DrawerHeader(
      decoration: BoxDecoration(),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            right: 0,
            left: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _controller.value * 2 * pi,
                      child: IconButton(
                        icon: ThemedIcon2(
                          lightIcon: 'assets/icons_24x24/moon-stars.png',
                          darkIcon: 'assets/icons_24x24/sun.png',
                          size: 24,
                        ),
                        onPressed: () {
                          _toggleTheme(context);
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => VisaFreeCalculatorScreen()),
                    );
                  },
                  child: ClipOval(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: CircleAvatar(
                        radius: 40.0,
                        backgroundColor: Colors.transparent,
                        child: Image.asset(
                          widget.imagePath,
                          fit: BoxFit.cover,
                          width: 80.0,
                          height: 80.0,
                        ),
                      ),
                    ),
                  ),
                ),
                Text(
                  widget.appName,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4.0),
                GestureDetector(
                  onTap: () {
                    UrlLauncherHelper.launchURL('https://www.promonet.rs');
                  },
                  child: Text(
                    exchangeRate,
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  _toggleTheme(BuildContext context) {
    SharedPreferences.getInstance().then((prefs) {
      bool isDarkMode = prefs.getBool('isDarkMode') ?? false;
      isDarkMode = !isDarkMode;
      prefs.setBool('isDarkMode', isDarkMode);

      ThemeMode newThemeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
      final mainScreen = MainScreen.of(context);
      mainScreen?.setThemeMode(newThemeMode);

      if (_controller.status != AnimationStatus.dismissed) {
        _controller.reverse();
      } else {
        _controller.forward();
      }
    });
  }
}