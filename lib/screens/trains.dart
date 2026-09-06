import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:srbguide/data/train.dart';
import 'package:srbguide/localization/app_localizations.dart';
import 'package:srbguide/service/srbijavoz_service.dart';
import 'package:srbguide/widget/guide_tiles.dart';

/// Serbian Railways timetable: route search and a per-station board.
class TrainsScreen extends StatefulWidget {
  const TrainsScreen({super.key});

  @override
  State<TrainsScreen> createState() => _TrainsScreenState();
}

class _TrainsScreenState extends State<TrainsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('trains')),
        bottom: TabBar(
          controller: _tabs,
          tabs: <Widget>[
            Tab(text: l10n.translate('trains_route')),
            Tab(text: l10n.translate('trains_board')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const <Widget>[_RouteTab(), _BoardTab()],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Route search
// ---------------------------------------------------------------------------

class _RouteTab extends StatefulWidget {
  const _RouteTab();

  @override
  State<_RouteTab> createState() => _RouteTabState();
}

class _RouteTabState extends State<_RouteTab>
    with AutomaticKeepAliveClientMixin {
  final SrbijavozService _service = SrbijavozService.instance;

  TrainStation? _from;
  TrainStation? _to;
  DateTime _date = DateTime.now();
  List<TrainConnection>? _results;
  bool _loading = false;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  Future<void> _search() async {
    final TrainStation? from = _from;
    final TrainStation? to = _to;
    if (from == null || to == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final List<TrainConnection> runs = await _service.connections(
        from: from,
        to: to,
        date: _date,
      );
      await _service.rememberStation(from);
      await _service.rememberStation(to);
      if (!mounted) return;
      setState(() {
        _results = runs;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool ready = _from != null && _to != null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: <Widget>[
        _StationField(
          label: l10n.translate('station_from'),
          station: _from,
          onPicked: (TrainStation s) => setState(() => _from = s),
        ),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            Expanded(
              child: _StationField(
                label: l10n.translate('station_to'),
                station: _to,
                onPicked: (TrainStation s) => setState(() => _to = s),
              ),
            ),
            IconButton(
              tooltip: l10n.translate('swap'),
              icon: const Icon(Icons.swap_vert),
              onPressed: () => setState(() {
                final TrainStation? t = _from;
                _from = _to;
                _to = t;
              }),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _DateField(
          date: _date,
          onPicked: (DateTime d) => setState(() => _date = d),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: ready && !_loading ? _search : null,
          icon: const Icon(Icons.search),
          label: Text(l10n.translate('find')),
        ),
        if (!ready)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              l10n.translate('pick_both_stations'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
            ),
          ),
        const SizedBox(height: 20),
        if (_loading)
          const Center(
              child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(),
          ))
        else if (_error != null)
          _ErrorNote(message: '${l10n.translate('load_error')}: $_error')
        else if (_results != null && _results!.isEmpty)
          EmptyState(
            icon: Icons.train_outlined,
            message: l10n.translate('no_trains_found'),
          )
        else if (_results != null)
          ..._results!.map((TrainConnection c) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _ConnectionCard(connection: c),
              )),
        if (_results != null && _results!.isNotEmpty) ...<Widget>[
          const SizedBox(height: 8),
          _SourceNote(),
        ],
      ],
    );
  }
}

class _ConnectionCard extends StatelessWidget {
  final TrainConnection connection;

  const _ConnectionCard({required this.connection});

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Text(
                  connection.departureTime,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Column(
                      children: <Widget>[
                        if (connection.duration.isNotEmpty)
                          Text(
                            connection.duration,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        Container(
                          height: 1,
                          margin: const EdgeInsets.only(top: 3),
                          color: scheme.outlineVariant,
                        ),
                      ],
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Text(
                      connection.arrivalTime,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (connection.arrivesNextDay)
                      Text(
                        l10n.translate('next_day'),
                        style: TextStyle(
                          fontSize: 10.5,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                _Pill(
                    text: '${l10n.translate('train_no')} ${connection.number}'),
                if (connection.rank.isNotEmpty) _Pill(text: connection.rank),
                if (connection.hasDelay)
                  _Pill(
                    text: '${l10n.translate('delay')} ${connection.delay}',
                    tone: _PillTone.warning,
                  ),
              ],
            ),
            if (connection.offer.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                connection.offer,
                style:
                    TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant),
              ),
            ],
            if (connection.note.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                connection.note,
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Station board
// ---------------------------------------------------------------------------

class _BoardTab extends StatefulWidget {
  const _BoardTab();

  @override
  State<_BoardTab> createState() => _BoardTabState();
}

class _BoardTabState extends State<_BoardTab>
    with AutomaticKeepAliveClientMixin {
  final SrbijavozService _service = SrbijavozService.instance;

  TrainStation? _station;
  DateTime _date = DateTime.now();
  BoardMode _mode = BoardMode.departures;
  List<StationBoardEntry>? _results;
  bool _loading = false;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  Future<void> _load() async {
    final TrainStation? station = _station;
    if (station == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final List<StationBoardEntry> entries = await _service.board(
        station: station,
        date: _date,
        mode: _mode,
      );
      await _service.rememberStation(station);
      if (!mounted) return;
      setState(() {
        _results = entries;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: <Widget>[
        _StationField(
          label: l10n.translate('select_station'),
          station: _station,
          onPicked: (TrainStation s) {
            setState(() => _station = s);
            _load();
          },
        ),
        const SizedBox(height: 12),
        _DateField(
          date: _date,
          onPicked: (DateTime d) {
            setState(() => _date = d);
            _load();
          },
        ),
        const SizedBox(height: 12),
        SegmentedButton<BoardMode>(
          segments: <ButtonSegment<BoardMode>>[
            ButtonSegment<BoardMode>(
              value: BoardMode.departures,
              label: Text(l10n.translate('departures')),
            ),
            ButtonSegment<BoardMode>(
              value: BoardMode.arrivals,
              label: Text(l10n.translate('arrivals')),
            ),
          ],
          selected: <BoardMode>{_mode},
          showSelectedIcon: false,
          onSelectionChanged: (Set<BoardMode> s) {
            setState(() => _mode = s.first);
            _load();
          },
        ),
        const SizedBox(height: 18),
        if (_loading)
          const Center(
              child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(),
          ))
        else if (_error != null)
          _ErrorNote(message: '${l10n.translate('load_error')}: $_error')
        else if (_station == null)
          EmptyState(
            icon: Icons.departure_board_outlined,
            message: l10n.translate('select_station'),
          )
        else if (_results != null && _results!.isEmpty)
          EmptyState(
            icon: Icons.train_outlined,
            message: l10n.translate('no_board_entries'),
          )
        else if (_results != null)
          Card(
            child: Column(
              children: <Widget>[
                for (int i = 0; i < _results!.length; i++) ...<Widget>[
                  if (i > 0) Divider(height: 1, color: scheme.outlineVariant),
                  _BoardRow(entry: _results![i]),
                ],
              ],
            ),
          ),
        if (_results != null && _results!.isNotEmpty) ...<Widget>[
          const SizedBox(height: 10),
          _SourceNote(),
        ],
      ],
    );
  }
}

class _BoardRow extends StatelessWidget {
  final StationBoardEntry entry;

  const _BoardRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 56,
            child: Text(
              entry.time,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  entry.station,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  <String>[
                    '${l10n.translate('train_no')} ${entry.number}',
                    if (entry.rank.isNotEmpty) entry.rank,
                    if (entry.otherTime.isNotEmpty) '→ ${entry.otherTime}',
                  ].join(' · '),
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (entry.hasDelay)
            _Pill(
              text: '+${entry.delay}',
              tone: _PillTone.warning,
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared pieces
// ---------------------------------------------------------------------------

class _StationField extends StatelessWidget {
  final String label;
  final TrainStation? station;
  final ValueChanged<TrainStation> onPicked;

  const _StationField({
    required this.label,
    required this.station,
    required this.onPicked,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          final TrainStation? picked = await showModalBottomSheet<TrainStation>(
            context: context,
            isScrollControlled: true,
            showDragHandle: true,
            builder: (_) => const _StationPicker(),
          );
          if (picked != null) onPicked(picked);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: <Widget>[
              Icon(Icons.train_outlined, color: scheme.onSurfaceVariant),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      station?.name ?? '—',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: station == null
                            ? scheme.onSurfaceVariant
                            : scheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.expand_more, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

/// Search sheet backed by the operator's station autocomplete.
class _StationPicker extends StatefulWidget {
  const _StationPicker();

  @override
  State<_StationPicker> createState() => _StationPickerState();
}

class _StationPickerState extends State<_StationPicker> {
  final SrbijavozService _service = SrbijavozService.instance;
  final TextEditingController _controller = TextEditingController();

  List<TrainStation> _results = const <TrainStation>[];
  List<TrainStation> _recent = const <TrainStation>[];
  Timer? _debounce;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service.recentStations().then((List<TrainStation> r) {
      if (mounted) setState(() => _recent = r);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    // One request per keystroke would hammer someone else's server.
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      if (!mounted) return;
      setState(() => _loading = true);
      try {
        final List<TrainStation> r = await _service.searchStations(value);
        if (mounted) {
          setState(() {
            _results = r;
            _error = null;
          });
        }
      } catch (e) {
        // The station list comes over the network the first time, so a failure
        // here is "we could not look", not "there is no such station".
        if (mounted) {
          setState(() {
            _results = const <TrainStation>[];
            _error = e.toString();
          });
        }
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool typing = _controller.text.trim().length >= 2;
    final List<TrainStation> shown = typing ? _results : _recent;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: l10n.translate('search_station'),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : null,
            ),
            onChanged: (String v) {
              setState(() {});
              _onChanged(v);
            },
          ),
          const SizedBox(height: 12),
          if (!typing && _recent.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 6),
              child: Text(
                l10n.translate('recent'),
                style: TextStyle(
                  fontSize: 12,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.45,
            ),
            child: shown.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    child: _error != null
                        ? _ErrorNote(
                            message: '${l10n.translate('load_error')}: $_error',
                          )
                        : Center(
                            child: Text(
                              typing
                                  ? l10n.translate('nothing_found')
                                  : l10n.translate('search_station'),
                              style: TextStyle(color: scheme.onSurfaceVariant),
                            ),
                          ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: shown.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: scheme.outlineVariant),
                    itemBuilder: (BuildContext context, int i) => ListTile(
                      shape: const RoundedRectangleBorder(),
                      dense: true,
                      leading: Icon(
                        typing ? Icons.place_outlined : Icons.history,
                        color: scheme.onSurfaceVariant,
                      ),
                      title: Text(shown[i].name,
                          style: const TextStyle(fontSize: 14.5)),
                      onTap: () => Navigator.of(context).pop(shown[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final DateTime date;
  final ValueChanged<DateTime> onPicked;

  const _DateField({required this.date, required this.onPicked});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final String locale = Localizations.localeOf(context).languageCode;

    return OutlinedButton.icon(
      onPressed: () async {
        final DateTime now = DateTime.now();
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(now.year, now.month, now.day),
          lastDate: now.add(const Duration(days: 180)),
        );
        if (picked != null) onPicked(picked);
      },
      icon: const Icon(Icons.calendar_today, size: 18),
      label: Text(
        '${l10n.translate('date')}: '
        '${DateFormat('d MMMM y', locale).format(date)}',
      ),
    );
  }
}

enum _PillTone { neutral, warning }

class _Pill extends StatelessWidget {
  final String text;
  final _PillTone tone;

  const _Pill({required this.text, this.tone = _PillTone.neutral});

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool warn = tone == _PillTone.warning;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: warn ? scheme.errorContainer : scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: warn ? scheme.onErrorContainer : scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _ErrorNote extends StatelessWidget {
  final String message;

  const _ErrorNote({required this.message});

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.cloud_off, size: 18, color: scheme.onErrorContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 13, color: scheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Text(
      AppLocalizations.of(context)!.translate('trains_source'),
      style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant),
    );
  }
}
