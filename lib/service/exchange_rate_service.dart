import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:srbguide/data/currency_rate.dart';
import 'package:srbguide/service/parser/dok_parser.dart';
import 'package:srbguide/service/parser/exchange_rate_parser.dart';
import 'package:srbguide/service/parser/funta_parser.dart';
import 'package:srbguide/service/parser/nbs_parser.dart';
import 'package:srbguide/service/parser/gaga_parser.dart';
import 'package:srbguide/service/parser/promonet_parser.dart';

/// Result of querying one office: either its rates, or why it failed.
class OfficeRates {
  final ExchangeRateParser office;
  final List<CurrencyRate> rates;
  final String? error;

  const OfficeRates({
    required this.office,
    this.rates = const <CurrencyRate>[],
    this.error,
  });

  bool get hasError => error != null;
}

/// Fetches rates from every supported office.
///
/// Offices are queried concurrently and one failing office no longer blocks
/// the others — previously a single broken site left the whole screen empty.
class ExchangeRateService {
  static const String _summaryKey = 'exchangeRateSummary';
  static const String _cacheKey = 'exchangeRatesCache';
  static const String _cacheAtKey = 'exchangeRatesCachedAt';

  static List<ExchangeRateParser> buildOffices() => <ExchangeRateParser>[
        NbsParser(),
        ProMonetParser(),
        FuntaParser(),
        GagaParser(),
        DokParser(),
      ];

  /// Queries all offices. [onProgress] receives 0..1 as results land.
  static Future<List<OfficeRates>> fetchAll({
    void Function(double progress)? onProgress,
  }) async {
    final List<ExchangeRateParser> offices = buildOffices();
    final List<OfficeRates?> results =
        List<OfficeRates?>.filled(offices.length, null);
    int done = 0;

    await Future.wait(
      List<Future<void>>.generate(offices.length, (int i) async {
        final ExchangeRateParser office = offices[i];
        try {
          final List<CurrencyRate> rates = await office.fetch();
          results[i] = OfficeRates(office: office, rates: rates);
        } catch (e) {
          results[i] = OfficeRates(office: office, error: e.toString());
        } finally {
          done++;
          onProgress?.call(done / offices.length);
        }
      }),
    );

    final List<OfficeRates> ok = results.whereType<OfficeRates>().toList();
    await _cache(ok);
    return ok;
  }

  /// Stores the offices that answered, so a later offline open still shows
  /// something. Previously the screen was simply empty with no connection.
  static Future<void> _cache(List<OfficeRates> results) async {
    final List<OfficeRates> usable = results
        .where((OfficeRates r) => !r.hasError && r.rates.isNotEmpty)
        .toList();
    if (usable.isEmpty) return;

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _cacheKey,
      json.encode(<Map<String, dynamic>>[
        for (final OfficeRates r in usable)
          <String, dynamic>{
            'name': r.office.name,
            'url': r.office.url,
            'reference': r.office.isReference,
            'rates': r.rates.map((CurrencyRate c) => c.toJson()).toList(),
          },
      ]),
    );
    await prefs.setString(_cacheAtKey, DateTime.now().toIso8601String());
  }

  /// Last successful fetch, or an empty list when there has never been one.
  static Future<({List<OfficeRates> offices, DateTime? at})> cached() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_cacheKey);
    final DateTime? at = DateTime.tryParse(prefs.getString(_cacheAtKey) ?? '');
    if (raw == null || raw.isEmpty) {
      return (offices: const <OfficeRates>[], at: at);
    }
    try {
      final List<dynamic> decoded = json.decode(raw) as List<dynamic>;
      return (
        offices: decoded
            .cast<Map<String, dynamic>>()
            .map((Map<String, dynamic> e) => OfficeRates(
                  office: _CachedOffice(
                    e['name'] as String? ?? '',
                    e['url'] as String? ?? '',
                    (e['reference'] ?? false) as bool,
                  ),
                  rates: ((e['rates'] ?? <dynamic>[]) as List<dynamic>)
                      .cast<Map<String, dynamic>>()
                      .map(CurrencyRate.fromJson)
                      .toList(),
                ))
            .toList(),
        at: at,
      );
    } catch (_) {
      return (offices: const <OfficeRates>[], at: at);
    }
  }

  /// The office offering the most dinars per unit of [code] when selling to
  /// you (lowest `sell`), across everything that answered.
  static BestRate? bestSell(List<OfficeRates> results, String code) {
    BestRate? best;
    for (final OfficeRates office in results) {
      if (office.hasError || office.office.isReference) continue;
      for (final CurrencyRate rate in office.rates) {
        if (rate.code != code) continue;
        final double? value = rate.sellValue;
        if (value == null) continue;
        if (best == null || value < (best.rate.sellValue ?? double.infinity)) {
          best = BestRate(office: office, rate: rate);
        }
      }
    }
    return best;
  }

  /// The official NBS rate for [code], preferring the bank's own feed over an
  /// office that happens to reprint it.
  static String? referenceRate(List<OfficeRates> results, String code) {
    for (final OfficeRates office in results) {
      if (!office.office.isReference) continue;
      for (final CurrencyRate rate in office.rates) {
        if (rate.code == code && rate.nbs != null) return rate.nbs;
      }
    }
    for (final OfficeRates office in results) {
      for (final CurrencyRate rate in office.rates) {
        if (rate.code == code && rate.nbs != null) return rate.nbs;
      }
    }
    return null;
  }

  /// Refreshes the short EUR line shown in the drawer header. Never throws —
  /// a failed refresh just leaves the previously cached value in place.
  static Future<void> refreshSummary() async {
    for (final ExchangeRateParser office in buildOffices()) {
      if (office.isReference) continue;
      try {
        final List<CurrencyRate> rates = await office.fetch();
        final CurrencyRate eur = rates.firstWhere(
          (CurrencyRate r) => r.code == 'EUR',
          orElse: () => rates.first,
        );
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          _summaryKey,
          '${eur.code} ${eur.buy} / ${eur.sell} · ${office.name}',
        );
        return;
      } catch (_) {
        // Try the next office.
      }
    }
  }

  static Future<String> cachedSummary() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_summaryKey) ?? '';
  }
}

/// The cheapest office for one currency.
class BestRate {
  final OfficeRates office;
  final CurrencyRate rate;

  const BestRate({required this.office, required this.rate});

  String get officeName => office.office.name;

  String get officeUrl => office.office.url;
}

/// Stands in for a real parser when rates come back from the offline cache.
class _CachedOffice extends ExchangeRateParser {
  _CachedOffice(this._name, this._url, this._isReference);

  final String _name;
  final String _url;
  final bool _isReference;

  @override
  bool get isReference => _isReference;

  @override
  String get name => _name;

  @override
  String get url => _url;

  @override
  Future<List<CurrencyRate>> fetch() async =>
      throw const ExchangeRateException('cached office cannot be refetched');
}
