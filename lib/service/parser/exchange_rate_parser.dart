import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

import 'package:srbguide/data/currency_rate.dart';

/// One exchange office the app can quote rates from.
///
/// Implementations scrape the office's public rate table. They match rows by
/// currency code rather than by row/column position, because the offices
/// change their table markup regularly and positional parsing silently
/// produced wrong currencies when they did.
abstract class ExchangeRateParser {
  /// Display name of the office.
  String get name;

  /// Public page the rates come from; also opened when the user taps the card.
  String get url;

  /// True for the official reference rate rather than a place you can walk
  /// into. Reference sources are excluded from "best rate" comparisons.
  bool get isReference => false;

  /// Fetches the current rates. Throws [ExchangeRateException] on failure so
  /// the UI can tell "office is down" apart from "office has no rates".
  Future<List<CurrencyRate>> fetch();

  /// Downloads [url] and parses it into a DOM document.
  Future<Document> loadDocument({String? overrideUrl}) async {
    final Uri uri = Uri.parse(overrideUrl ?? url);
    late http.Response response;
    try {
      response = await http.get(uri, headers: const <String, String>{
        // Some of these sites return a stub body to unknown agents.
        'User-Agent': 'Mozilla/5.0 (Linux; Android 16) AppleWebKit/537.36 '
            'srbguide-app',
        'Accept-Language': 'sr,en;q=0.8,ru;q=0.6',
      }).timeout(const Duration(seconds: 20));
    } catch (e) {
      throw ExchangeRateException('$name: network error ($e)');
    }
    if (response.statusCode != 200) {
      throw ExchangeRateException('$name: HTTP ${response.statusCode}');
    }
    return html_parser.parse(response.body);
  }
}

/// Raised when an office cannot be reached or its page no longer parses.
class ExchangeRateException implements Exception {
  final String message;
  const ExchangeRateException(this.message);

  @override
  String toString() => message;
}

/// Currency codes worth surfacing. Offices list a long tail (TRY, DKK, ...)
/// that only clutters the card.
const Set<String> kSupportedCurrencies = <String>{
  'EUR',
  'USD',
  'RUB',
  'CHF',
  'GBP',
};

/// Normalizes a scraped number: strips spaces/NBSP and unifies the decimal
/// separator to a comma, which is what these offices use locally.
String normalizeAmount(String raw) {
  final String cleaned =
      raw.replaceAll(' ', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  if (cleaned.isEmpty) return '';
  // Offices mix "117.20" and "117,20" in the same table.
  return cleaned.replaceAll('.', ',');
}

/// Pulls a 3-letter currency code out of [raw], or returns `''`.
String extractCurrencyCode(String raw) {
  final Match? m = RegExp(r'\b([A-Z]{3})\b').firstMatch(raw.toUpperCase());
  return m == null ? '' : m.group(1)!;
}
