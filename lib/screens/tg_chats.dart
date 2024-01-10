import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:srbguide/localization/app_localizations.dart';
import 'package:srbguide/service/url_launcher_helper.dart';
import 'package:srbguide/widget/app_bar.dart';
import 'package:srbguide/widget/drawer/drawer.dart';
import 'package:srbguide/widget/themed/themed_icon.dart';

class TgChatScreen extends StatefulWidget {
  @override
  _TgChatScreenState createState() => _TgChatScreenState();
}

class _TgChatScreenState extends State<TgChatScreen> {
  late List<Map<String, dynamic>> buttonUrls = [];
  late List<Map<String, dynamic>> filteredButtons = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadJsonData();
    searchController.addListener(_filterButtons);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadJsonData() async {
    try {
      String jsonString = await rootBundle.loadString('assets/data/tg_chats.json');
      List<dynamic> jsonData = json.decode(jsonString);
      buttonUrls = List<Map<String, dynamic>>.from(jsonData);
      filteredButtons = List.from(buttonUrls);
      setState(() {});
    } catch (e) {
      print("Error loading JSON data: $e");
    }
  }

  void _filterButtons() {
    setState(() {
      String query = searchController.text.toLowerCase();
      if (query.isEmpty) {
        filteredButtons = List.from(buttonUrls);
      } else {
        filteredButtons = buttonUrls.where((map) {
          return map['name'].toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
      CustomAppBar(
        title: AppLocalizations.of(context)!.translate('tg_chats'),
      ),
      drawer: AppDrawer(),
      body: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.translate('search'),
                      prefixIcon: ThemedIcon(
                        iconPath: 'assets/icons_24x24/search.png',
                        size: 24.0,
                      ),
                      suffixIcon: searchController.text.isNotEmpty
                          ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          searchController.clear();
                          setState(() {
                            filteredButtons = List.from(buttonUrls);
                          });
                        },
                      )
                          : null,
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                },
                icon: ThemedIcon(
                  iconPath: 'assets/icons_24x24/filter.png',
                  size: 36.0,
                ),
              ),
            ],
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredButtons.length,
              itemBuilder: (context, index) {
                String title = filteredButtons[index]['name']!;
                String url = filteredButtons[index]['url']!;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    child: ListTile(
                      title: Text(title),
                      onTap: () {
                        UrlLauncherHelper.launchURL(url);
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
