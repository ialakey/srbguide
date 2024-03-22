import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:srbguide/localization/app_localizations.dart';
import 'package:srbguide/service/url_launcher_helper.dart';
import 'package:srbguide/widget/app_bar.dart';
import 'package:srbguide/widget/drawer/drawer.dart';
import 'package:srbguide/widget/themed/themed_icon.dart';
import 'package:http/http.dart' as http;

class TgChatScreen extends StatefulWidget {
  @override
  _TgChatScreenState createState() => _TgChatScreenState();
}

class _TgChatScreenState extends State<TgChatScreen> {
  late List<Map<String, dynamic>> buttonUrls = [];
  late List<Map<String, dynamic>> filteredButtons = [];
  TextEditingController searchController = TextEditingController();
  Set<String> uniqueGroups = Set();
  Set<String> selectedFilters = Set();

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
      final response = await http.get(Uri.parse('http://localhost:8080/tgchats'));

      if (response.statusCode == 200) {
        // Parse the response body if successful
        List<dynamic> jsonData = json.decode(response.body);
        buttonUrls = List<Map<String, dynamic>>.from(jsonData);

        uniqueGroups = buttonUrls.map((map) => map['group'] as String).toSet();

        filteredButtons = List.from(buttonUrls);
        print(jsonData);
        setState(() {});
      } else {
        // Handle errors if the request was not successful
        print("Error loading data from server. Status code: ${response.statusCode}");
      }
    } catch (e) {
      // Handle other exceptions
      print("Error loading data from server: $e");
    }
  }

  // Future<void> loadJsonData() async {
  //   try {
  //     String jsonString =
  //     await rootBundle.loadString('assets/data/tg_chats.json');
  //     List<dynamic> jsonData = json.decode(jsonString);
  //     buttonUrls = List<Map<String, dynamic>>.from(jsonData);
  //
  //     uniqueGroups = buttonUrls.map((map) => map['group'] as String).toSet();
  //
  //     filteredButtons = List.from(buttonUrls);
  //     setState(() {});
  //   } catch (e) {
  //     print("Error loading JSON data: $e");
  //   }
  // }

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

  void _applyFilters(Set<String> selectedFilters) {
    setState(() {
      if (selectedFilters.isEmpty) {
        filteredButtons = List.from(buttonUrls);
      } else {
        filteredButtons = buttonUrls.where((map) {
          return selectedFilters.contains(map['group']);
        }).toList();
      }
    });
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.translate('filter')),
          contentPadding: EdgeInsets.zero,
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: uniqueGroups
                      .map(
                        (group) => CheckboxListTile(
                      title: Text(group),
                      value: selectedFilters.contains(group),
                      onChanged: (value) {
                        setState(() {
                          if (value != null && value) {
                            selectedFilters.add(group);
                          } else {
                            selectedFilters.remove(group);
                          }
                        });
                      },
                    ),
                  )
                      .toList(),
                ),
              );
            },
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(AppLocalizations.of(context)!.translate('cancel')),
                ),
                TextButton(
                  onPressed: () {
                    _applyFilters(selectedFilters);
                    Navigator.of(context).pop();
                  },
                  child: Text(AppLocalizations.of(context)!.translate('apply')),
                ),
              ],
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
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
                      labelText:
                      AppLocalizations.of(context)!.translate('search'),
                      prefixIcon:
                      ThemedIcon(
                        iconPath: 'assets/icons_24x24/search-24.png',
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
                  _showFilterDialog();
                },
                icon: ThemedIcon(
                  iconPath: 'assets/icons_24x24/filter.png',
                  size: 24.0, // Adjust size here
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
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