import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:srbguide/widget/drawer.dart';
import 'package:srbguide/widget/map.dart';
import 'package:srbguide/widget/themed_icon.dart';

class GuideScreen extends StatefulWidget {
  @override
  _GuideScreenState createState() => _GuideScreenState();
}

class _GuideScreenState extends State<GuideScreen> {
  Map<String, List<Map<String, String>>> locations = {};

  List<Map<String, String>> filteredLocations = [];

  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    _loadLocations();
    super.initState();
  }

  Future<void> _loadLocations() async {
    try {
      String jsonData = await rootBundle.loadString('assets/guide.json');
      Map<String, dynamic> decodedJson = json.decode(jsonData);

      if (decodedJson.containsKey('ru') && decodedJson['ru'] is List<dynamic>) {
        List<Map<String, String>> locationsList = (decodedJson['ru'] as List<dynamic>)
            .map((item) => Map<String, String>.from(item))
            .toList();

        setState(() {
          locations['ru'] = locationsList;
          filteredLocations = locationsList;
        });
      }
    } catch (e) {
      print('Error loading locations: $e');
    }
  }

  void filterLocations(String query) {
    List<Map<String, String>> _filteredLocations = locations['ru']!.where((location) {
      return location['title']!.toLowerCase().contains(query.toLowerCase());
    }).toList();

    setState(() {
      filteredLocations = _filteredLocations;
    });
  }

  Map<String, List<Map<String, String>>> _groupLocations() {
    Map<String, List<Map<String, String>>> grouped = {};

    for (var location in filteredLocations) {
      String section = location['group']!;
      if (!grouped.containsKey(section)) {
        grouped[section] = [];
      }
      grouped[section]!.add(location);
    }
    return grouped;
  }

  Widget _buildSection(String sectionTitle, String icon, List<Map<String, String>> sectionItems) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: Text(
                sectionTitle,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ThemedIcon(
              lightIcon: 'assets/icons_24x24/$icon',
              darkIcon: 'assets/icons_24x24/$icon',
              size: 24.0,
            ),
          ],
        ),
        Column(
          children: sectionItems.map((location) {
            return MapWidgets.googleMapsCard(
              url: "null",
              title: location['smile']! + " " + location['title']!,
              content: location['description']!, // Changed 'content' to 'description'
              context: context,
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    Map<String, List<Map<String, String>>> groupedLocations = _groupLocations();
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
                labelText: 'Поиск',
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
                String sectionTitle = groupedLocations.keys.elementAt(index);
                List<Map<String, String>> sectionItems = groupedLocations.values.elementAt(index);

                return _buildSection(sectionTitle, "usd.png", sectionItems);
              },
            ),
          ),
        ],
      ),
    );
  }
}