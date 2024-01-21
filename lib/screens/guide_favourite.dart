import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:srbguide/localization/app_localizations.dart';
import 'package:srbguide/screens/markdown_reader.dart';
import 'package:srbguide/widget/drawer/drawer.dart';

class GuideFavoritesScreen extends StatefulWidget {
  @override
  _GuideFavoritesScreenState createState() => _GuideFavoritesScreenState();
}

class _GuideFavoritesScreenState extends State<GuideFavoritesScreen> {
  late Map<String, String> favorites = {};

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    Map<String, String> savedFavorites =
    Map<String, String>.from(json.decode(prefs.getString('favorites') ?? '{}'));
    setState(() {
      favorites = savedFavorites;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.translate('favourite')),
      ),
      drawer: AppDrawer(),
      body: favorites.isEmpty
          ? Center(
        child: Text(AppLocalizations.of(context)!.translate('no_favourite_message')),
      )
          : ListView.builder(
        itemCount: favorites.length,
        itemBuilder: (context, index) {
          String title = favorites.keys.elementAt(index);
          String content = favorites[title]!;
          return Card(
            child: ListTile(
              title: Text(title),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MarkdownReaderScreen(
                      title: title,
                      content: content,
                    ),
                  ),
                );
                _loadFavorites();
              },
            ),
          );
        },
      ),
    );
  }
}
