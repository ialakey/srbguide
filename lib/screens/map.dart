import 'package:flutter/material.dart';
import 'package:srbguide/app_localizations.dart';
import 'package:srbguide/widget/app_bar.dart';
import 'package:srbguide/widget/drawer.dart';
import 'package:srbguide/widget/themed_icon.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final List<Map<String, String>> locations = [
    {
      'iconPath': 'usd.png',
      'url': 'https://www.google.com/maps/search/Мењачница',
      'title': 'Обменники',
      'section': 'Карты',
    },
    {
      'iconPath': 'angry.png',
      'url': 'https://t.ly/YAx6',
      'title': 'Черный список квартир',
      'section': 'Карты',
    },
    {
      'iconPath': 'no-smoking.png',
      'url':
      'https://www.google.com/maps/d/viewer?mid=1DhbU4mNbi0OVkoRSpKBqBmWqeRXU5vo&usp=sharing',
      'title': 'Не курящие',
      'section': 'Карты',
    },
    {
      'iconPath': 'tea.png',
      'url':
      'https://www.google.com/maps/d/u/0/viewer?mid=12l4BVYg_FV0d9CMeEWEtnJDQioL9804&ll=sharing',
      'title': 'Русские заведения',
      'section': 'Карты',
    },
  ];

  late Map<String, String> selectedLocation;
  late Key webViewKey;
  late String selectedUrl;
  late String selectedIconPath;

  @override
  void initState() {
    super.initState();
    selectedLocation = locations[0];
    selectedUrl = selectedLocation['url'] ?? '';
    webViewKey = UniqueKey();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
      CustomAppBar(
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
              child: DropdownButton<Map<String, String>>(
                value: selectedLocation,
                onChanged: (newValue) {
                  setState(() {
                    selectedLocation = newValue!;
                    selectedUrl = newValue['url'] ?? '';
                    webViewKey = UniqueKey();
                  });
                },
                items: locations.map<DropdownMenuItem<Map<String, String>>>(
                      (location) {
                    return DropdownMenuItem<Map<String, String>>(
                      value: location,
                      child: Row(
                        children: [
                          ThemedIcon(
                            lightIcon: 'assets/icons_24x24/${location['iconPath']}',
                            darkIcon: 'assets/icons_24x24/${location['iconPath']}',
                            size: 24.0,
                          ),
                          SizedBox(width: 8),
                          Text(location['title'] ?? ''),
                        ],
                      ),
                    );
                  },
                ).toList(),
                icon:
                ThemedIcon(
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
          ],
        ),
      ),
    );
  }
}
