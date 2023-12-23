import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:srbguide/helper/text_size_dialog.dart';
import 'package:srbguide/utils/contents_util.dart';
import 'package:srbguide/widget/custom_search.dart';
import 'package:srbguide/widget/markdown/markdown_body.dart';
import 'package:srbguide/widget/markdown/popup_menu_item.dart';
import 'package:url_launcher/url_launcher.dart';
typedef ScrollToTextFunction = void Function(String text);

class MarkdownReaderScreen extends StatefulWidget {
  final String title;
  final String content;

  MarkdownReaderScreen({required this.content, required this.title});

  @override
  _MarkdownReaderScreenState createState() => _MarkdownReaderScreenState();
}

class _MarkdownReaderScreenState extends State<MarkdownReaderScreen> {
  late String _title;
  late String _markdownContent;
  late ScrollController _scrollController;
  late TextEditingController _searchController;
  bool _isLoading = true;
  double _currentTextSize = 18.0;
  final MarkdownHelper _markdownHelper = MarkdownHelper();
  final ContentUtil _contentUtil = ContentUtil();

  @override
  void initState() {
    super.initState();
    _loadSavedTextSize();
    _scrollController = ScrollController();
    _searchController = TextEditingController();
    _title = widget.title;
    _markdownContent = widget.content;
    _isLoading = false;
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
        title: Text(_title),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        actions: [
          ActionMenuButton(
            onTapChangeTextSize: () {
              DialogHelper.showTextSizeDialog(
                context,
                _currentTextSize,
                _setTextSize,
              );
            },
            onTapSearch: () async {
              String? searchValue = await showSearch<String>(
                context: context,
                delegate: CustomSearchDelegate(
                  _contentUtil.removeATags(_markdownContent),
                  _scrollToText,
                ),
              );
              if (searchValue != null && searchValue.isNotEmpty) {
                _searchController.text = searchValue;
                _scrollToText(searchValue);
              }
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: _markdownHelper.buildMarkdownBody(
            context,
            _isLoading,
            _markdownContent,
            textSize,
            _onTapLink,
            _scrollToAnchor,
          ),
        ),
      ),
    );
  }
}