import 'package:html/dom.dart';

import 'package:srbguide/data/currency_rate.dart';
import 'package:srbguide/service/parser/exchange_rate_parser.dart';

/// funta.rs — TablePress table.
///
/// The site dropped `tbody.row-hover` and renumbered its columns
/// (`column-4/5` became `column-2/3`), which is why the old positional parser
/// returned nothing. Columns are now read by their `column-N` class and rows
/// matched on the currency code in the first column.
class FuntaParser extends ExchangeRateParser {
  @override
  String get name => 'Funta';

  @override
  String get url => 'https://funta.rs';

  @override
  Future<List<CurrencyRate>> fetch() async {
    final Document document = await loadDocument();
    final Element? table = document.querySelector('#tablepress-2') ??
        document.querySelector('table.tablepress');
    if (table == null) {
      throw ExchangeRateException('$name: rate table not found');
    }

    final List<CurrencyRate> rates = <CurrencyRate>[];
    for (final Element row in table.querySelectorAll('tr')) {
      final Element? currencyCell = row.querySelector('td.column-1');
      final Element? buyCell = row.querySelector('td.column-2');
      final Element? sellCell = row.querySelector('td.column-3');
      if (currencyCell == null || buyCell == null || sellCell == null) continue;

      final String code = extractCurrencyCode(currencyCell.text);
      if (!kSupportedCurrencies.contains(code)) continue;

      final CurrencyRate rate = CurrencyRate(
        code: code,
        buy: normalizeAmount(buyCell.text),
        sell: normalizeAmount(sellCell.text),
      );
      if (rate.isComplete) rates.add(rate);
    }

    if (rates.isEmpty) {
      throw ExchangeRateException('$name: no rates in table');
    }
    return sortByPreferredOrder(rates);
  }
}
