/// Visa-free stay rules for Serbia, and the arithmetic behind them.
///
/// The rules come from the guide's own calculator article
/// (srb.guide/guides/personal/visa-calculator). Two things it settles that are
/// easy to get wrong:
///
///  * **Both the entry day and the exit day count.** Enter on 1 January, leave
///    on 2 January, and that is two days of stay.
///  * Not everyone is on the same rule. Russia, Belarus, China and Kazakhstan
///    get 30 days *per entry* with no rolling window, which is what makes a
///    visa run work for them. Most other visa-free nationalities are on a
///    90-in-180 rolling window, where leaving and returning resets nothing.
library;

/// Which visa-free regime applies to a traveller.
enum VisaRule {
  /// 30 days per entry, no rolling window — Russia, Belarus, China,
  /// Kazakhstan. Leaving and re-entering resets the counter, which is the
  /// whole point of a visa run.
  perEntry30(allowanceDays: 30, windowDays: null),

  /// 90 days within any rolling 180 — EU, USA, Ukraine and most others.
  /// A visa run does **not** reset this.
  rolling90in180(allowanceDays: 90, windowDays: 180),

  /// 30 days within any rolling year — Bahamas, Barbados, Colombia,
  /// Indonesia, Jamaica, Paraguay, St Vincent and the Grenadines.
  rolling30in365(allowanceDays: 30, windowDays: 365);

  const VisaRule({required this.allowanceDays, required this.windowDays});

  /// Days of presence permitted.
  final int allowanceDays;

  /// Length of the rolling window, or null when the allowance is per entry.
  final int? windowDays;

  bool get isPerEntry => windowDays == null;

  /// Localization key for the rule's short name.
  String get titleKey => switch (this) {
        VisaRule.perEntry30 => 'visa_rule_per_entry',
        VisaRule.rolling90in180 => 'visa_rule_90_180',
        VisaRule.rolling30in365 => 'visa_rule_30_365',
      };

  /// Localization key for the countries the rule applies to.
  String get countriesKey => switch (this) {
        VisaRule.perEntry30 => 'visa_rule_per_entry_countries',
        VisaRule.rolling90in180 => 'visa_rule_90_180_countries',
        VisaRule.rolling30in365 => 'visa_rule_30_365_countries',
      };

  static VisaRule fromName(String? name) => VisaRule.values.firstWhere(
        (VisaRule r) => r.name == name,
        orElse: () => VisaRule.perEntry30,
      );
}

/// One period of presence in the country.
///
/// Dates are whole days; the time part is discarded so that a stay entered at
/// 23:00 is not a different length from one entered at 01:00.
class Stay {
  final DateTime entry;

  /// The day of departure, or null while the traveller is still in the country.
  final DateTime? exit;

  Stay({required DateTime entry, DateTime? exit})
      : entry = dateOnly(entry),
        exit = exit == null ? null : dateOnly(exit);

  bool get isOpen => exit == null;

  /// Whether [day] falls inside this stay, counting both endpoints.
  bool covers(DateTime day, {required DateTime openEndsAt}) {
    final DateTime d = dateOnly(day);
    final DateTime end = exit ?? dateOnly(openEndsAt);
    return !d.isBefore(entry) && !d.isAfter(end);
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'entry': entry.toIso8601String(),
        'exit': exit?.toIso8601String(),
      };

  static Stay? fromJson(Map<String, dynamic> json) {
    final DateTime? entry = DateTime.tryParse((json['entry'] ?? '') as String);
    if (entry == null) return null;
    return Stay(
      entry: entry,
      exit: DateTime.tryParse((json['exit'] ?? '') as String),
    );
  }
}

/// The answer the calculator screen renders.
class VisaStatus {
  /// Days of presence already counted against the allowance.
  final int daysUsed;

  /// Days still available, never negative.
  final int daysLeft;

  /// Last day the traveller may lawfully be in the country, or null when no
  /// stay has been entered yet.
  final DateTime? mustLeaveBy;

  /// True once the allowance is exhausted and the traveller is still present.
  final bool isOverstay;

  const VisaStatus({
    required this.daysUsed,
    required this.daysLeft,
    required this.mustLeaveBy,
    required this.isOverstay,
  });

  static const VisaStatus empty = VisaStatus(
    daysUsed: 0,
    daysLeft: 0,
    mustLeaveBy: null,
    isOverstay: false,
  );
}

/// Strips the time component so day arithmetic is not thrown off by clock time.
///
/// Deliberately returns a **UTC** date. Serbia moves its clocks twice a year,
/// and `Duration(days: 1)` is exactly 24 hours — so adding days to a local
/// DateTime across the last Sunday in March shifts the wall clock by an hour
/// and can drop a whole day from a difference. Anchoring every calculation to
/// UTC midnight removes the problem; nothing here is a real instant in time,
/// only a calendar day.
DateTime dateOnly(DateTime d) => DateTime.utc(d.year, d.month, d.day);

/// [d] shifted by [days] calendar days, DST-safe by construction.
DateTime addDays(DateTime d, int days) {
  final DateTime base = dateOnly(d);
  return DateTime.utc(base.year, base.month, base.day + days);
}

/// The same calendar day in the device's own time zone, at midnight.
///
/// Calendar days here are UTC-anchored, but anything leaving this file for the
/// platform — a calendar event, a scheduled notification — has to be a real
/// local instant.
DateTime localDay(DateTime d) => DateTime(d.year, d.month, d.day);

/// Whole days from [a] to [b], both dates inclusive of their own day.
int daysBetween(DateTime a, DateTime b) =>
    dateOnly(b).difference(dateOnly(a)).inDays;

/// Works out how much visa-free time is left.
///
/// The previous implementation subtracted two `DateTime`s and read `.inDays`,
/// which truncates: at 10:00 on the day before the deadline it reported zero
/// days left when there were still two. Everything here is calendar-day
/// arithmetic.
VisaStatus calculateVisaStatus({
  required VisaRule rule,
  required List<Stay> stays,
  required DateTime today,
}) {
  if (stays.isEmpty) return VisaStatus.empty;
  final DateTime now = dateOnly(today);

  if (rule.isPerEntry) {
    // Only the current entry matters — an earlier trip has no bearing.
    final Stay latest = stays.reduce(
      (Stay a, Stay b) => b.entry.isAfter(a.entry) ? b : a,
    );
    final DateTime lastLawful = addDays(latest.entry, rule.allowanceDays - 1);

    // Before the trip starts nothing has been used yet.
    if (now.isBefore(latest.entry)) {
      return VisaStatus(
        daysUsed: 0,
        daysLeft: rule.allowanceDays,
        mustLeaveBy: lastLawful,
        isOverstay: false,
      );
    }

    final DateTime countedTo = now.isAfter(lastLawful) ? lastLawful : now;
    final int used = daysBetween(latest.entry, countedTo) + 1;
    final int left = daysBetween(now, lastLawful) + 1;

    return VisaStatus(
      daysUsed: used,
      daysLeft: left < 0 ? 0 : left,
      mustLeaveBy: lastLawful,
      isOverstay: now.isAfter(lastLawful),
    );
  }

  final int window = rule.windowDays!;

  /// Days of presence inside the window ending on [ref], assuming any open
  /// stay runs through [presentUntil].
  int usedAt(DateTime ref, DateTime presentUntil) {
    final DateTime from = addDays(ref, -(window - 1));
    int count = 0;
    for (int i = 0; i < window; i++) {
      final DateTime day = addDays(from, i);
      if (day.isAfter(ref)) break;
      for (final Stay s in stays) {
        if (s.covers(day, openEndsAt: presentUntil)) {
          count++;
          break;
        }
      }
    }
    return count;
  }

  final int used = usedAt(now, now);
  final int left = rule.allowanceDays - used;

  // How long presence can continue from today before the window overflows.
  DateTime? lastLawful;
  final bool presentToday = stays.any(
    (Stay s) => s.covers(now, openEndsAt: now),
  );
  if (presentToday || left > 0) {
    DateTime probe = now;
    for (int i = 0; i <= window; i++) {
      final DateTime candidate = addDays(now, i);
      if (usedAt(candidate, candidate) > rule.allowanceDays) break;
      probe = candidate;
    }
    lastLawful = probe;
  }

  return VisaStatus(
    daysUsed: used,
    daysLeft: left < 0 ? 0 : left,
    mustLeaveBy: lastLawful,
    isOverstay: used > rule.allowanceDays,
  );
}
