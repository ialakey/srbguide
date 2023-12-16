import 'package:flutter/material.dart';
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
      'url': 'https://www.google.com/maps/d/viewer?mid=1yZgQ4K-QdicajdZ3OGIxzpUjoMWJkcg&usp=sharing',
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
      'https://www.google.com/maps/d/viewer?mid=17hd5rO7Sw0y9URWFQOt6L1EerZ74Buc&usp=sharing',
      'title': 'Русские заведения',
      'section': 'Карты',
    },
  ];

  late Map<String, String> selectedLocation;
  late Key webViewKey;
  late String selectedUrl;

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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButton<Map<String, String>>(
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
                    child: Text(location['title'] ?? ''),
                  );
                },
              ).toList(),
              style: TextStyle(
                color: Colors.blue, // Example text color
                fontSize: 16.0,
              ),
              icon: Icon(
                Icons.arrow_drop_down,
                color: Colors.blue, // Example icon color
              ),
              dropdownColor: Colors.white,
            ),
            SizedBox(height: 20.0),
            Expanded(
              child: selectedUrl.isNotEmpty
                  ? WebView(
                key: webViewKey,
                initialUrl: selectedUrl,
                javascriptMode: JavascriptMode.unrestricted,
                onPageFinished: (url) {
                  // Add your custom logic when the page finishes loading
                },
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