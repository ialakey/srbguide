import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

class MyMarkdownScreen extends StatefulWidget {
  @override
  _MyMarkdownScreenState createState() => _MyMarkdownScreenState();
}

class _MyMarkdownScreenState extends State<MyMarkdownScreen> {
  late String _markdownContent;
  late ScrollController _scrollController;
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _loadMarkdownFile();
    _scrollController = ScrollController();
    _searchController = TextEditingController();
  }

  Future<void> _loadMarkdownFile() async {
    String data = await rootBundle.loadString('assets/test.md');
    setState(() {
      _markdownContent = data;
    });
  }

  void _scrollToText(String text) {
    final index = _markdownContent.indexOf(text);
    if (index != -1) {
      final key = GlobalKey(debugLabel: index.toString());
      WidgetsBinding.instance?.addPostFrameCallback((_) {
        final RenderBox renderBox =
        key.currentContext?.findRenderObject() as RenderBox;
        _scrollController.animateTo(
          renderBox.localToGlobal(Offset.zero).dy,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Сербия начало'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () async {
              String? searchValue = await showSearch<String>(
                context: context,
                delegate: _CustomSearchDelegate(),
              );
              if (searchValue != null && searchValue.isNotEmpty) {
                _searchController.text = searchValue;
                _scrollToText(searchValue);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: _markdownContent != null
              ? MarkdownBody(
            key: GlobalKey(),
            data: _markdownContent,
            onTapLink: (text, href, title) {
              _onTapLink(text, href, title);
            },
          )
              : Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}

class _CustomSearchDelegate extends SearchDelegate<String> {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return Container();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Container();
  }
}