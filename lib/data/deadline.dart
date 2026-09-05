import 'package:flutter/material.dart';

/// The recurring obligations a migrant in Serbia is fined for missing.
///
/// Each kind carries its own default schedule so the user only has to enter the
/// date that is actually personal to them (entry date, ВНЖ expiry) — the rest
/// is derived.
enum DeadlineKind {
  /// 29 visa-free days from the entry date; the app already computes it, this
  /// turns it into a notification.
  visaRun,

  /// Temporary residence permit expiry. Reminders start 30 days out.
  residencePermit,

  /// Paušal tax — due by the 15th of every month.
  pausalTax,

  /// Eco tax — filed once a year, by 30 April.
  ecoTax,

  /// Private health insurance renewal.
  insurance,

  /// Serbian ID card / driving licence expiry.
  documentExpiry,

  /// Anything else the user wants to be reminded about.
  custom,
}

extension DeadlineKindInfo on DeadlineKind {
  String get id => name;

  IconData get icon {
    switch (this) {
      case DeadlineKind.visaRun:
        return Icons.flight_takeoff;
      case DeadlineKind.residencePermit:
        return Icons.home_outlined;
      case DeadlineKind.pausalTax:
        return Icons.receipt_long_outlined;
      case DeadlineKind.ecoTax:
        return Icons.eco_outlined;
      case DeadlineKind.insurance:
        return Icons.health_and_safety_outlined;
      case DeadlineKind.documentExpiry:
        return Icons.badge_outlined;
      case DeadlineKind.custom:
        return Icons.event_outlined;
    }
  }

  /// Localization key for the human-readable name.
  String get titleKey {
    switch (this) {
      case DeadlineKind.visaRun:
        return 'deadline_visa_run';
      case DeadlineKind.residencePermit:
        return 'deadline_residence';
      case DeadlineKind.pausalTax:
        return 'deadline_pausal';
      case DeadlineKind.ecoTax:
        return 'deadline_eco_tax';
      case DeadlineKind.insurance:
        return 'deadline_insurance';
      case DeadlineKind.documentExpiry:
        return 'deadline_document';
      case DeadlineKind.custom:
        return 'deadline_custom';
    }
  }

  /// How many days before the date to warn, most distant first.
  List<int> get defaultLeadDays {
    switch (this) {
      case DeadlineKind.visaRun:
        return <int>[7, 3, 1];
      case DeadlineKind.residencePermit:
        return <int>[30, 14, 3];
      case DeadlineKind.pausalTax:
        return <int>[3, 1];
      case DeadlineKind.ecoTax:
        return <int>[14, 3];
      case DeadlineKind.insurance:
      case DeadlineKind.documentExpiry:
        return <int>[30, 7];
      case DeadlineKind.custom:
        return <int>[7, 1];
    }
  }

  /// Monthly obligations roll forward on their own.
  bool get repeatsMonthly => this == DeadlineKind.pausalTax;

  bool get repeatsYearly => this == DeadlineKind.ecoTax;
}

/// A single date the user wants to be reminded about.
class Deadline {
  final String id;
  final DeadlineKind kind;

  /// Overrides the kind's default name when the user typed their own.
  final String? customTitle;

  final DateTime date;
  final bool enabled;

  const Deadline({
    required this.id,
    required this.kind,
    required this.date,
    this.customTitle,
    this.enabled = true,
  });

  Deadline copyWith({
    DateTime? date,
    bool? enabled,
    String? customTitle,
  }) =>
      Deadline(
        id: id,
        kind: kind,
        date: date ?? this.date,
        customTitle: customTitle ?? this.customTitle,
        enabled: enabled ?? this.enabled,
      );

  int get daysLeft {
    final DateTime today = DateTime.now();
    final DateTime a = DateTime(today.year, today.month, today.day);
    final DateTime b = DateTime(date.year, date.month, date.day);
    return b.difference(a).inDays;
  }

  bool get isOverdue => daysLeft < 0;

  /// The next occurrence for recurring kinds, or [date] for one-off ones.
  DateTime get nextOccurrence {
    if (!isOverdue) return date;
    if (kind.repeatsMonthly) {
      final DateTime now = DateTime.now();
      DateTime next = DateTime(now.year, now.month, date.day);
      if (next.isBefore(DateTime(now.year, now.month, now.day))) {
        next = DateTime(now.year, now.month + 1, date.day);
      }
      return next;
    }
    if (kind.repeatsYearly) {
      final DateTime now = DateTime.now();
      DateTime next = DateTime(now.year, date.month, date.day);
      if (next.isBefore(DateTime(now.year, now.month, now.day))) {
        next = DateTime(now.year + 1, date.month, date.day);
      }
      return next;
    }
    return date;
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'kind': kind.id,
        'customTitle': customTitle,
        'date': date.toIso8601String(),
        'enabled': enabled,
      };

  static Deadline? fromJson(Map<String, dynamic> json) {
    final DateTime? date = DateTime.tryParse((json['date'] ?? '') as String);
    if (date == null) return null;
    return Deadline(
      id: (json['id'] ?? '') as String,
      kind: DeadlineKind.values.firstWhere(
        (DeadlineKind k) => k.id == json['kind'],
        orElse: () => DeadlineKind.custom,
      ),
      customTitle: json['customTitle'] as String?,
      date: date,
      enabled: (json['enabled'] ?? true) as bool,
    );
  }
}
