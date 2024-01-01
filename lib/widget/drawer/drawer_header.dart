import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:srbguide/main.dart';
import 'package:srbguide/widget/themed_icon.dart';

class CustomDrawerHeader extends StatelessWidget {
  final String appName;
  final String imagePath;

  const CustomDrawerHeader({
    Key? key,
    required this.appName,
    required this.imagePath,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DrawerHeader(
      decoration: BoxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 40.0,
                    backgroundColor: Colors.transparent,
                    child: ClipOval(
                      child: Image.asset(
                        imagePath,
                        fit: BoxFit.cover,
                        width: 80.0,
                        height: 80.0,
                      ),
                    ),
                  ),
                  SizedBox(height: 10.0),
                  Text(
                    appName,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              IconButton(
                icon: ThemedIcon(
                  lightIcon: 'assets/icons_24x24/moon-stars.png',
                  darkIcon: 'assets/icons_24x24/sun.png',
                  size: 30,
                ),
                onPressed: () {
                  _toggleTheme(context);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _toggleTheme(BuildContext context) {
    SharedPreferences.getInstance().then((prefs) {
      bool isDarkMode = prefs.getBool('isDarkMode') ?? false;
      isDarkMode = !isDarkMode;
      prefs.setBool('isDarkMode', isDarkMode);

      ThemeMode newThemeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
      final mainScreen = MainScreen.of(context);
      mainScreen?.setThemeMode(newThemeMode);
    });
  }
}
