import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:srbguide/data/deadline.dart';

/// Stores the user's deadlines and keeps them sorted by urgency.
class DeadlineRepository {
  DeadlineRepository._();

  static final DeadlineRepository instance = DeadlineRepository._();

  static const String _key = 'deadlines';

  Future<List<Deadline>> load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return <Deadline>[];

    try {
      final List<dynamic> decoded = json.decode(raw) as List<dynamic>;
      final List<Deadline> items = decoded
          .cast<Map<String, dynamic>>()
          .map(Deadline.fromJson)
          .whereType<Deadline>()
          .toList();
      _sort(items);
      return items;
    } catch (_) {
      return <Deadline>[];
    }
  }

  Future<void> save(List<Deadline> deadlines) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      json.encode(deadlines.map((Deadline d) => d.toJson()).toList()),
    );
  }

  Future<List<Deadline>> upsert(Deadline deadline) async {
    final List<Deadline> items = await load();
    final int i = items.indexWhere((Deadline d) => d.id == deadline.id);
    if (i == -1) {
      items.add(deadline);
    } else {
      items[i] = deadline;
    }
    _sort(items);
    await save(items);
    return items;
  }

  Future<List<Deadline>> remove(String id) async {
    final List<Deadline> items = await load();
    items.removeWhere((Deadline d) => d.id == id);
    await save(items);
    return items;
  }

  /// Soonest first; overdue one-off deadlines float to the top because they
  /// are the ones that need action.
  void _sort(List<Deadline> items) {
    items.sort((Deadline a, Deadline b) =>
        a.nextOccurrence.compareTo(b.nextOccurrence));
  }

  /// Used by the home screen to show the single most urgent item.
  Future<Deadline?> next() async {
    final List<Deadline> items = await load();
    for (final Deadline d in items) {
      if (d.enabled) return d;
    }
    return null;
  }
}
