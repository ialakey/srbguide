import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AuthorScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                _launchURL('https://www.linkedin.com/in/ilya-alakov-14b979266');
              },
              child: Text('Linkedin'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _launchURL('https://t.me/kino_narezo4ka');
              },
              child: Text('Telegram с фильмами'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _launchURL('https://www.instagram.com/unnamed_junior');
              },
              child: Text('Instagram'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _launchURL('prosoulk2017@gmail.com');
              },
              child: Text('Почта'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _launchURL('https://www.paypal.com/your-paypal-url');
              },
              child: Text('Пожертвовать'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchURL(String urlKey) async {
    final Uri url = Uri.parse(urlKey);
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }
}
