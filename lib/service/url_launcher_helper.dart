import 'package:url_launcher/url_launcher.dart';

class UrlLauncherHelper {
  static Future<void> launchURL(String urlKey) async {
    final Uri url = Uri.parse(urlKey);
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }
}
