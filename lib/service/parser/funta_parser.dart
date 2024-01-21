import 'exchange_rate_parser.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as htmlParser;
import 'package:html/dom.dart';

class FuntaParser implements ExchangeRateParser {
  late String valueEur = '';
  late String valueRub = '';
  late String valueUsd = '';

  late String currencyEur = 'EUR';
  late String currencyRub = 'RUB';
  late String currencyUsd = 'USD';

  late String exchangeEur = '';
  late String exchangeRub = '';
  late String exchangeUsd = '';

  @override
  String getCurrencyEur() {
    return currencyEur;
  }

  @override
  String getCurrencyRub() {
    return currencyRub;
  }

  @override
  String getCurrencyUsd() {
    return currencyUsd;
  }

  @override
  String getExchangeEur() {
    return exchangeEur;
  }

  @override
  String getExchangeRub() {
    return exchangeRub;
  }

  @override
  String getExchangeUsd() {
    return exchangeUsd;
  }

  @override
  String getValueEur() {
    return valueEur;
  }

  @override
  String getValueRub() {
    return valueRub;
  }

  @override
  String getValueUsd() {
    return valueUsd;
  }

  @override
  Future<void> parse() async {
    String url = 'https://funta.rs';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final document = htmlParser.parse(response.body);
      List<String> listRow = ['row-2', 'row-11', 'row-15'];
      _parseRow(document, listRow);
    } else {
      print('Error: ${response.statusCode}');
    }
  }

  void _parseRow(Document document, List<String> rowClasses) {
    final table = document.querySelector('#tablepress-2');
    if (table != null) {
      final tbody = table.querySelector('tbody.row-hover');
      if (tbody != null) {
        List<String> values = [];

        for (String rowClass in rowClasses) {
          final row = tbody.querySelector('tr.$rowClass');
          if (row != null) {
            row.querySelectorAll('td.column-4, td.column-5').forEach((column) {
              values.add(column.text.trim());
            });
          } else {
            print('Row not found for $rowClass');
          }
        }

        if (values.length >= 2) {
          valueEur = values[0];
          exchangeEur = values[1];
        }
        if (values.length >= 4) {
          valueRub = values[2];
          exchangeRub = values[3];
        }
        if (values.length >= 6) {
          valueUsd = values[4];
          exchangeUsd = values[5];
        }
      } else {
        print('Tbody with class "row-hover" not found');
      }
    } else {
      print('Table with id "tablepress-2" not found');
    }
  }

}