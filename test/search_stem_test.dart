import 'package:flutter_test/flutter_test.dart';
import 'package:srbguide/utils/search_stem.dart';

void main() {
  group('stemWord', () {
    test('strips Russian inflection so forms share a stem', () {
      // The bug this exists for: "банка" used to find nothing.
      expect(stemWord('банка'), stemWord('банки'));
      expect(stemWord('банка'), 'банк');
      expect('банки'.startsWith(stemWord('банка')), isTrue);
      expect('банковский'.startsWith(stemWord('банка')), isTrue);
    });

    test('leaves short words alone', () {
      // "ВНЖ" must not be cut down to something that matches everything.
      expect(stemWord('внж'), 'внж');
      expect(stemWord('виза'), 'виза');
    });

    test('never produces a stem shorter than the floor', () {
      for (final String w in <String>[
        'дом',
        'налог',
        'документы',
        'страхование',
      ]) {
        expect(stemWord(w).length, greaterThanOrEqualTo(3),
            reason: 'stem of "$w" is too short');
      }
    });

    test('handles English endings', () {
      expect(stemWord('documents'), 'document');
      expect(stemWord('banking'), 'bank');
    });

    test('is case-insensitive', () {
      expect(stemWord('Банки'), stemWord('банки'));
    });
  });

  group('stemQuery', () {
    test('splits on punctuation and drops empties', () {
      expect(stemQuery('  банки, налоги!  '), <String>['банк', 'налог']);
    });

    test('returns nothing for a blank query', () {
      expect(stemQuery('   '), isEmpty);
      expect(stemQuery(''), isEmpty);
    });

    test('keeps digits', () {
      expect(stemQuery('2026'), <String>['2026']);
    });
  });
}
