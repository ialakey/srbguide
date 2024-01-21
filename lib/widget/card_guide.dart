import 'package:flutter/material.dart';
import 'package:srbguide/screens/markdown_reader.dart';

class CardWidgets {
  static Widget cardWidgets({
    required String smile,
    required String title,
    required String content,
    required BuildContext context,
  }) {
    return Column(
      children: [
        Card(
          child: ListTile(
            title: Text('$smile $title'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MarkdownReaderScreen(title: '$smile $title', content: content),
                ),
              );
            },
          ),
        ),
        SizedBox(height: 7),
      ],
    );
  }
}