import 'dart:convert';

import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:srbguide/data/deadline.dart';
import 'package:srbguide/data/deadline_repository.dart';
import 'package:srbguide/data/visa_rule.dart';
import 'package:srbguide/localization/app_localizations.dart';
import 'package:srbguide/service/notification_service.dart';
import 'package:srbguide/theme/app_theme.dart';

/// Visa-free stay calculator.
///
/// The screen keeps a *list* of trips rather than one entry date, because that
/// is what the rules actually need: a rolling 90-in-180 window counts every day
/// spent in the country over the last half year, so a single date cannot
/// answer it. [calculateVisaStatus] owns the arithmetic; this file is storage
/// and presentation only.
class VisaFreeCalculatorScreen extends StatefulWidget {
  const VisaFreeCalculatorScreen({super.key});

  @override
  State<VisaFreeCalculatorScreen> createState() =>
      _VisaFreeCalculatorScreenState();
}

class _VisaFreeCalculatorScreenState extends State<VisaFreeCalculatorScreen> {
  static const String _ruleKey = 'visa_rule';
  static const String _staysKey = 'visa_stays';

  /// Key written by the earlier version of this screen, which stored a single
  /// exit date. Read once so nobody loses the date they had entered.
  static const String _legacyExitKey = 'exitDate';

  SharedPreferences? _prefs;
  VisaRule _rule = VisaRule.perEntry30;
  List<Stay> _stays = <Stay>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final VisaRule rule = VisaRule.fromName(prefs.getString(_ruleKey));
    List<Stay> stays = _decodeStays(prefs.getString(_staysKey));

    // The old screen saved the exit day, which it set 29 days after entry, so
    // the entry date it came from can be recovered exactly.
    if (stays.isEmpty && prefs.getString(_staysKey) == null) {
      final String? legacy = prefs.getString(_legacyExitKey);
      final DateTime? exit = legacy == null ? null : DateTime.tryParse(legacy);
      if (exit != null) stays = <Stay>[Stay(entry: addDays(exit, -29))];
    }

    if (!mounted) return;
    setState(() {
      _prefs = prefs;
      _rule = rule;
      _stays = stays..sort(_newestFirst);
      _loading = false;
    });
  }

  static int _newestFirst(Stay a, Stay b) => b.entry.compareTo(a.entry);

  List<Stay> _decodeStays(String? raw) {
    if (raw == null || raw.isEmpty) return <Stay>[];
    try {
      final List<dynamic> list = json.decode(raw) as List<dynamic>;
      return list
          .map((dynamic e) => Stay.fromJson(e as Map<String, dynamic>))
          .whereType<Stay>()
          .toList();
    } catch (_) {
      return <Stay>[];
    }
  }

  Future<void> _persist() async {
    final SharedPreferences? prefs = _prefs;
    if (prefs == null) return;
    await prefs.setString(_ruleKey, _rule.name);
    await prefs.setString(
      _staysKey,
      json.encode(_stays.map((Stay s) => s.toJson()).toList()),
    );
  }

  Future<void> _selectRule(VisaRule rule) async {
    setState(() => _rule = rule);
    await _persist();
  }

  Future<void> _editStay({int? index}) async {
    final Stay? result = await showModalBottomSheet<Stay>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext ctx) =>
          _StayEditor(existing: index == null ? null : _stays[index]),
    );
    if (result == null) return;
    setState(() {
      if (index == null) {
        _stays.add(result);
      } else {
        _stays[index] = result;
      }
      _stays.sort(_newestFirst);
    });
    await _persist();
  }

  Future<void> _deleteStay(int index) async {
    setState(() => _stays.removeAt(index));
    await _persist();
  }

  /// Turns the deadline into a real reminder, reusing the deadlines feature so
  /// there is one list of dates in the app rather than two.
  Future<void> _createReminder(DateTime mustLeaveBy) async {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    if (!await NotificationService.instance.hasPermission()) {
      await NotificationService.instance.requestPermission();
    }

    // A fixed id means tapping this again moves the existing reminder instead
    // of stacking up a new one for every recalculation.
    final List<Deadline> items = await DeadlineRepository.instance.upsert(
      Deadline(
        id: 'visa-run',
        kind: DeadlineKind.visaRun,
        date: localDay(mustLeaveBy),
      ),
    );
    await NotificationService.instance.reschedule(
      items,
      title: (Deadline d) => d.customTitle?.isNotEmpty == true
          ? d.customTitle!
          : l10n.translate(d.kind.titleKey),
      body: (Deadline d, int daysBefore) => daysBefore == 0
          ? l10n.translate('reminder_body_today')
          : l10n
              .translate('reminder_body_before')
              .replaceFirst('%d', '$daysBefore'),
    );

    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.translate('reminder_created'))),
    );
  }

  void _addToCalendar(DateTime mustLeaveBy) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final DateTime day = localDay(mustLeaveBy);
    Add2Calendar.addEvent2Cal(
      Event(
        title: l10n.translate('visarun'),
        description: l10n.translate('need_make_visa_run_by'),
        startDate: day,
        endDate: day,
        allDay: true,
      ),
    );
  }

  void _showRules() {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              l10n.translate('how_days_counted'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.translate('how_days_counted_body'),
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: Theme.of(ctx).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final VisaStatus status = calculateVisaStatus(
      rule: _rule,
      stays: _stays,
      today: DateTime.now(),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('calculator_visarun')),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: l10n.translate('how_days_counted'),
            onPressed: _showRules,
          ),
        ],
      ),
      // While there is nothing to show, the empty state carries the only call
      // to action; a FAB saying the same thing next to it is just noise.
      floatingActionButton: _loading || _stays.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _editStay(),
              icon: const Icon(Icons.add),
              label: Text(l10n.translate('add_stay')),
            ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              children: <Widget>[
                _StatusCard(
                  status: status,
                  rule: _rule,
                  hasStays: _stays.isNotEmpty,
                  onAdd: () => _editStay(),
                ),
                if (status.mustLeaveBy != null) ...<Widget>[
                  const SizedBox(height: 10),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: () => _createReminder(status.mustLeaveBy!),
                          icon: const Icon(Icons.notifications_active_outlined,
                              size: 19),
                          label: Text(l10n.translate('remind_me')),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _addToCalendar(status.mustLeaveBy!),
                          icon: const Icon(Icons.event_outlined, size: 19),
                          label: Text(l10n.translate('add_to_calendar')),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 22),
                _SectionLabel(l10n.translate('visa_rule_section')),
                const SizedBox(height: 8),
                ...VisaRule.values.map(
                  (VisaRule rule) => _RuleTile(
                    rule: rule,
                    selected: rule == _rule,
                    onTap: () => _selectRule(rule),
                  ),
                ),
                const SizedBox(height: 22),
                _SectionLabel(l10n.translate('stays_title')),
                const SizedBox(height: 8),
                if (_stays.isEmpty)
                  _Hint(l10n.translate('stays_empty'))
                else
                  ...List<Widget>.generate(
                    _stays.length,
                    (int i) => _StayTile(
                      stay: _stays[i],
                      onTap: () => _editStay(index: i),
                      onDelete: () => _deleteStay(i),
                    ),
                  ),
                const SizedBox(height: 18),
                Text(
                  l10n.translate('calc_disclaimer'),
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
    );
  }
}

/// The headline answer: how much time is left, and until when.
class _StatusCard extends StatelessWidget {
  final VisaStatus status;
  final VisaRule rule;
  final bool hasStays;
  final VoidCallback onAdd;

  const _StatusCard({
    required this.status,
    required this.rule,
    required this.hasStays,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final ColorScheme scheme = Theme.of(context).colorScheme;

    if (!hasStays) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 26, 20, 22),
          child: Column(
            children: <Widget>[
              Icon(Icons.flight_takeoff,
                  size: 40, color: scheme.onSurfaceVariant),
              const SizedBox(height: 14),
              Text(
                l10n.translate('select_entry_date_serbia'),
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: onAdd,
                child: Text(l10n.translate('add_stay')),
              ),
            ],
          ),
        ),
      );
    }

    final bool overstay = status.isOverstay;
    final bool urgent = !overstay && status.daysLeft <= 7;
    final Color accent = overstay
        ? scheme.error
        : urgent
            ? AppTheme.warningOf(context)
            : scheme.primary;
    final double progress =
        (status.daysUsed / rule.allowanceDays).clamp(0.0, 1.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
        child: Column(
          children: <Widget>[
            SizedBox(
              width: 148,
              height: 148,
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: overstay ? 1 : progress,
                      strokeWidth: 11,
                      strokeCap: StrokeCap.round,
                      backgroundColor: scheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(accent),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        '${status.daysLeft}',
                        style: TextStyle(
                          fontSize: 46,
                          height: 1,
                          fontWeight: FontWeight.w700,
                          color: accent,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.translate('days_left_label'),
                        style: TextStyle(
                          fontSize: 12.5,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n
                  .translate('days_used_of')
                  .replaceFirst('%1', '${status.daysUsed}')
                  .replaceFirst('%2', '${rule.allowanceDays}'),
              style: TextStyle(fontSize: 13.5, color: scheme.onSurfaceVariant),
            ),
            if (status.mustLeaveBy != null) ...<Widget>[
              const SizedBox(height: 14),
              Divider(color: scheme.outlineVariant, height: 1),
              const SizedBox(height: 14),
              Text(
                l10n.translate('leave_serbia_by'),
                style:
                    TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 3),
              Text(
                DateFormat('d MMMM y',
                        Localizations.localeOf(context).languageCode)
                    .format(status.mustLeaveBy!),
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
            ],
            if (overstay) ...<Widget>[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: scheme.errorContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: <Widget>[
                    Icon(Icons.warning_amber_rounded,
                        size: 20, color: scheme.onErrorContainer),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.translate('overstay_body'),
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.35,
                          color: scheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// One of the three visa-free regimes, with the countries it covers.
class _RuleTile extends StatelessWidget {
  final VisaRule rule;
  final bool selected;
  final VoidCallback onTap;

  const _RuleTile({
    required this.rule,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? scheme.primaryContainer : scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              // The country list runs to three lines; a centred radio would
              // float against the middle of it.
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    size: 20,
                    color: selected ? scheme.primary : scheme.outline,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        l10n.translate(rule.titleKey),
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.translate(rule.countriesKey),
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.3,
                          color: selected
                              ? scheme.onPrimaryContainer
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One recorded trip. Swipe to delete, as on the deadlines screen.
class _StayTile extends StatelessWidget {
  final Stay stay;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _StayTile({
    required this.stay,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final String locale = Localizations.localeOf(context).languageCode;
    final DateFormat format = DateFormat('d MMM y', locale);
    final int length =
        daysBetween(stay.entry, stay.exit ?? dateOnly(DateTime.now())) + 1;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: ValueKey<String>('${stay.entry}-${stay.exit}'),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => onDelete(),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: scheme.errorContainer,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(Icons.delete_outline, color: scheme.onErrorContainer),
        ),
        child: Card(
          margin: EdgeInsets.zero,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      stay.isOpen ? Icons.place_outlined : Icons.check,
                      size: 20,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          stay.isOpen
                              ? '${format.format(stay.entry)} → ${l10n.translate('still_in_country')}'
                              : '${format.format(stay.entry)} → ${format.format(stay.exit!)}',
                          style: const TextStyle(
                              fontSize: 14.5, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$length ${l10n.translate('days_left_short')}',
                          style: TextStyle(
                              fontSize: 12.5, color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: scheme.outline),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Entry and exit dates for one trip.
class _StayEditor extends StatefulWidget {
  final Stay? existing;

  const _StayEditor({this.existing});

  @override
  State<_StayEditor> createState() => _StayEditorState();
}

class _StayEditorState extends State<_StayEditor> {
  late DateTime _entry = widget.existing?.entry ?? dateOnly(DateTime.now());
  late DateTime? _exit = widget.existing?.exit;
  late bool _stillHere = widget.existing?.isOpen ?? true;

  Future<void> _pick({required bool isEntry}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: localDay(isEntry ? _entry : _exit ?? _entry),
      firstDate: DateTime(2015),
      lastDate: DateTime(DateTime.now().year + 5),
    );
    if (picked == null) return;
    setState(() {
      if (isEntry) {
        _entry = dateOnly(picked);
        // An exit before the entry is never what the user meant.
        if (_exit != null && _exit!.isBefore(_entry)) _exit = _entry;
      } else {
        _exit = dateOnly(picked).isBefore(_entry) ? _entry : dateOnly(picked);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final String locale = Localizations.localeOf(context).languageCode;
    final DateFormat format = DateFormat('d MMMM y', locale);

    // Everything here sizes to its own content. The sheet measures its child
    // with an unbounded width before laying it out, which anything relying on
    // `Expanded` inside a `Row` cannot survive.
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 28,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              l10n.translate(
                  widget.existing == null ? 'add_stay' : 'edit_stay'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            _DateField(
              label: l10n.translate('entry_date'),
              value: format.format(_entry),
              onTap: () => _pick(isEntry: true),
            ),
            const SizedBox(height: 4),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                l10n.translate('still_in_country'),
                style: const TextStyle(fontSize: 15),
              ),
              value: _stillHere,
              onChanged: (bool v) => setState(() {
                _stillHere = v;
                if (!v) _exit ??= dateOnly(DateTime.now());
              }),
            ),
            if (!_stillHere) ...<Widget>[
              const SizedBox(height: 8),
              _DateField(
                label: l10n.translate('exit_date'),
                value: format.format(_exit ?? _entry),
                onTap: () => _pick(isEntry: false),
              ),
            ],
            const SizedBox(height: 24),
            // Both buttons are Expanded because the app's button theme asks
            // for a full-width minimum size, and a Row hands its children an
            // unbounded width — the two together assert.
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.translate('cancel')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(
                      context,
                      Stay(
                        entry: _entry,
                        exit: _stillHere ? null : (_exit ?? _entry),
                      ),
                    ),
                    child: Text(l10n.translate('save')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A labelled date button.
class _DateField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 6),
        OutlinedButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.calendar_today_outlined, size: 17),
          label: Text(value),
          style: OutlinedButton.styleFrom(foregroundColor: scheme.onSurface),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.9,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
}

class _Hint extends StatelessWidget {
  final String text;

  const _Hint(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13.5,
            height: 1.4,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
}
