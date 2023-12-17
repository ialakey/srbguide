import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:srbguide/service/url_launcher_helper.dart';
import 'package:srbguide/widget/app_bar.dart';
import 'package:srbguide/widget/drawer.dart';

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

  final Map<String, String> links = {
    'Linkedin': 'https://www.linkedin.com/in/ilya-alakov-14b979266',
    'Почта': 'mailto:prosoulk2017@gmail.com',
    'GitHub': 'https://github.com/ialakey/srbguide',
    // 'Telegram с фильмами': 'https://t.me/kino_narezo4ka',
  };

  List<Widget> generateButtons(Map<String, String> links) {
    return links.entries.map((entry) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: ElevatedButton(
          onPressed: () {
            UrlLauncherHelper.launchURL(entry.value);
          },
          child: SizedBox(
            width: 150,
            child: Center(child: Text(entry.key)),
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
      CustomAppBar(
        title: 'Автор',
      ),
      drawer: AppDrawer(),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Это приложение разрабатывается исключительно на основе энтузиазма. Если оно оказало вам помощь и вы желаете выразить благодарность автору, есть несколько способов сделать это! 😎",
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
                child:
                Text(
                  'По номеру телефона +7 952 633 49 42 СПБ Сбер, QIWI',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text('Крипта',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),),
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
              ...generateButtons(links),
            ],
          ),
        ),
      ),
    );
  }
}
