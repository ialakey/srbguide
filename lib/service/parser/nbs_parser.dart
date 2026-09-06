import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:srbguide/data/currency_rate.dart';
import 'package:srbguide/service/parser/exchange_rate_parser.dart';

/// The National Bank of Serbia's official rate.
///
/// Unlike the exchange offices this is not somewhere you can walk in and change
/// money — it is the reference every office prices against, so it belongs on
/// the screen as a yardstick rather than as a competing quote.
///
/// Served as JSON by kurs.resenje.org, a long-standing public mirror of the
/// NBS list. That is why this is the one source that does not need scraping.
class NbsParser extends ExchangeRateParser {
  static const String _api = 'https://kurs.resenje.org/api/v1/currencies';

  @override
  String get name => 'NBS';

  @override
  String get url => 'https://www.nbs.rs/en/indeks/index.html';

  @override
  bool get isReference => true;

  @override
  Future<List<CurrencyRate>> fetch() async {
    // One request per currency, run together rather than in sequence.
    final List<CurrencyRate?> results = await Future.wait(
      kPreferredCurrencyOrder.map(_fetchOne),
    );

    final List<CurrencyRate> rates = results.whereType<CurrencyRate>().toList();
    if (rates.isEmpty) {
      throw const ExchangeRateException('NBS: no rates returned');
    }
    return sortByPreferredOrder(rates);
  }

  Future<CurrencyRate?> _fetchOne(String code) async {
    try {
      final http.Response response = await http.get(
        Uri.parse('$_api/${code.toLowerCase()}/rates/today'),
        headers: const <String, String>{
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 16) AppleWebKit/537.36 srbguide-app',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) return null;

      final Map<String, dynamic> json_ =
          json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

      // Cash rates are what you get over the counter, but the NBS publishes
      // them only for the currencies it holds in cash — RUB and GBP come back
      // with the non-cash rate only.
      final num? buy = (json_['cash_buy'] ?? json_['exchange_buy']) as num?;
      final num? sell = (json_['cash_sell'] ?? json_['exchange_sell']) as num?;
      if (buy == null || sell == null) return null;

      final num? middle = json_['exchange_middle'] as num?;

      final CurrencyRate rate = CurrencyRate(
        code: code,
        buy: _format(buy),
        sell: _format(sell),
        nbs: middle == null ? null : _format(middle),
      );
      return rate.isComplete ? rate : null;
    } catch (_) {
      return null;
    }
  }

  /// Matches how the offices print their rates: two decimals, comma separator.
  /// Sub-unit currencies like RUB need more precision to stay meaningful.
  static String _format(num value) {
    final String text =
        value < 10 ? value.toStringAsFixed(4) : value.toStringAsFixed(2);
    return text.replaceAll('.', ',');
  }
}
