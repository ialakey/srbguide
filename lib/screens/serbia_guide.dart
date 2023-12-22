import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:photo_view/photo_view.dart';
import 'package:quickalert/quickalert.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:srbguide/app_localizations.dart';
import 'package:srbguide/widget/custom_search.dart';
import 'package:srbguide/widget/drawer.dart';
import 'package:srbguide/widget/themed_icon.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_xlider/flutter_xlider.dart';
typedef ScrollToTextFunction = void Function(String text);

class SerbiaGuideScreen extends StatefulWidget {
  @override
  _SerbiaGuideScreenState createState() => _SerbiaGuideScreenState();
}

class _SerbiaGuideScreenState extends State<SerbiaGuideScreen> {
  late String _markdownContent;
  late ScrollController _scrollController;
  late TextEditingController _searchController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMarkdownFile();
    _loadSavedTextSize();
    _scrollController = ScrollController();
    _searchController = TextEditingController();
  }

  Future<void> _loadMarkdownFile() async {
    String data = await rootBundle.loadString('assets/serbia-guide-ru.md');
    setState(() {
      _markdownContent = data;
      _isLoading = false;
    });
  }

  _scrollToText(String anchor) {
    final anchorPattern = anchor;
    final anchorIndex = _markdownContent.indexOf(anchorPattern);
    if (anchorIndex != -1) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent *
            (anchorIndex / _markdownContent.length),
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _onTapLink(String text, String? href, String title) async {
    if (href == null) return;
    final Uri url = Uri.parse(href);
    if (!await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Wrong address: $href'),
        ),
      );
    }
  }

  _scrollToAnchor(String anchor) {
    final anchorPattern = '<a name="$anchor"></a>';
    final anchorIndex = _markdownContent.indexOf(anchorPattern);
    if (anchorIndex != -1) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent *
            (anchorIndex / _markdownContent.length),
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  String _removeATags(String htmlString) {
    String contentWithoutATags;
    final patternTagA = RegExp(r'<a\b[^>]*>(.*?)<\/a>');
    final patternTagCard = RegExp(r'<card>|<\/card>');
    contentWithoutATags = htmlString.replaceAll(patternTagA, '');
    contentWithoutATags.replaceAll(patternTagCard, '');
    return contentWithoutATags;
  }

  double _currentTextSize = 18.0;

  Future<void> _saveTextSize(double textSize) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('textSize', textSize);
  }

  Future<double> _loadTextSize() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('textSize') ?? 18.0;
  }

  Future<void> _loadSavedTextSize() async {
    double savedTextSize = await _loadTextSize();
    setState(() {
      _currentTextSize = savedTextSize;
    });
  }

  void _showTextSizeDialog() {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.custom,
      confirmBtnText: AppLocalizations.of(context)!.translate('save'),
      widget: StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FlutterSlider(
                values: [_currentTextSize],
                min: 12,
                max: 30,
                step: FlutterSliderStep(step: 1),
                axis: Axis.horizontal,
                handler: FlutterSliderHandler(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
                trackBar: FlutterSliderTrackBar(
                  activeTrackBar: BoxDecoration(
                    color: Colors.blue.withOpacity(0.5),
                  ),
                  inactiveTrackBar: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                  ),
                ),
                tooltip: FlutterSliderTooltip(
                  textStyle: TextStyle(fontSize: 16),
                  boxStyle: FlutterSliderTooltipBox(
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                onDragging: (handlerIndex, lowerValue, upperValue) {
                  setState(() {
                    _currentTextSize = lowerValue;
                  });
                },
              ),
              Text('${AppLocalizations.of(context)!.translate('current_size')}: ${_currentTextSize.toStringAsFixed(0)}'),
            ],
          );
        },
      ),
      onConfirmBtnTap: () {
        _setTextSize(_currentTextSize);
        Navigator.of(context).pop();
      },
      title: AppLocalizations.of(context)!.translate('text_size'),
    );
  }

  void _setTextSize(double value) {
    setState(() {
      _currentTextSize = value;
    });
    _saveTextSize(value);
  }

  @override
  Widget build(BuildContext context) {
    final double textSize = _currentTextSize;
    return Scaffold(
      appBar: AppBar(
        title: Text('🚜 Гайд по Сербии'),
        actions: [
          IconButton(
            onPressed: () {
              _showTextSizeDialog();
            },
            icon:
            ThemedIcon(
              lightIcon: 'assets/icons_24x24/letter-case.png',
              darkIcon: 'assets/icons_24x24/letter-case.png',
              size: 24.0,
            ),
          ),
          IconButton(
            icon:
            ThemedIcon(
              lightIcon: 'assets/icons_24x24/search.png',
              darkIcon: 'assets/icons_24x24/search.png',
              size: 24.0,
            ),
            onPressed: () async {
              String? searchValue = await showSearch<String>(
                context: context,
                delegate: CustomSearchDelegate(
                  _removeATags(_markdownContent),
                  _scrollToText,
                ),
              );
              if (searchValue != null && searchValue.isNotEmpty) {
                _searchController.text = searchValue;
                _scrollToText(searchValue);
              }
            },
          ),
        ],
      ),
      drawer: AppDrawer(),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: _buildMarkdownBody(textSize),
        ),
      ),
    );
  }

  Widget _buildMarkdownBody(double textSize) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    } else if (_markdownContent == null) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        title: 'Упс...',
        text: 'Данные не были загружены',
      );
      return Center(child: Text('No data'));
    } else {
      final contentWithoutATags = _removeATags(_markdownContent);
      List<String> lines = contentWithoutATags.split('\n');
      final widgets = <Widget>[];

      bool isInCard = false;
      bool isInFavouriteCard = false;
      List<String> cardContent = [];

      for (String line in lines) {
        if (line.trim() == "<card>") {
          isInCard = true;
          continue;
        } else if (line.trim() == "</card>") {
          isInCard = false;
          if (cardContent.isNotEmpty) {
            widgets.add(_buildCard(cardContent.join('\n'), textSize));
            cardContent.clear();
          }
          continue;
        } else if (line.trim() == "<card-favourite>") {
          isInFavouriteCard = true;
          continue;
        } else if (line.trim() == "</card-favourite>") {
          isInFavouriteCard = false;
          if (cardContent.isNotEmpty) {
            widgets.add(_buildFavouriteCard(cardContent.join('\n'), textSize));
            cardContent.clear();
          }
          continue;
        }

        if (isInCard || isInFavouriteCard) {
          cardContent.add(line);
        } else {
          widgets.add(_buildMarkdown(line, textSize));
        }
      }

      if (cardContent.isNotEmpty) {
        if (isInCard) {
          widgets.add(_buildCard(cardContent.join('\n'), textSize));
        } else if (isInFavouriteCard) {
          widgets.add(_buildFavouriteCard(cardContent.join('\n'), textSize));
        }
      }

      return SingleChildScrollView(
        child: Column(
          children: widgets,
        ),
      );
    }
  }

  Widget _buildMarkdown(String content, double textSize) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    Color textColor = isDarkMode ? Colors.white : Colors.black;

    return MarkdownBody(
      selectable: true,
      key: GlobalKey(),
      data: content,
      styleSheetTheme: MarkdownStyleSheetBaseTheme.material,
      styleSheet: MarkdownStyleSheet.fromTheme(ThemeData(
        textTheme: TextTheme(
          headlineLarge: TextStyle(fontSize: textSize + 4, color: textColor),
          headlineMedium: TextStyle(fontSize: textSize + 2, color: textColor),
          headlineSmall: TextStyle(fontSize: textSize, color: textColor),

          titleLarge: TextStyle(fontSize: textSize + 4, color: textColor),
          titleMedium: TextStyle(fontSize: textSize + 2, color: textColor),
          titleSmall: TextStyle(fontSize: textSize, color: textColor),

          bodyLarge: TextStyle(fontSize: textSize, color: textColor),
          bodyMedium: TextStyle(fontSize: textSize + 2, color: textColor),
          bodySmall: TextStyle(fontSize: textSize, color: textColor),

          displayLarge: TextStyle(fontSize: textSize + 4, color: textColor),
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
          _scrollToAnchor(anchor);
        } else {
          _onTapLink(text, href, title);
        }
      },
    );
  }

  //Добавить в избранное
  Widget _buildFavouriteCard(String content, double textSize) {

    bool isBookmarked = false;

    return Card(
      elevation: 4.0,
      margin: EdgeInsets.all(8.0),
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: _buildMarkdown(content, textSize),
          ),
          Positioned(
            top: 8.0,
            right: 8.0,
            child: InkWell(
              onTap: () {
                setState(() {
                  isBookmarked = !isBookmarked;
                });
              },
              child: Icon(
                isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                color: isBookmarked ? Colors.yellowAccent : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

Widget _buildCard(String content, double textSize) {
    return Card(
      elevation: 4.0,
      margin: EdgeInsets.all(8.0),
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child: _buildMarkdown(content, textSize),
      ),
    );
  }
}