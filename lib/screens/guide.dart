import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:srbguide/localization/app_localizations.dart';
import 'package:srbguide/data/guide_dto.dart';
import 'package:srbguide/widget/drawer/drawer.dart';
import 'package:srbguide/widget/section.dart';

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

  Future<void> _loadLocations() async {
    try {
      String jsonData = await rootBundle.loadString('assets/data/guide.json');
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

  Map<String, Guide> _guides() {
    Map<String, Guide> grouped = {};

    if (filteredLocations.isNotEmpty) {
      for (var location in filteredLocations) {
        String? section = location['group'];
        String? icon = location['icon'];
        if (section != null) {
          if (!grouped.containsKey(section)) {
            grouped[section] = Guide(
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

  @override
  Widget build(BuildContext context) {
    Map<String, Guide> groupedLocations = _guides();
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.translate('guide')),
      ),
      drawer: AppDrawer(),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: 20),
                    Text(
                      'Описание каждой жизненной ситуации для экспатов из РФ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 20),
                    InteractiveViewer(
                      child: Image.network(
                        'https://github.com/ialakey/serbia.guide/assets/56916175/336f8093-06cc-405c-9122-49bf1a0b727a',
                        fit: BoxFit.contain,
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Более детальную информацию по каждому пункту ищите в разделах ниже',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 10),
                  ],
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: groupedLocations.length,
                  itemBuilder: (BuildContext context, int index) {
                    Guide guide = groupedLocations.values.elementAt(index);
                    return buildSection(context, guide.group, guide.icon, guide.items);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}