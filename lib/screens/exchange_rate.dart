import 'package:flutter/material.dart';
import 'package:srbguide/localization/app_localizations.dart';
import 'package:srbguide/service/parser/dok_parser.dart';
import 'package:srbguide/service/parser/exchange_office.dart';
import 'package:srbguide/service/parser/funta_parser.dart';
import 'package:srbguide/service/parser/gaga_parser.dart';
import 'package:srbguide/service/parser/promonet_parser.dart';
import 'package:srbguide/service/url_launcher_helper.dart';
import 'package:srbguide/widget/drawer/drawer.dart';
import 'package:srbguide/widget/themed/themed_icon.dart';

class ExchangeRateScreen extends StatefulWidget {
  @override
  _ExchangeRateScreenState createState() => _ExchangeRateScreenState();
}

class _ExchangeRateScreenState extends State<ExchangeRateScreen> {
  late List<ExchangeOffice> exchangeOffices;
  bool isLoading = true;
  double progress = 0.0;

  @override
  void initState() {
    super.initState();
    exchangeOffices = [
      ExchangeOffice(name: 'ProMonet', url: 'https://www.promonet.rs', parser: ProMonetParser()),
      ExchangeOffice(name: 'Funta', url: 'https://funta.rs', parser: FuntaParser()),
      ExchangeOffice(name: 'Gaga', url: 'https://menjacnicegaga.rs/#kursna', parser: GagaParser()),
      ExchangeOffice(name: 'Dok', url: 'https://www.menjacnicedok.rs/kursna_lista.html', parser: DokParser()),
    ];

    loadData();
  }

  Future<void> loadData() async {
    for (var i = 0; i < exchangeOffices.length; i++) {
      var office = exchangeOffices[i];
      await office.parser.parse();

      setState(() {
        progress = (i + 1) / exchangeOffices.length;
      });
    }

    setState(() {
      isLoading = false;
      progress = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.translate('exchange_rate'),
        ),
        actions: [
          IconButton(
            icon: ThemedIcon(
              iconPath: 'assets/icons_24x24/rotate-right.png',
              size: 20.0,
            ),
            onPressed: loadData,
          ),
        ],
      ),
      drawer: AppDrawer(),
      body: isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LinearProgressIndicator(value: progress),
            SizedBox(height: 16.0),
            Text(
              '${AppLocalizations.of(context)!.translate('loading')} ${(progress * 100).toStringAsFixed(2)}%',
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      )
          : ListView(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                '${AppLocalizations.of(context)!.translate('exchange_rate_on')} ${DateTime.now().day.toString()}.${DateTime.now().month.toString().padLeft(2, '0')}.${DateTime.now().year.toString()}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          ...exchangeOffices.map((office) => ExchangeRateCard(exchangeOffice: office)).toList(),
        ],
      ),
    );
  }
}

class ExchangeRateCard extends StatelessWidget {
  final ExchangeOffice exchangeOffice;

  const ExchangeRateCard({Key? key, required this.exchangeOffice})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(10),
      child: Column(
        children: [
          ListTile(
            title: Text(exchangeOffice.name),
            onTap: () async {
              UrlLauncherHelper.launchURL(exchangeOffice.url);
            },
          ),
          DataTable(
            columns: [
              DataColumn(label: Text(
                  AppLocalizations.of(context)!.translate('buy'))),
              DataColumn(label: Text(
                  AppLocalizations.of(context)!.translate('currency'))),
              DataColumn(label: Text(
                  AppLocalizations.of(context)!.translate('sell'))),
            ],
            rows: [
              if (exchangeOffice.parser.getValueEur() != '' &&
                  exchangeOffice.parser.getCurrencyEur() != '' &&
                  exchangeOffice.parser.getExchangeEur() != '')
                DataRow(cells: [
                  DataCell(Text(exchangeOffice.parser.getValueEur())),
                  DataCell(Text(exchangeOffice.parser.getCurrencyEur())),
                  DataCell(Text(exchangeOffice.parser.getExchangeEur())),
                ]),
              if (exchangeOffice.parser.getValueRub() != '' &&
                  exchangeOffice.parser.getCurrencyRub() != '' &&
                  exchangeOffice.parser.getExchangeRub() != '')
                DataRow(cells: [
                  DataCell(Text(exchangeOffice.parser.getValueRub())),
                  DataCell(Text(exchangeOffice.parser.getCurrencyRub())),
                  DataCell(Text(exchangeOffice.parser.getExchangeRub())),
                ]),
              if (exchangeOffice.parser.getValueUsd() != '' &&
                  exchangeOffice.parser.getCurrencyUsd() != '' &&
                  exchangeOffice.parser.getExchangeUsd() != '')
                DataRow(cells: [
                  DataCell(Text(exchangeOffice.parser.getValueUsd())),
                  DataCell(Text(exchangeOffice.parser.getCurrencyUsd())),
                  DataCell(Text(exchangeOffice.parser.getExchangeUsd())),
                ]),
            ],
          ),
        ],
      ),
    );
  }
}
