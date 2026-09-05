import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:srbguide/data/deadline.dart';
import 'package:srbguide/data/deadline_repository.dart';
import 'package:srbguide/localization/app_localizations.dart';
import 'package:srbguide/service/notification_service.dart';
import 'package:srbguide/widget/guide_tiles.dart';

/// The deadlines a migrant gets fined for missing, with local reminders.
class DeadlinesScreen extends StatefulWidget {
  const DeadlinesScreen({super.key});

  @override
  State<DeadlinesScreen> createState() => _DeadlinesScreenState();
}

class _DeadlinesScreenState extends State<DeadlinesScreen> {
  final DeadlineRepository _repository = DeadlineRepository.instance;

  List<Deadline>? _deadlines;
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final List<Deadline> items = await _repository.load();
    final bool permitted = await NotificationService.instance.hasPermission();
    if (!mounted) return;
    setState(() {
      _deadlines = items;
      _notificationsEnabled = permitted;
    });
  }

  /// Notification text has to be built here, where the localizations live.
  Future<void> _reschedule(List<Deadline> items) async {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    await NotificationService.instance.reschedule(
      items,
      title: (Deadline d) => _titleOf(d, l10n),
      body: (Deadline d, int daysBefore) => daysBefore == 0
          ? l10n.translate('reminder_body_today')
          : l10n
              .translate('reminder_body_before')
              .replaceFirst('%d', '$daysBefore'),
    );
  }

  String _titleOf(Deadline d, AppLocalizations l10n) =>
      d.customTitle?.isNotEmpty == true
          ? d.customTitle!
          : l10n.translate(d.kind.titleKey);

  Future<void> _save(Deadline deadline) async {
    final List<Deadline> items = await _repository.upsert(deadline);
    if (!mounted) return;
    setState(() => _deadlines = items);
    await _reschedule(items);
  }

  Future<void> _delete(Deadline deadline) async {
    final List<Deadline> items = await _repository.remove(deadline.id);
    if (!mounted) return;
    setState(() => _deadlines = items);
    await _reschedule(items);
  }

  Future<void> _requestPermission() async {
    final bool granted = await NotificationService.instance.requestPermission();
    if (!mounted) return;
    setState(() => _notificationsEnabled = granted);
    if (granted && _deadlines != null) await _reschedule(_deadlines!);
  }

  Future<void> _openEditor({Deadline? existing}) async {
    final Deadline? result = await showModalBottomSheet<Deadline>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext ctx) => _DeadlineEditor(existing: existing),
    );
    if (result != null) await _save(result);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final List<Deadline>? items = _deadlines;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.translate('deadlines'))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add),
        label: Text(l10n.translate('add_deadline')),
      ),
      body: items == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: <Widget>[
                if (!_notificationsEnabled)
                  _PermissionBanner(onEnable: _requestPermission),
                Expanded(
                  child: items.isEmpty
                      ? EmptyState(
                          icon: Icons.notifications_none,
                          message: l10n.translate('deadlines_empty'),
                          action: FilledButton.tonal(
                            onPressed: () => _openEditor(),
                            child: Text(l10n.translate('add_deadline')),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                          itemCount: items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (BuildContext context, int i) =>
                              _DeadlineCard(
                            deadline: items[i],
                            title: _titleOf(items[i], l10n),
                            onTap: () => _openEditor(existing: items[i]),
                            onToggle: (bool v) =>
                                _save(items[i].copyWith(enabled: v)),
                            onDelete: () => _delete(items[i]),
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}

class _PermissionBanner extends StatelessWidget {
  final VoidCallback onEnable;

  const _PermissionBanner({required this.onEnable});

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.notifications_off_outlined,
              size: 20, color: scheme.onErrorContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.translate('notifications_disabled'),
              style: TextStyle(fontSize: 13, color: scheme.onErrorContainer),
            ),
          ),
          TextButton(
            onPressed: onEnable,
            child: Text(l10n.translate('enable_notifications')),
          ),
        ],
      ),
    );
  }
}

class _DeadlineCard extends StatelessWidget {
  final Deadline deadline;
  final String title;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  const _DeadlineCard({
    required this.deadline,
    required this.title,
    required this.onTap,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final DateTime target = deadline.nextOccurrence;
    final int days = DateTime(target.year, target.month, target.day)
        .difference(DateTime(
            DateTime.now().year, DateTime.now().month, DateTime.now().day))
        .inDays;

    final bool urgent = days <= 3;
    final String counter = days < 0
        ? l10n.translate('overdue')
        : days == 0
            ? l10n.translate('today')
            : days == 1
                ? l10n.translate('tomorrow')
                : '$days ${l10n.translate('days_left_short')}';

    return Dismissible(
      key: ValueKey<String>(deadline.id),
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
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
            child: Row(
              children: <Widget>[
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: urgent && deadline.enabled
                        ? scheme.errorContainer
                        : scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    deadline.kind.icon,
                    size: 21,
                    color: urgent && deadline.enabled
                        ? scheme.onErrorContainer
                        : scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${DateFormat('d MMMM y', Localizations.localeOf(context).languageCode).format(target)} · $counter',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: urgent && deadline.enabled
                              ? scheme.error
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(value: deadline.enabled, onChanged: onToggle),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DeadlineEditor extends StatefulWidget {
  final Deadline? existing;

  const _DeadlineEditor({this.existing});

  @override
  State<_DeadlineEditor> createState() => _DeadlineEditorState();
}

class _DeadlineEditorState extends State<_DeadlineEditor> {
  late DeadlineKind _kind = widget.existing?.kind ?? DeadlineKind.visaRun;
  late DateTime _date =
      widget.existing?.date ?? _defaultDateFor(DeadlineKind.visaRun);
  late final TextEditingController _title =
      TextEditingController(text: widget.existing?.customTitle ?? '');

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  /// Pre-fills the date from what the obligation actually is, so most
  /// deadlines need no date entry at all.
  static DateTime _defaultDateFor(DeadlineKind kind) {
    final DateTime now = DateTime.now();
    switch (kind) {
      case DeadlineKind.visaRun:
        return now.add(const Duration(days: 29));
      case DeadlineKind.pausalTax:
        final DateTime this15 = DateTime(now.year, now.month, 15);
        return this15.isBefore(now)
            ? DateTime(now.year, now.month + 1, 15)
            : this15;
      case DeadlineKind.ecoTax:
        final DateTime apr30 = DateTime(now.year, 4, 30);
        return apr30.isBefore(now) ? DateTime(now.year + 1, 4, 30) : apr30;
      case DeadlineKind.residencePermit:
        return DateTime(now.year + 1, now.month, now.day);
      case DeadlineKind.insurance:
      case DeadlineKind.documentExpiry:
      case DeadlineKind.custom:
        return now.add(const Duration(days: 30));
    }
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime(DateTime.now().year + 10),
    );
    if (picked != null && mounted) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final String locale = Localizations.localeOf(context).languageCode;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              l10n.translate(
                  widget.existing == null ? 'add_deadline' : 'edit_deadline'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            Text(l10n.translate('deadline_kind'),
                style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: DeadlineKind.values.map((DeadlineKind k) {
                return ChoiceChip(
                  avatar: Icon(k.icon, size: 17),
                  label: Text(l10n.translate(k.titleKey),
                      style: const TextStyle(fontSize: 12.5)),
                  selected: _kind == k,
                  onSelected: (_) => setState(() {
                    _kind = k;
                    if (widget.existing == null) _date = _defaultDateFor(k);
                  }),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            if (_kind == DeadlineKind.custom ||
                _kind == DeadlineKind.documentExpiry) ...<Widget>[
              TextField(
                controller: _title,
                decoration: InputDecoration(
                  labelText: l10n.translate('deadline_title'),
                ),
              ),
              const SizedBox(height: 16),
            ],
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today, size: 18),
              label: Text(DateFormat('d MMMM y', locale).format(_date)),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(
                Deadline(
                  id: widget.existing?.id ??
                      DateTime.now().microsecondsSinceEpoch.toString(),
                  kind: _kind,
                  date: _date,
                  customTitle:
                      _title.text.trim().isEmpty ? null : _title.text.trim(),
                  enabled: widget.existing?.enabled ?? true,
                ),
              ),
              child: Text(l10n.translate('save')),
            ),
          ],
        ),
      ),
    );
  }
}
