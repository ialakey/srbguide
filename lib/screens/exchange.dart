import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ExchangePlacesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WebView(
        initialUrl: 'https://www.google.com/maps/search/exchange',
        javascriptMode: JavascriptMode.unrestricted,
      ),
    );
  }
}