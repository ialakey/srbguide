import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class AuthorScreen extends StatelessWidget {

  final List<Map<String, String>> cryptoData = [
    {
      'Coin': 'USDT',
      'Network': 'Tron (TRC20)',
      'Address': 'TUHt3r2ufuMabviaowEsQmynoV1tYE6DFg',
    },
    {
      'Coin': 'BTC',
      'Network': 'Bitcoin',
      'Address': '17RQZqoUcy4jmkk5ciYQAV3DfZU9MfBYX1',
    },
    {
      'Coin': 'ETH',
      'Network': 'Ethereum (ERC20)',
      'Address': '0xc3ca11d069f67ffa826ce6172f0e5466b66ef3f8',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Приложение делается на чистом энтузиазме, если вам помогло это приложение и вы хотите поблагодарить автора, то это можно сделать следующим способам! 💫"),
              SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: '+7 952 633 49 42'));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Номер телефона скопирован'),
                    ),
                  );
                },
                child: Text(
                  'По номеру телефона +7 952 633 49 42 СПБ Сбер, QIWI',
                ),
              ),
              SizedBox(height: 20),
              Text('Крипта'),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: [
                    DataColumn(label: Text('Coin')),
                    DataColumn(label: Text('Network')),
                    DataColumn(label: Text('Address')),
                  ],
                  rows: cryptoData.map((data) {
                    return DataRow(cells: [
                      DataCell(Text(data['Coin'] ?? '')),
                      DataCell(Text(data['Network'] ?? '')),
                      DataCell(
                        GestureDetector(
                          onLongPress: () {
                            Clipboard.setData(ClipboardData(text: data['Address'] ?? ''));
                          },
                          child: Text(data['Address'] ?? ''),
                        ),
                      ),
                    ]);
                  }).toList(),
                ),
              ),
              SizedBox(height: 20),
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
                  _launchURL('mailto:prosoulk2017@gmail.com');
                },
                child: Text('Почта'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  _launchURL('https://github.com/ialakey');
                },
                child: Text('GitHub'),
              ),
              // SizedBox(height: 20),
              // ElevatedButton(
              //   onPressed: () {
              //     _launchURL('https://www.paypal.com/your-paypal-url');
              //   },
              //   child: Text('Пожертвовать'),
              // ),
            ],
          ),
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
