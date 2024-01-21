import 'package:flutter/material.dart';
import 'package:srbguide/localization/app_localizations.dart';
import 'package:srbguide/widget/themed/themed_icon.dart';

class ActionMenuButton extends StatelessWidget {
  final Function() onTapChangeTextSize;
  final Function() onTapSearch;
  final Function() onTapAddToFavorite;
  final String buttonText;
  final String icon;

  ActionMenuButton({
    required this.onTapChangeTextSize,
    required this.onTapSearch,
    required this.onTapAddToFavorite,
    required this.buttonText,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      itemBuilder: (BuildContext context) {
        return [
          PopupMenuItem(
            child: ListTile(
              onTap: onTapChangeTextSize,
              leading: ThemedIcon(
                iconPath: 'assets/icons_24x24/text.png',
                size: 24.0,
              ),
              title: Text(AppLocalizations.of(context)!.translate('change_size_text')),
            ),
          ),
          PopupMenuItem(
            child: ListTile(
              onTap: onTapSearch,
              leading: ThemedIcon(
                iconPath: 'assets/icons_24x24/search.png',
                size: 24.0,
              ),
              title: Text(AppLocalizations.of(context)!.translate('search')),
            ),
          ),
          PopupMenuItem(
            child: ListTile(
              onTap: onTapAddToFavorite,
              leading: ThemedIcon(
                iconPath: 'assets/icons_24x24/$icon',
                size: 24.0,
              ),
              title: Text(buttonText),
            ),
          ),
        ];
      },
      icon: ThemedIcon(
        iconPath: 'assets/icons_24x24/menu-dots-vertical.png',
        size: 24.0,
      ),
    );
  }
}
