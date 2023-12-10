import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class TgChatScreen extends StatefulWidget {
  @override
  _TgChatScreenState createState() => _TgChatScreenState();
}

class _TgChatScreenState extends State<TgChatScreen> {
  final Map<String, String> buttonUrls = {
    'Чат Сербских IT-ИП. Паушал, налоги, книжар': 'https://t.me/serbia_self_it',
    'Кнопка 2': 'https://example.com/button2',
    'Кнопка 3': 'https://example.com/button3',
    'Кнопка 4': 'https://example.com/button4',
    'Кнопка 5': 'https://example.com/button5',
    'Кнопка 6': 'https://example.com/button2',
    'Кнопка 7': 'https://example.com/button3',
    'Кнопка 8': 'https://example.com/button4',
    'Кнопка 9': 'https://example.com/button5',
    'Кнопка 10': 'https://example.com/button2',
    'Кнопка 11': 'https://example.com/button3',
    'Кнопка 12': 'https://example.com/button4',
    'Кнопка 13': 'https://example.com/button5',
    'Кнопка 14': 'https://example.com/button2',
    'Кнопка 15': 'https://example.com/button3',
    'Кнопка 16': 'https://example.com/button4',
    'Кнопка 17': 'https://example.com/button5',
  };

  late List<String> filteredButtons;

  @override
  void initState() {
    super.initState();
    filteredButtons = buttonUrls.keys.toList();
  }

  void _filterButtons(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredButtons = buttonUrls.keys.toList();
      } else {
        filteredButtons = buttonUrls.keys.where((button) {
          return button.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Список телеграм каналов'),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: TextField(
              onChanged: _filterButtons,
              decoration: InputDecoration(
                labelText: 'Поиск',
                prefixIcon: Icon(Icons.search),
                contentPadding: EdgeInsets.symmetric(vertical: 10.0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredButtons.length,
              itemBuilder: (context, index) {
                String title = filteredButtons[index];
                String url = buttonUrls[title]!;

                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed: () {
                      _launchURL(url);
                    },
                    child: Text(title),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchURL(String urlKey) async {
    final Uri url = Uri.parse(urlKey);
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }
}
