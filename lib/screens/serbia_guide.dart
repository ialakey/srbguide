import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class SerbiaGuideScreen extends StatefulWidget {
  @override
  _SerbiaGuideScreenState createState() => _SerbiaGuideScreenState();
}

class _SerbiaGuideScreenState extends State<SerbiaGuideScreen> {
  final Completer<WebViewController> _controller = Completer<WebViewController>();

  bool _isLoading = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          WebView(
            initialUrl: 'https://www.srb.guide',
            javascriptMode: JavascriptMode.unrestricted,
            onWebViewCreated: (WebViewController webViewController) {
              _controller.complete(webViewController);
            },
            onPageFinished: (String url) async {
              final webViewController = await _controller.future;
              webViewController.evaluateJavascript('document.cookie = "cookies_enabled=true";');
              setState(() {
                _isLoading = false;
              });
            },
          ),
          if (_isLoading)
            Container(
              color: Colors.white,
              alignment: Alignment.center,
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}