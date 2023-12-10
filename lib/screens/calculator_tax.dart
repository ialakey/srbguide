import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class CalculatorTaxScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WebView(
        initialUrl: 'https://eporezi.purs.gov.rs/kalkulator-pausalnog-poreza-i-doprinosa.html',
        javascriptMode: JavascriptMode.unrestricted,
      ),
    );
  }
}