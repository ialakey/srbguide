import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class SmokersLoungeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WebView(
        initialUrl: 'https://lokalibezdima.rs',
        javascriptMode: JavascriptMode.unrestricted,
      ),
    );
  }
}