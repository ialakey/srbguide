@Tags(<String>['live'])
library;

// Live smoke test against the real exchange-office sites.
// Run with: flutter test test/exchange_parsers_live_test.dart
//
// These hit the network on purpose — the parsers exist to track markup that
// changes without notice, and only a live run tells us they still match.

import 'package:flutter_test/flutter_test.dart';
import 'package:srbguide/data/currency_rate.dart';
import 'package:srbguide/service/parser/dok_parser.dart';
import 'package:srbguide/service/parser/exchange_rate_parser.dart';
import 'package:srbguide/service/parser/funta_parser.dart';
import 'package:srbguide/service/parser/nbs_parser.dart';
import 'package:srbguide/service/parser/gaga_parser.dart';
import 'package:srbguide/service/parser/promonet_parser.dart';

void main() {
  final List<ExchangeRateParser> offices = <ExchangeRateParser>[
    NbsParser(),
    ProMonetParser(),
    FuntaParser(),
    GagaParser(),
    DokParser(),
  ];

  for (final ExchangeRateParser office in offices) {
    test('${office.name} returns a EUR quote', () async {
      final List<CurrencyRate> rates = await office.fetch();
      // ignore: avoid_print
      print(
          '${office.name}: ${rates.map((CurrencyRate r) => '${r.code} ${r.buy}/${r.sell}').join('  ')}');
      expect(rates, isNotEmpty);
      expect(rates.any((CurrencyRate r) => r.code == 'EUR'), isTrue,
          reason: '${office.name} should quote EUR');
      for (final CurrencyRate r in rates) {
        expect(r.isComplete, isTrue, reason: '${r.code} incomplete');
        expect(RegExp(r'^[0-9]+(,[0-9]+)?$').hasMatch(r.buy), isTrue,
            reason: '${office.name} ${r.code} buy="${r.buy}" not numeric');
      }
    }, timeout: const Timeout(Duration(seconds: 60)));
  }
}
