import 'package:flutter/material.dart';
import 'package:srbguide/widget/map.dart';
import 'package:srbguide/widget/themed_icon.dart';

class UsefulLinksScreen extends StatefulWidget {
  @override
  _UsefulLinksScreenState createState() => _UsefulLinksScreenState();
}

class _UsefulLinksScreenState extends State<UsefulLinksScreen> {
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
    {
      'iconPath': 'home-location.png',
      'url':
      'https://docs.google.com/spreadsheets/d/1nfsCW2oXz2lIJ7E4b4RPN_rTRPVp2svl3zAy2NSCqHc/edit#gid=2073213305',
      'title': 'Нови Сад',
      'section': 'Ссылки',
    },
  ];

  List<Map<String, String>> filteredLocations = [];

  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    filteredLocations = locations;
    super.initState();
  }

  void filterLocations(String query) {
    List<Map<String, String>> _filteredLocations = [];
    _filteredLocations.addAll(locations.where((location) {
      return location['title']!.toLowerCase().contains(query.toLowerCase());
    }));

    setState(() {
      filteredLocations = _filteredLocations;
    });
  }

  Map<String, List<Map<String, String>>> _groupLocations() {
    Map<String, List<Map<String, String>>> grouped = {};

    for (var location in filteredLocations) {
      String section = location['section']!;
      if (!grouped.containsKey(section)) {
        grouped[section] = [];
      }
      grouped[section]!.add(location);
    }
    return grouped;
  }

  Widget _buildSection(String sectionTitle, List<Map<String, String>> sectionItems) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
        Column(
          children: sectionItems.map((location) {
            return MapWidgets.googleMapsCard(
              iconPath: location['iconPath']!,
              url: location['url']!,
              title: location['title']!,
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
                prefixIcon:
                ThemedIcon(
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

                return _buildSection(sectionTitle, sectionItems);
              },
            ),
          ),
        ],
      ),
    );
  }
}