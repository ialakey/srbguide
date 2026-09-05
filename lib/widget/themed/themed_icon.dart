import 'package:flutter/material.dart';

class ThemedIcon extends StatelessWidget {
  final String iconPath;
  final double size;

  const ThemedIcon({
    super.key,
    required this.iconPath,
    this.size = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Image.asset(
      iconPath,
      width: size,
      height: size,
      color: isDarkMode ? Colors.white : Colors.black,
    );
  }
}
