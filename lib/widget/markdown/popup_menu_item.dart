import 'package:flutter/material.dart';
import 'package:srbguide/widget/themed_icon.dart';

class ActionMenuButton extends StatelessWidget {
  final Function() onTapChangeTextSize;
  final Function() onTapSearch;
  // final Function() onTapAddToFavorite;

  ActionMenuButton({
    required this.onTapChangeTextSize,
    required this.onTapSearch,
    // required this.onTapAddToFavorite,
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
                lightIcon: 'assets/icons_24x24/letter-case.png',
                darkIcon: 'assets/icons_24x24/letter-case.png',
                size: 24.0,
              ),
              title: Text('Изменить размер текста'),
            ),
          ),
          PopupMenuItem(
            child: ListTile(
              onTap: onTapSearch,
              leading: ThemedIcon(
                lightIcon: 'assets/icons_24x24/search.png',
                darkIcon: 'assets/icons_24x24/search.png',
                size: 24.0,
              ),
              title: Text('Поиск'),
            ),
          ),
          PopupMenuItem(
            child: ListTile(
              // onTap: onTapAddToFavorite,
              leading: ThemedIcon(
                lightIcon: 'assets/icons_24x24/bookmark.png',
                darkIcon: 'assets/icons_24x24/bookmark.png',
                size: 24.0,
              ),
              title: Text('Добавить в избранное'),
            ),
          ),
        ];
      },
      icon: ThemedIcon(
        lightIcon: 'assets/icons_24x24/circle-ellipsis-vertical.png',
        darkIcon: 'assets/icons_24x24/circle-ellipsis-vertical.png',
        size: 24.0,
      ),
    );
  }
}
