import 'package:flutter/material.dart';
import 'package:srbguide/service/url_launcher_helper.dart';
import 'package:srbguide/widget/themed_icon.dart';

class MapWidgets {
  static Widget googleMapsListTile({
    required String iconPath,
    required String url,
    required String title,
    required BuildContext context,
  }) {
    return ListTile(
      leading: ThemedIcon(
        lightIcon: iconPath,
        darkIcon: iconPath,
        size: 24.0,
      ),
      title: Text(title),
      onTap: () {
        UrlLauncherHelper.launchURL(url);
        Navigator.pop(context);
      },
    );
  }
}
