import 'package:html/dom.dart';

import 'package:srbguide/data/currency_rate.dart';
import 'package:srbguide/service/parser/exchange_rate_parser.dart';

/// promonet.rs — TablePress table with an unusual layout:
/// the EUR quote sits in the `thead` (`buy | EUR | sell | note`) and the other
/// currencies follow in the `tbody` with the same column order.
///
/// The previous parser assigned tbody rows by `index % 2`, so the third row
/// (CHF) overwrote the RUB quote. Rows are matched on the code in column 1
/// instead.
class ProMonetParser extends ExchangeRateParser {
  @override
  String get name => 'ProMonet';

  @override
  String get url => 'https://www.promonet.rs';

  @override
  Future<List<CurrencyRate>> fetch() async {
    final Document document = await loadDocument();
    final Element? table = document.querySelector('.tablepress');
    if (table == null) {
      throw ExchangeRateException('$name: rate table not found');
    }

    final List<CurrencyRate> rates = <CurrencyRate>[];

    final Element? head = table.querySelector('thead');
    if (head != null) {
      final List<Element> cells = head.querySelectorAll('th');
      if (cells.length >= 3) {
        _addRate(rates, cells[1].text, cells[0].text, cells[2].text);
      }
    }

    final Element? body = table.querySelector('tbody');
    if (body != null) {
      for (final Element row in body.querySelectorAll('tr')) {
        final List<Element> cells = row.querySelectorAll('td');
        if (cells.length < 3) continue;
        _addRate(rates, cells[1].text, cells[0].text, cells[2].text);
      }
    }

    if (rates.isEmpty) {
      throw ExchangeRateException('$name: no rates in table');
    }
    return sortByPreferredOrder(rates);
  }

  void _addRate(
    List<CurrencyRate> into,
    String codeText,
    String buyText,
    String sellText,
  ) {
    final String code = extractCurrencyCode(codeText);
    if (!kSupportedCurrencies.contains(code)) return;
    if (into.any((CurrencyRate r) => r.code == code)) return;

    final CurrencyRate rate = CurrencyRate(
      code: code,
      buy: normalizeAmount(buyText),
      sell: normalizeAmount(sellText),
    );
    if (rate.isComplete) into.add(rate);
  }
}
