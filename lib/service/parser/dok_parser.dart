import 'package:html/dom.dart';

import 'package:srbguide/data/currency_rate.dart';
import 'package:srbguide/service/parser/exchange_rate_parser.dart';

/// menjacnicedok.rs — classic HTML table.
///
/// Row shape: `Country | numeric code | CODE | unit | buy | sell | name`
/// The currency code lives in cell 2, so rows are matched on that instead of
/// assuming EUR is first and USD is second.
class DokParser extends ExchangeRateParser {
  @override
  String get name => 'Dok';

  @override
  String get url => 'https://www.menjacnicedok.rs/kursna_lista.html';

  @override
  Future<List<CurrencyRate>> fetch() async {
    final Document document = await loadDocument();
    final List<CurrencyRate> rates = <CurrencyRate>[];

    for (final Element row in document.querySelectorAll('tr')) {
      final List<Element> cells = row.querySelectorAll('td');
      if (cells.length < 6) continue;

      final String code = extractCurrencyCode(cells[2].text);
      if (!kSupportedCurrencies.contains(code)) continue;

      final String buy = normalizeAmount(cells[4].text);
      final String sell = normalizeAmount(cells[5].text);
      final CurrencyRate rate = CurrencyRate(code: code, buy: buy, sell: sell);
      if (rate.isComplete) rates.add(rate);
    }

    if (rates.isEmpty) {
      throw ExchangeRateException('$name: rate table not found');
    }
    return sortByPreferredOrder(rates);
  }
}
