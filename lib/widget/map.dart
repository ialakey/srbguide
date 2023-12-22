import 'package:flutter/material.dart';
import 'package:srbguide/screens/serbia_guide.dart';

class MapWidgets {
  static Widget googleMapsCard({
    required String url,
    required String title,
    required String content,
    required BuildContext context,
  }) {
    return Column(
      children: [
        Card(
          child: ListTile(
            title: Text(title),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SerbiaGuideScreen(content: content),
                ),
              );
            },
          ),
        ),
        SizedBox(height: 8),
      ],
    );
  }
}