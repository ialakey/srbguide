import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:photo_view/photo_view.dart';
import 'package:srbguide/widget/custom_search.dart';
import 'package:srbguide/widget/drawer.dart';
import 'package:url_launcher/url_launcher.dart';
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
    final pattern = RegExp(r'<a\b[^>]*>(.*?)<\/a>');
    return htmlString.replaceAll(pattern, '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('🚜 Гайд по Сербии'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
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
          child: _buildMarkdownBody(),
        ),
      ),
    );
  }

  Widget _buildMarkdownBody() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    } else if (_markdownContent == null) {
      return Center(child: Text('No data'));
    } else {
      final contentWithoutATags = _removeATags(_markdownContent);
      return MarkdownBody(
        selectable: true,
        key: GlobalKey(),
        data: contentWithoutATags,
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
  }
}