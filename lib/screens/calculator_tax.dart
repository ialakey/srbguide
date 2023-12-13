import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:async';

class CalculatorTaxScreen extends StatefulWidget {
  @override
  _CalculatorTaxScreenState createState() => _CalculatorTaxScreenState();
}

class _CalculatorTaxScreenState extends State<CalculatorTaxScreen> {
  final Completer<WebViewController> _controller =
  Completer<WebViewController>();

  bool _isLoading = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          WebView(
            initialUrl: 'https://eporezi.purs.gov.rs/kalkulator-pausalnog-poreza-i-doprinosa.html',
            javascriptMode: JavascriptMode.unrestricted,
            onWebViewCreated: (WebViewController webViewController) {
              _controller.complete(webViewController);
            },
            onPageFinished: (String url) {
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