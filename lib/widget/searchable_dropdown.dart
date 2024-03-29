import 'package:flutter/material.dart';
import 'package:srbguide/localization/app_localizations.dart';

class SearchableDropdownDelegate extends SearchDelegate<String> {
  final List<String> locations;

  SearchableDropdownDelegate(this.locations);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final List<String> searchResults = locations
        .where((location) => location.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: searchResults.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(searchResults[index]),
          onTap: () {
            close(context, searchResults[index]);
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final List<String> suggestionList = locations
        .where((location) => location.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: suggestionList.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(suggestionList[index]),
          onTap: () {
            close(context, suggestionList[index]);
          },
        );
      },
    );
  }

  @override
  Widget buildSearchField(BuildContext context) {
    return TextField(
      autofocus: true,
      decoration: InputDecoration(
        hintText: AppLocalizations.of(context)!.translate('search_placeholder'),
        border: InputBorder.none,
        hintStyle: TextStyle(color: Colors.grey),
      ),
      style: TextStyle(color: Colors.black),
      onChanged: (value) {
        query = value;
      },
    );
  }
}