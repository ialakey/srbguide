import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class SerbiaGuideScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WebView(
        initialUrl: 'https://www.srb.guide',
        javascriptMode: JavascriptMode.unrestricted,
      ),
    );
  }
}