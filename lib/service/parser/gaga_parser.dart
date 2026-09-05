import 'package:html/dom.dart';

import 'package:srbguide/data/currency_rate.dart';
import 'package:srbguide/service/parser/exchange_rate_parser.dart';

/// menjacnicegaga.rs — no longer a table at all.
///
/// The site replaced its TablePress table (`#tablepress-1`) with a ticker built
/// from `.rate-ticker-row` / `.rate-ticker-cell` divs, so the old table lookup
/// always failed. Cells are: `currency | buy | NBS reference | sell`.
class GagaParser extends ExchangeRateParser {
  @override
  String get name => 'Gaga';

  @override
  String get url => 'https://menjacnicegaga.rs/#kursna';

  @override
  Future<List<CurrencyRate>> fetch() async {
    final Document document =
        await loadDocument(overrideUrl: 'https://menjacnicegaga.rs/');

    final List<Element> rows = document.querySelectorAll('.rate-ticker-row');
    if (rows.isEmpty) {
      throw ExchangeRateException('$name: rate ticker not found');
    }

    final List<CurrencyRate> rates = <CurrencyRate>[];
    for (final Element row in rows) {
      final List<Element> cells = row.querySelectorAll('.rate-ticker-cell');
      if (cells.length < 4) continue;

      final String code = extractCurrencyCode(cells[0].text);
      if (!kSupportedCurrencies.contains(code)) continue;

      // cells[2] is the NBS reference rate — kept alongside the office's own
      // buy/sell so the UI can show how far the spread sits from official.
      final String nbs = normalizeAmount(cells[2].text);
      final CurrencyRate rate = CurrencyRate(
        code: code,
        buy: normalizeAmount(cells[1].text),
        sell: normalizeAmount(cells[3].text),
        nbs: nbs.isEmpty ? null : nbs,
      );
      if (rate.isComplete) rates.add(rate);
    }

    if (rates.isEmpty) {
      throw ExchangeRateException('$name: no rates in ticker');
    }
    return sortByPreferredOrder(rates);
  }
}
