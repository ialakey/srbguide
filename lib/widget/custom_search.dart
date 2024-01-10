import 'package:flutter/material.dart';
import 'package:srbguide/localization/app_localizations.dart';
typedef ScrollToTextFunction = void Function(String text);

class CustomSearchDelegate extends SearchDelegate<String> {

  final String contentWithoutATags;
  final ScrollToTextFunction scrollToText;

  CustomSearchDelegate(this.contentWithoutATags, this.scrollToText);

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
    final List<String> searchResults = contentWithoutATags
        .split('\n')
        .where((line) => line.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: searchResults.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(searchResults[index]),
          onTap: () {
            final selectedText = searchResults[index];
            close(context, selectedText);
            scrollToText(selectedText);
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Container();
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