import 'exchange_rate_parser.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as htmlParser;
import 'package:html/dom.dart';

class DokParser implements ExchangeRateParser {
  late String valueEur = '';
  late String valueRub = '';
  late String valueUsd = '';

  late String currencyEur = 'EUR';
  late String currencyRub = '';
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
    String url = 'https://www.menjacnicedok.rs/kursna_lista.html';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final document = htmlParser.parse(response.body);
      _parseTable(document);
    } else {
      print('Error: ${response.statusCode}');
    }
  }

  void _parseTable(Document document) {
    final tbodyList = document.querySelectorAll('tbody');
    if (tbodyList.length >= 2) {
      final secondTbody = tbodyList[1];
      final rows = secondTbody.querySelectorAll('tr');

      if (rows.length >= 2) {
        final firstRowCells = rows[0].querySelectorAll('td');
        if (firstRowCells.length >= 6) {
          valueEur = firstRowCells[4].text.trim();
          exchangeEur = firstRowCells[5].text.trim();
        } else {
          print('Not enough cells in the first row');
        }
        final secondRowCells = rows[1].querySelectorAll('td');
        if (secondRowCells.length >= 6) {
          valueUsd = secondRowCells[4].text.trim();
          exchangeUsd = secondRowCells[5].text.trim();
        } else {
          print('Not enough cells in the second row');
        }
      } else {
        print('Not enough rows in the second tbody');
      }
    } else {
      print('Not enough tbody elements in the document');
    }
  }

}