import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:srbguide/app_localizations.dart';
import 'package:srbguide/widget/drawer.dart';
import 'package:srbguide/widget/card_guide.dart';
import 'package:srbguide/widget/themed_icon.dart';

class GuideScreen extends StatefulWidget {
  @override
  _GuideScreenState createState() => _GuideScreenState();
}

class _GuideScreenState extends State<GuideScreen> {
  Map<String, List<Map<String, dynamic>>> locations = {};

  List<Map<String, dynamic>> filteredLocations = [];

  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    _loadLocations();
    super.initState();
  }

  /*TODO разобраться с поиском, при удаление данные не возвращаются
    вынести все классы и виджеты
  */
  Future<void> _loadLocations() async {
    try {
      String jsonData = await rootBundle.loadString('assets/guide.json');
      Map<String, dynamic> decodedJson = json.decode(jsonData);

      if (decodedJson.containsKey('ru') && decodedJson['ru'] is List<dynamic>) {
        List<Map<String, dynamic>> locationsList = (decodedJson['ru'] as List<dynamic>).expand<Map<String, dynamic>>((item) {
          String section = item['group'] ?? '';
          String icon = item['icon'] ?? '';
          List<Map<String, dynamic>> items = (item['items'] as List<dynamic>).cast<Map<String, dynamic>>();

          List<Map<String, dynamic>> itemsWithGroup = items.map<Map<String, dynamic>>((item) {
            return {
              ...item,
              'group': section,
              'icon': icon,
            };
          }).toList();

          return itemsWithGroup;
        }).toList();

        setState(() {
          filteredLocations = locationsList;
        });
      }
    } catch (e) {
      print('Error loading locations: $e');
    }
  }

  Map<String, LocationGroup> _groupLocations() {
    Map<String, LocationGroup> grouped = {};

    if (filteredLocations.isNotEmpty) {
      for (var location in filteredLocations) {
        String? section = location['group'];
        String? icon = location['icon'];
        if (section != null) {
          if (!grouped.containsKey(section)) {
            grouped[section] = LocationGroup(
              group: section,
              icon: icon ?? '',
              items: [],
            );
          }
          grouped[section]!.items.add({
            'smile': location['smile'] ?? '',
            'title': location['title'] ?? '',
            'description': location['description'] ?? '',
          });
        }
      }
    }
    return grouped;
  }

  void filterLocations(String query) {
    List<Map<String, dynamic>> _filteredLocations = filteredLocations.where((location) {
      return location['title']?.toLowerCase().contains(query.toLowerCase());
    }).toList();

    setState(() {
      filteredLocations = _filteredLocations;
    });
  }

  Widget _buildSection(String sectionTitle, String icon, List<Map<String, String>> sectionItems) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Row(
            children: [
              Text(
                sectionTitle,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(
                width: 7,
              ),
              ThemedIcon(
                lightIcon: 'assets/icons_24x24/$icon',
                darkIcon: 'assets/icons_24x24/$icon',
                size: 24.0,
              ),
            ],
          ),
        ),
        SizedBox(height: 8),
        Column(
          children: sectionItems.map((location) {
            return CardWidgets.cardWidgets(
              smile: location['smile'] ?? '',
              title: location['title'] ?? '',
              content: location['description'] ?? '',
              context: context,
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    Map<String, LocationGroup> groupedLocations = _groupLocations();
    return Scaffold(
      appBar: AppBar(
        title: Text('🚜 Гайд по Сербии'),
      ),
      drawer: AppDrawer(),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              onChanged: (value) {
                filterLocations(value);
              },
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.translate('search'),
                prefixIcon: ThemedIcon(
                  lightIcon: 'assets/icons_24x24/search.png',
                  darkIcon: 'assets/icons_24x24/search.png',
                  size: 24.0,
                ),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    searchController.clear();
                    filterLocations('');
                  },
                )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: groupedLocations.length,
              itemBuilder: (BuildContext context, int index) {
                LocationGroup group = groupedLocations.values.elementAt(index);
                return _buildSection(group.group, group.icon, group.items);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class LocationGroup {
  final String group;
  final String icon;
  final List<Map<String, String>> items;

  LocationGroup({required this.group, required this.icon, required this.items});
}