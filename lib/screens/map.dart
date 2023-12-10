import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MapScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WebView(
        initialUrl: 'https://www.google.com/maps/d/u/0/viewer?mid=12l4BVYg_FV0d9CMeEWEtnJDQioL9804&ll=45.23992208501285%2C19.854860046985962&z=13',
        javascriptMode: JavascriptMode.unrestricted,
      ),
    );
  }
}