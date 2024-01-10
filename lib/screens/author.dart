import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:srbguide/localization/app_localizations.dart';
import 'package:srbguide/service/url_launcher_helper.dart';
import 'package:srbguide/widget/app_bar.dart';
import 'package:srbguide/widget/drawer/drawer.dart';

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
    'LinkedIn': 'https://www.linkedin.com/in/ilya-alakov-14b979266',
    'Gmail': 'mailto:prosoulk2017@gmail.com',
    'GitHub': 'https://github.com/ialakey/srbguide',
    // 'Telegram с фильмами': 'https://t.me/kino_narezo4ka',
  };

  List<Widget> generateListTiles(Map<String, String> links) {
    return links.entries.map((entry) {
      return Card(
          margin: EdgeInsets.all(8.0),
          child:
            ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
              title: Center(
                child: Text(
                  entry.key,
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              onTap: () {
                UrlLauncherHelper.launchURL(entry.value);
              },
            ));
        }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
      CustomAppBar(
        title: AppLocalizations.of(context)!.translate('author'),
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
                AppLocalizations.of(context)!.translate('info_by_author'),
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
                  AppLocalizations.of(context)!.translate('donate'),
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                AppLocalizations.of(context)!.translate('crypto'),
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
              ...generateListTiles(links),
            ],
          ),
        ),
      ),
    );
  }
}
