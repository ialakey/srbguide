import 'package:flutter/material.dart';
import 'package:srbguide/service/url_launcher_helper.dart';
import 'package:srbguide/widget/drawer/drawer.dart';

class ExchangeRateScreen extends StatelessWidget {
  final List<ExchangeOffice> exchangeOffices = [
    ExchangeOffice(name: 'Exchange Office 1', url: 'https://exchange1.com'),
    ExchangeOffice(name: 'Exchange Office 2', url: 'https://exchange2.com'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Курс валют на ${DateTime.now().day}.${DateTime.now().month.toString().padLeft(2, '0')}.${DateTime.now().year}'),
      ),
      drawer: AppDrawer(),
      body: ListView.builder(
        itemCount: exchangeOffices.length,
        itemBuilder: (context, index) {
          return ExchangeRateCard(exchangeOffice: exchangeOffices[index]);
        },
      ),
    );
  }
}

class ExchangeRateCard extends StatelessWidget {
  final ExchangeOffice exchangeOffice;

  const ExchangeRateCard({Key? key, required this.exchangeOffice}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(10),
      child: Column(
        children: [
          ListTile(
            title: Text(exchangeOffice.name),
            onTap: () {
              UrlLauncherHelper.launchURL(exchangeOffice.url);
            },
          ),
          DataTable(
            columns: [
              DataColumn(label: Text('Курс')),
              DataColumn(label: Text('Валюта')),
              DataColumn(label: Text('Обмен')),
            ],
            rows: [
              DataRow(cells: [
                DataCell(Text('117.10')),
                DataCell(Text('EUR')),
                DataCell(Text('117,50')),
              ]),
              DataRow(cells: [
                DataCell(Text('1.06')),
                DataCell(Text('RUB')),
                DataCell(Text('1.172')),
              ]),
              DataRow(cells: [
                DataCell(Text('106.00')),
                DataCell(Text('USD')),
                DataCell(Text('107.60')),
              ]),
            ],
          ),
        ],
      ),
    );
  }
}

class ExchangeOffice {
  final String name;
  final String url;

  ExchangeOffice({required this.name, required this.url});
}
