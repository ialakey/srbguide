import 'package:flutter_test/flutter_test.dart';
import 'package:srbguide/data/visa_rule.dart';

// Calendar days are anchored to UTC midnight — see dateOnly().
DateTime d(int y, int m, int day) => DateTime.utc(y, m, day);

void main() {
  group('per-entry 30 days', () {
    const VisaRule rule = VisaRule.perEntry30;

    test('entry day counts, so 1 Jan gives a deadline of 30 Jan', () {
      // The guide is explicit: enter 1 Jan, leave 2 Jan = two days of stay.
      final VisaStatus s = calculateVisaStatus(
        rule: rule,
        stays: <Stay>[Stay(entry: d(2026, 1, 1))],
        today: d(2026, 1, 1),
      );
      expect(s.mustLeaveBy, d(2026, 1, 30));
      expect(s.daysUsed, 1);
      expect(s.daysLeft, 30);
      expect(s.isOverstay, isFalse);
    });

    test('the old truncation bug: two days left is not reported as zero', () {
      // Subtracting DateTimes and reading .inDays used to return 0 here.
      final VisaStatus s = calculateVisaStatus(
        rule: rule,
        stays: <Stay>[Stay(entry: d(2026, 1, 1))],
        today: DateTime(2026, 1, 29, 10),
      );
      expect(s.daysLeft, 2, reason: '29th and 30th are both still available');
      expect(s.isOverstay, isFalse);
    });

    test('the last lawful day still counts as one day left', () {
      final VisaStatus s = calculateVisaStatus(
        rule: rule,
        stays: <Stay>[Stay(entry: d(2026, 1, 1))],
        today: DateTime(2026, 1, 30, 23),
      );
      expect(s.daysLeft, 1);
      expect(s.daysUsed, 30);
      expect(s.isOverstay, isFalse);
    });

    test('the day after the deadline is an overstay', () {
      final VisaStatus s = calculateVisaStatus(
        rule: rule,
        stays: <Stay>[Stay(entry: d(2026, 1, 1))],
        today: d(2026, 1, 31),
      );
      expect(s.daysLeft, 0);
      expect(s.isOverstay, isTrue);
    });

    test('a visa run resets the counter', () {
      // Leaving and re-entering starts a fresh 30 days for these countries.
      final VisaStatus s = calculateVisaStatus(
        rule: rule,
        stays: <Stay>[
          Stay(entry: d(2026, 1, 1), exit: d(2026, 1, 30)),
          Stay(entry: d(2026, 1, 30)),
        ],
        today: d(2026, 2, 1),
      );
      expect(s.mustLeaveBy, d(2026, 2, 28));
      expect(s.isOverstay, isFalse);
    });

    test('a future entry has not consumed anything yet', () {
      final VisaStatus s = calculateVisaStatus(
        rule: rule,
        stays: <Stay>[Stay(entry: d(2026, 3, 1))],
        today: d(2026, 2, 20),
      );
      expect(s.daysUsed, 0);
      expect(s.daysLeft, 30);
    });
  });

  group('rolling 90 in 180', () {
    const VisaRule rule = VisaRule.rolling90in180;

    test('a fresh arrival gets the full allowance', () {
      final VisaStatus s = calculateVisaStatus(
        rule: rule,
        stays: <Stay>[Stay(entry: d(2026, 1, 1))],
        today: d(2026, 1, 1),
      );
      expect(s.daysUsed, 1);
      expect(s.daysLeft, 89);
      expect(s.mustLeaveBy, d(2026, 3, 31), reason: '90 days counting 1 Jan');
    });

    test('an earlier trip eats into the allowance', () {
      final VisaStatus s = calculateVisaStatus(
        rule: rule,
        stays: <Stay>[
          // 30 days in January, both endpoints counted.
          Stay(entry: d(2026, 1, 1), exit: d(2026, 1, 30)),
          Stay(entry: d(2026, 2, 1)),
        ],
        today: d(2026, 2, 1),
      );
      expect(s.daysUsed, 31, reason: '30 in January plus 1 February');
      expect(s.daysLeft, 59);
    });

    test('leaving and returning does not reset a rolling window', () {
      final VisaStatus withRun = calculateVisaStatus(
        rule: rule,
        stays: <Stay>[
          Stay(entry: d(2026, 1, 1), exit: d(2026, 3, 1)),
          Stay(entry: d(2026, 3, 2)),
        ],
        today: d(2026, 3, 2),
      );
      // 60 days in the first stay + 1 today; a visa run buys nothing here.
      expect(withRun.daysUsed, 61);
      expect(withRun.daysLeft, 29);
    });

    test('days roll out of the window as it moves', () {
      // A stay long past drops out of a 180-day window entirely.
      final VisaStatus s = calculateVisaStatus(
        rule: rule,
        stays: <Stay>[Stay(entry: d(2025, 1, 1), exit: d(2025, 1, 30))],
        today: d(2026, 1, 1),
      );
      expect(s.daysUsed, 0);
      expect(s.daysLeft, 90);
    });

    test('exceeding the allowance is flagged as an overstay', () {
      final VisaStatus s = calculateVisaStatus(
        rule: rule,
        stays: <Stay>[Stay(entry: d(2026, 1, 1))],
        today: d(2026, 4, 15),
      );
      expect(s.isOverstay, isTrue);
      expect(s.daysLeft, 0);
    });
  });

  group('rolling 30 in 365', () {
    test('uses a one-year window', () {
      final VisaStatus s = calculateVisaStatus(
        rule: VisaRule.rolling30in365,
        stays: <Stay>[Stay(entry: d(2026, 1, 1), exit: d(2026, 1, 20))],
        today: d(2026, 6, 1),
      );
      expect(s.daysUsed, 20, reason: 'still inside the 365-day window');
      expect(s.daysLeft, 10);
    });
  });

  group('edge cases', () {
    test('no stays yields an empty status', () {
      final VisaStatus s = calculateVisaStatus(
        rule: VisaRule.perEntry30,
        stays: const <Stay>[],
        today: d(2026, 1, 1),
      );
      expect(s.daysUsed, 0);
      expect(s.mustLeaveBy, isNull);
    });

    test('time of day never changes the answer', () {
      final List<Stay> stays = <Stay>[Stay(entry: DateTime(2026, 1, 1, 23, 59))];
      final VisaStatus morning = calculateVisaStatus(
        rule: VisaRule.perEntry30,
        stays: stays,
        today: DateTime(2026, 1, 15, 0, 1),
      );
      final VisaStatus evening = calculateVisaStatus(
        rule: VisaRule.perEntry30,
        stays: stays,
        today: DateTime(2026, 1, 15, 23, 59),
      );
      expect(morning.daysLeft, evening.daysLeft);
      expect(morning.daysUsed, evening.daysUsed);
    });

    test('a stay survives a json round-trip', () {
      final Stay original = Stay(entry: d(2026, 1, 1), exit: d(2026, 1, 10));
      final Stay? restored = Stay.fromJson(original.toJson());
      expect(restored, isNotNull);
      expect(restored!.entry, original.entry);
      expect(restored.exit, original.exit);
    });

    test('an open stay round-trips with a null exit', () {
      final Stay? restored = Stay.fromJson(Stay(entry: d(2026, 1, 1)).toJson());
      expect(restored!.isOpen, isTrue);
    });
  });
}
