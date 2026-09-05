import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:srbguide/localization/app_localizations.dart';
import 'package:srbguide/service/url_launcher_helper.dart';
import 'package:srbguide/widget/app_bar.dart';
import 'package:srbguide/widget/themed/themed_icon.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  List<Map<String, dynamic>> locations = [];
  late Map<String, dynamic> selectedLocation = {};
  late final WebViewController _webViewController;
  late String selectedUrl = "";

  @override
  void initState() {
    super.initState();
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          // Map providers redirect to intent:// / geo:// to hand the route off
          // to a native app. The WebView can't load those schemes and shows
          // ERR_UNKNOWN_URL_SCHEME, so send them to the platform instead.
          onNavigationRequest: (NavigationRequest request) {
            final Uri? uri = Uri.tryParse(request.url);
            if (uri != null && uri.scheme != 'http' && uri.scheme != 'https') {
              UrlLauncherHelper.launchURL(request.url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );
    loadLocations();
  }

  Future<void> loadLocations() async {
    String data = await DefaultAssetBundle.of(context)
        .loadString('assets/data/locations.json');
    setState(() {
      locations = List<Map<String, dynamic>>.from(json.decode(data));
      if (locations.isNotEmpty) {
        selectedLocation = locations[0];
        selectedUrl = selectedLocation['url'] ?? '';
      }
    });
    if (selectedUrl.isNotEmpty) {
      await _webViewController.loadRequest(Uri.parse(selectedUrl));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (locations.isEmpty) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: AppLocalizations.of(context)!.translate('maps'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: double.infinity,
              child: DropdownButton<Map<String, dynamic>>(
                value: selectedLocation,
                onChanged: (newValue) {
                  setState(() {
                    selectedLocation = newValue!;
                    selectedUrl = newValue['url'] ?? '';
                  });
                  if (selectedUrl.isNotEmpty) {
                    _webViewController.loadRequest(Uri.parse(selectedUrl));
                  }
                },
                items: locations.map<DropdownMenuItem<Map<String, dynamic>>>(
                  (location) {
                    return DropdownMenuItem<Map<String, dynamic>>(
                      value: location,
                      child: Row(
                        children: [
                          ThemedIcon(
                            iconPath:
                                'assets/icons_24x24/${location['iconPath']}',
                            size: 24.0,
                          ),
                          SizedBox(width: 8),
                          Text(location['title'] ?? ''),
                        ],
                      ),
                    );
                  },
                ).toList(),
                icon: ThemedIcon(
                  iconPath: 'assets/icons_24x24/caret-down.png',
                  size: 24.0,
                ),
              ),
            ),
            SizedBox(height: 10.0),
            Expanded(
              child: selectedUrl.isNotEmpty
                  ? WebViewWidget(controller: _webViewController)
                  : Center(
                      child: Text('No URL selected'),
                    ),
            ),
            Card(
              margin: EdgeInsets.all(8.0),
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
                title: Center(
                  child: Text(
                    AppLocalizations.of(context)!
                        .translate('open_selected_map'),
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                onTap: () {
                  if (selectedUrl.isNotEmpty) {
                    UrlLauncherHelper.launchURL(selectedUrl);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('No URL selected')),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
