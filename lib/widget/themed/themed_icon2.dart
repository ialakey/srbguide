import 'package:flutter/material.dart';

class ThemedIcon2 extends StatelessWidget {
  final String lightIcon;
  final String darkIcon;
  final double size;

  const ThemedIcon2({
    Key? key,
    required this.lightIcon,
    required this.darkIcon,
    this.size = 24.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    String iconPath = isDarkMode ? darkIcon : lightIcon;

    return Image.asset(
      iconPath,
      width: size,
      height: size,
      color: isDarkMode ? Colors.white : Colors.black,
    );
  }
}