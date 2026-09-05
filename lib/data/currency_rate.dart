/// A single currency quote from an exchange office.
class CurrencyRate {
  /// ISO code, e.g. `EUR`.
  final String code;

  /// What the office pays you for the currency.
  final String buy;

  /// What the office charges you for it.
  final String sell;

  /// National Bank of Serbia reference rate, when the office publishes it.
  /// Useful as a neutral yardstick for how far an office's spread sits from
  /// the official rate.
  final String? nbs;

  const CurrencyRate({
    required this.code,
    required this.buy,
    required this.sell,
    this.nbs,
  });

  /// [sell] parsed as a number, for comparing offices.
  double? get sellValue => _asNumber(sell);

  /// [buy] parsed as a number, for comparing offices.
  double? get buyValue => _asNumber(buy);

  Map<String, dynamic> toJson() => <String, dynamic>{
        'code': code,
        'buy': buy,
        'sell': sell,
        if (nbs != null) 'nbs': nbs,
      };

  static CurrencyRate fromJson(Map<String, dynamic> json) => CurrencyRate(
        code: (json['code'] ?? '') as String,
        buy: (json['buy'] ?? '') as String,
        sell: (json['sell'] ?? '') as String,
        nbs: json['nbs'] as String?,
      );

  /// True when the quote is usable. Offices list currencies they do not
  /// actually trade as `0,0000`, which must not reach the UI as a real rate.
  bool get isComplete =>
      code.isNotEmpty &&
      buy.isNotEmpty &&
      sell.isNotEmpty &&
      (_asNumber(buy) ?? 0) > 0 &&
      (_asNumber(sell) ?? 0) > 0;

  static double? _asNumber(String raw) =>
      double.tryParse(raw.replaceAll(',', '.'));
}

/// Currencies shown first; anything else keeps the office's own order after
/// these. Migrants care about EUR/USD/RUB, the rest is noise for most people.
const List<String> kPreferredCurrencyOrder = <String>[
  'EUR',
  'USD',
  'RUB',
  'CHF',
  'GBP',
];

/// Sorts [rates] so the preferred currencies lead, preserving source order
/// among the remainder.
List<CurrencyRate> sortByPreferredOrder(List<CurrencyRate> rates) {
  final List<CurrencyRate> sorted = List<CurrencyRate>.from(rates);
  sorted.sort((CurrencyRate a, CurrencyRate b) {
    final int ia = kPreferredCurrencyOrder.indexOf(a.code);
    final int ib = kPreferredCurrencyOrder.indexOf(b.code);
    if (ia == -1 && ib == -1) return 0;
    if (ia == -1) return 1;
    if (ib == -1) return -1;
    return ia.compareTo(ib);
  });
  return sorted;
}
