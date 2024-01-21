import 'package:flutter/material.dart';
import 'package:srbguide/widget/markdown/markdown_body.dart';

class CardHelper {
  Widget buildCard(
      BuildContext context,
      String content,
      double textSize,
      Function(String, String?, String) onTapLink,
      Function(String) scrollToAnchor,
      ) {

    MarkdownHelper markdownHelper = MarkdownHelper();

    return Card(
      elevation: 4.0,
      margin: EdgeInsets.all(8.0),
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child: markdownHelper.buildMarkdown(
          context,
          content,
          textSize,
          onTapLink,
          scrollToAnchor,
        ),
      ),
    );
  }
}
