import 'package:flutter_test/flutter_test.dart';
import 'package:srbguide/data/deadline.dart';

Deadline _deadline(DeadlineKind kind, DateTime date) =>
    Deadline(id: 'test', kind: kind, date: date);

void main() {
  group('daysLeft', () {
    test('counts whole days regardless of time of day', () {
      final DateTime now = DateTime.now();
      final Deadline d = _deadline(
        DeadlineKind.visaRun,
        DateTime(now.year, now.month, now.day).add(const Duration(days: 5)),
      );
      expect(d.daysLeft, 5);
    });

    test('is zero on the day itself', () {
      final DateTime now = DateTime.now();
      final Deadline d = _deadline(
        DeadlineKind.visaRun,
        DateTime(now.year, now.month, now.day, 23, 59),
      );
      expect(d.daysLeft, 0);
      expect(d.isOverdue, isFalse);
    });

    test('goes negative once passed', () {
      final DateTime now = DateTime.now();
      final Deadline d = _deadline(
        DeadlineKind.visaRun,
        DateTime(now.year, now.month, now.day)
            .subtract(const Duration(days: 2)),
      );
      expect(d.daysLeft, -2);
      expect(d.isOverdue, isTrue);
    });
  });

  group('nextOccurrence', () {
    test('a passed one-off deadline stays in the past', () {
      // Visa run does not roll forward on its own — the user has to act.
      final DateTime past = DateTime.now().subtract(const Duration(days: 10));
      final Deadline d = _deadline(DeadlineKind.visaRun, past);
      expect(d.nextOccurrence.isBefore(DateTime.now()), isTrue);
    });

    test('paušal tax rolls to the next month once the 15th passes', () {
      final DateTime longPast = DateTime(2024, 1, 15);
      final Deadline d = _deadline(DeadlineKind.pausalTax, longPast);
      final DateTime next = d.nextOccurrence;

      expect(next.day, 15);
      final DateTime today = DateTime.now();
      expect(
        next.isAfter(DateTime(today.year, today.month, today.day)) ||
            next.isAtSameMomentAs(DateTime(today.year, today.month, today.day)),
        isTrue,
        reason: 'monthly deadline should not stay in the past',
      );
    });

    test('eco tax rolls to the next year', () {
      final Deadline d = _deadline(DeadlineKind.ecoTax, DateTime(2024, 4, 30));
      final DateTime next = d.nextOccurrence;
      expect(next.month, 4);
      expect(next.day, 30);
      expect(next.year, greaterThanOrEqualTo(DateTime.now().year));
    });

    test('a future deadline is returned unchanged', () {
      final DateTime future = DateTime.now().add(const Duration(days: 20));
      final Deadline d = _deadline(DeadlineKind.residencePermit, future);
      expect(d.nextOccurrence, future);
    });
  });

  group('kind metadata', () {
    test('every kind has lead days ordered most-distant first', () {
      for (final DeadlineKind kind in DeadlineKind.values) {
        final List<int> leads = kind.defaultLeadDays;
        expect(leads, isNotEmpty, reason: '${kind.name} has no lead days');
        for (int i = 1; i < leads.length; i++) {
          expect(leads[i], lessThan(leads[i - 1]),
              reason: '${kind.name} lead days are not descending');
        }
      }
    });

    test('only paušal repeats monthly and only eco tax yearly', () {
      expect(DeadlineKind.pausalTax.repeatsMonthly, isTrue);
      expect(DeadlineKind.ecoTax.repeatsYearly, isTrue);
      expect(DeadlineKind.visaRun.repeatsMonthly, isFalse);
      expect(DeadlineKind.visaRun.repeatsYearly, isFalse);
    });
  });

  group('json round-trip', () {
    test('survives serialisation', () {
      final Deadline original = Deadline(
        id: 'abc',
        kind: DeadlineKind.documentExpiry,
        date: DateTime(2027, 3, 4),
        customTitle: 'ID card',
        enabled: false,
      );
      final Deadline? restored = Deadline.fromJson(original.toJson());

      expect(restored, isNotNull);
      expect(restored!.id, original.id);
      expect(restored.kind, original.kind);
      expect(restored.date, original.date);
      expect(restored.customTitle, original.customTitle);
      expect(restored.enabled, isFalse);
    });

    test('rejects a record with an unparseable date', () {
      expect(
        Deadline.fromJson(<String, dynamic>{'id': 'x', 'date': 'nonsense'}),
        isNull,
      );
    });

    test('falls back to custom for an unknown kind', () {
      final Deadline? d = Deadline.fromJson(<String, dynamic>{
        'id': 'x',
        'kind': 'something_removed_in_a_later_version',
        'date': '2027-01-01T00:00:00.000',
      });
      expect(d, isNotNull);
      expect(d!.kind, DeadlineKind.custom);
    });
  });
}
