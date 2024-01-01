import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:srbguide/app_localizations.dart';
import 'package:srbguide/service/url_launcher_helper.dart';
import 'package:srbguide/widget/app_bar.dart';
import 'package:srbguide/widget/drawer.dart';
import 'package:srbguide/widget/themed_icon.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  List<Map<String, dynamic>> locations = [];
  late Map<String, dynamic> selectedLocation = {};
  late Key webViewKey;
  late String selectedUrl = "";

  @override
  void initState() {
    super.initState();
    loadLocations();
  }

  Future<void> loadLocations() async {
    String data =
    await DefaultAssetBundle.of(context).loadString('assets/data/locations.json');
    setState(() {
      locations = List<Map<String, dynamic>>.from(json.decode(data));
      if (locations.isNotEmpty) {
        selectedLocation = locations[0];
        selectedUrl = selectedLocation['url'] ?? '';
        webViewKey = UniqueKey();
      }
    });
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
      drawer: AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: double.infinity,
              child: DropdownButton<Map<String, dynamic>>(
                value: selectedLocation,
                onChanged: (newValue) {
                  setState(() {
                    selectedLocation = newValue!;
                    selectedUrl = newValue['url'] ?? '';
                    webViewKey = UniqueKey();
                  });
                },
                items: locations.map<DropdownMenuItem<Map<String, dynamic>>>(
                      (location) {
                    return DropdownMenuItem<Map<String, dynamic>>(
                      value: location,
                      child: Row(
                        children: [
                          ThemedIcon(
                            lightIcon:
                            'assets/icons_24x24/${location['iconPath']}',
                            darkIcon:
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
                  lightIcon: 'assets/icons_24x24/caret-down.png',
                  darkIcon: 'assets/icons_24x24/caret-down.png',
                  size: 24.0,
                ),
              ),
            ),
            SizedBox(height: 10.0),
            Expanded(
              child: selectedUrl.isNotEmpty
                  ? WebView(
                key: webViewKey,
                initialUrl: selectedUrl,
                javascriptMode: JavascriptMode.unrestricted,
                onPageFinished: (url) {},
              )
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
                    AppLocalizations.of(context)!.translate('open_selected_map'),
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