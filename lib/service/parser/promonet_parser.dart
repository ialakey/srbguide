import 'package:shared_preferences/shared_preferences.dart';

import 'exchange_rate_parser.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as htmlParser;

class ProMonetParser implements ExchangeRateParser {
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
    String url = 'https://www.promonet.rs';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final document = htmlParser.parse(response.body);
      final table = document.querySelector('.tablepress');

      if (table != null) {
        final thead = table.querySelector('thead');
        if (thead != null) {
          final headerCells = thead.querySelectorAll('th');
          valueEur = headerCells[0].text.trim();
          exchangeEur = headerCells[2].text.trim();
        }
        final tbody = table.querySelector('tbody');
        if (tbody != null) {
          final rows = tbody.querySelectorAll('tr');
          for (int i = 0; i < rows.length; i++) {
            final row = rows[i];
            final cells = row.querySelectorAll('td');

            if (cells.isNotEmpty) {
              if (i % 2 == 0) {
                valueRub = cells[0].text.trim();
                exchangeRub = cells[2].text.trim();
              } else {
                valueUsd = cells[0].text.trim();
                exchangeUsd = cells[2].text.trim();
              }
            }
          }

        }
      } else {
        print('Таблица с классом "tablepress" не найдена.');
      }
    } else {
      print('Ошибка при получении HTML: ${response.statusCode}');
    }
  }

  Future<void> getExchangeRateInHeader() async {
    late String exchangeRate;
    String url = 'https://www.promonet.rs';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final document = htmlParser.parse(response.body);
      final table = document.querySelector('.tablepress');

      if (table != null) {
        final thead = table.querySelector('thead');
        if (thead != null) {
          final headerCells = thead.querySelectorAll('th');
          List<String> headers = headerCells.map((headerCell) => headerCell.text.trim()).toList();
          exchangeRate = headers.join(" ");
        } else {
          exchangeRate = 'Ошибка загрузки';
        }
      } else {
        exchangeRate = 'Ошибка загрузки';
      }
    } else {
      exchangeRate = 'Ошибка загрузки: ${response.statusCode}';
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('exchangeRate', exchangeRate);
  }
}