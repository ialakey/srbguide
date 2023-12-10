import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class AuthorScreen extends StatelessWidget {

  final List<Map<String, String>> cryptoData = [
    {
      'Coin': 'ETH',
      'Network': 'Ethereum',
      'Address': '0x2483Dc9e39F16C1DFCc98B3E1445aC0157adB607',
    },
    {
      'Coin': 'USDT',
      'Network': 'Tron (TRC20)',
      'Address': 'TN4eVCvrm8JA21a5y7H2yRQFHAsWx8zjNh',
    },
    {
      'Coin': 'USDT',
      'Network': 'Ethereum (ERC20)',
      'Address': '0x001b7c9bd24bec8df46c3c0e9dfa8548a281d41e',
    },
    {
      'Coin': 'BTC',
      'Network': 'Bitcoin',
      'Address': '1F3ZDbiuAvb19USN13WQYrSj1CacadJ7Km',
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
              Text("Приложение делается на чистом энтузиазме, если вам помогло это приложение и вы хотите поблагодарить автора, то это можно сделать по ссылке ниже! 💫"),
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
                  style: TextStyle(color: Colors.black),
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
                  _launchURL('prosoulk2017@gmail.com');
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
