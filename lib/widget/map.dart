import 'package:flutter/material.dart';
import 'package:srbguide/service/url_launcher_helper.dart';
import 'package:srbguide/widget/themed_icon.dart';

class MapWidgets {
  static Widget googleMapsCard({
    required String iconPath,
    required String url,
    required String title,
    required BuildContext context,
  }) {
    return Column(
      children: [
        Card(
          child: ListTile(
            leading: ThemedIcon(
              lightIcon: 'assets/icons_24x24/$iconPath',
              darkIcon: 'assets/icons_24x24/$iconPath',
              size: 24.0,
            ),
            title: Text(title),
            onTap: () {
              UrlLauncherHelper.launchURL(url);
              Navigator.pop(context);
            },
          ),
        ),
        SizedBox(height: 8),
      ],
    );
  }
}