import 'package:flutter/material.dart';
import 'package:srbguide/widget/card_guide.dart';

import 'themed/themed_icon.dart';

Widget buildSection(BuildContext context, String sectionTitle, String icon, List<Map<String, String>> sectionItems) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Row(
          children: [
            Text(
              sectionTitle,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(
              width: 7,
            ),
            ThemedIcon(
              iconPath: 'assets/icons_24x24/$icon',
              size: 24.0,
            ),
          ],
        ),
      ),
      SizedBox(height: 8),
      Column(
        children: sectionItems.map((location) {
          return CardWidgets.cardWidgets(
            smile: location['smile'] ?? '',
            title: location['title'] ?? '',
            content: location['description'] ?? '',
            context: context,
          );
        }).toList(),
      ),
    ],
  );
}