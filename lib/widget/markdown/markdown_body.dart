import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:photo_view/photo_view.dart';
import 'package:srbguide/utils/contents_util.dart';
import 'package:srbguide/widget/dialogs/error.dart';
import 'package:srbguide/widget/markdown/card.dart';

class MarkdownHelper {
  Widget buildMarkdownBody(
      BuildContext context,
      bool isLoading,
      String? markdownContent,
      double textSize,
      Function(String, String?, String) onTapLink,
      Function(String) scrollToAnchor,
      ) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    } else if (markdownContent == null) {
      CustomErrorDialog.show(
        context: context,
        title: 'Упс...',
        text: 'Данные не были загружены',
      );
      return Center(child: Text('No data'));
    } else {
      ContentUtil util = ContentUtil();

      final contentWithoutATags = util.removeATags(markdownContent);
      List<String> lines = contentWithoutATags.split('\n');
      final widgets = <Widget>[];
      CardHelper cardHelper = CardHelper();

      bool isInCard = false;
      List<String> cardContent = [];

      for (String line in lines) {
        if (line.trim() == "<card>") {
          isInCard = true;
          continue;
        } else if (line.trim() == "</card>") {
          isInCard = false;
          if (cardContent.isNotEmpty) {
            widgets.add(
              cardHelper.buildCard(
                context,
                cardContent.join('\n'),
                textSize,
                onTapLink,
                scrollToAnchor
            ));
            cardContent.clear();
          }
          continue;
        }

        if (isInCard) {
          cardContent.add(line);
        } else {
          widgets.add(
              buildMarkdown(
                  context,
                  line,
                  textSize,
                  onTapLink,
                  scrollToAnchor
              ));
        }
      }

      if (cardContent.isNotEmpty && isInCard) {
        widgets.add(
            cardHelper.buildCard(
                context,
                cardContent.join('\n'),
                textSize,
                onTapLink,
                scrollToAnchor
            ));
      }

      return SingleChildScrollView(
        child: Column(
          children: widgets,
        ),
      );
    }
  }

  Widget buildMarkdown(
      BuildContext context,
      String content,
      double textSize,
      Function(String, String?, String) onTapLink,
      Function(String) scrollToAnchor,
      ) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    Color textColor = isDarkMode ? Colors.white : Colors.black;

    return MarkdownBody(
      selectable: true,
      key: GlobalKey(),
      data: content,
      styleSheetTheme: MarkdownStyleSheetBaseTheme.material,
      styleSheet: MarkdownStyleSheet.fromTheme(
          ThemeData(
        textTheme: TextTheme(
          headlineLarge: TextStyle(fontSize: textSize + 4, color: textColor, fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(fontSize: textSize + 2, color: textColor),
          headlineSmall: TextStyle(fontSize: textSize, color: textColor),

          titleLarge: TextStyle(fontSize: textSize + 4, color: textColor, fontWeight: FontWeight.bold),
          titleMedium: TextStyle(fontSize: textSize + 2, color: textColor),
          titleSmall: TextStyle(fontSize: textSize, color: textColor),

          bodyLarge: TextStyle(fontSize: textSize + 4, color: textColor, fontWeight: FontWeight.bold),
          bodyMedium: TextStyle(fontSize: textSize + 2, color: textColor),
          bodySmall: TextStyle(fontSize: textSize, color: textColor),

          displayLarge: TextStyle(fontSize: textSize + 4, color: textColor, fontWeight: FontWeight.bold),
          displayMedium: TextStyle(fontSize: textSize + 2, color: textColor),
          displaySmall: TextStyle(fontSize: textSize, color: textColor),
        ),
      )),
      imageBuilder: (uri, title, alt) {
        if (uri.toString().startsWith('https://github.com/')) {
          return GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (BuildContext context) {
                    return Scaffold(
                      appBar: AppBar(),
                      body: Center(
                        child: PhotoView(
                          imageProvider: NetworkImage(uri.toString()),
                          minScale: PhotoViewComputedScale.contained,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
            child: Image.network(uri.toString()),
          );
        }
        return const SizedBox();
      },
      onTapLink: (text, href, title) {
        if (href != null && href.startsWith('#')) {
          final anchor = Uri.decodeComponent(href.substring(1));
          scrollToAnchor(anchor);
        } else {
          onTapLink(text, href, title);
        }
      },
    );
  }

}
