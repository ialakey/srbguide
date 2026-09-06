import 'dart:convert';

import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:srbguide/data/train.dart';
import 'package:srbguide/utils/station_search.dart';

/// Reads the Serbian Railways timetable at w3.srbvoz.rs.
///
/// The operator's own site is a jQuery front end over two endpoints: a JSON
/// station lookup, and two server-rendered result pages. Station search is
/// therefore clean JSON; the timetables have to be read out of the result
/// tables, which is why the row layouts are pinned down in one place here
/// rather than scattered through the UI.
///
/// The station lookup only understands Latin, so it is used the way the site's
/// own front end uses it for a term it cannot send — once, with no term, which
/// returns the whole network. Matching then happens on device, where a Russian
/// spelling can be transliterated. See `utils/station_search.dart`.
class SrbijavozService {
  SrbijavozService._();

  static final SrbijavozService instance = SrbijavozService._();

  static const String _base = 'https://w3.srbvoz.rs/redvoznje';
  static const String _recentKey = 'recentTrainStations';
  static const String _stationsKey = 'trainStations';
  static const String _stationsAtKey = 'trainStationsFetchedAt';

  /// The network barely changes, and a stale list still resolves to the same
  /// codes, so this only guards against a station being added and never seen.
  static const Duration _stationsTtl = Duration(days: 7);

  static const Map<String, String> _headers = <String, String>{
    'User-Agent':
        'Mozilla/5.0 (Linux; Android 16) AppleWebKit/537.36 srbguide-app',
    'Accept-Language': 'sr,en;q=0.8',
  };

  /// The whole network, once it has been fetched.
  List<TrainStation>? _stations;

  /// Autocomplete over station names, matched on device.
  Future<List<TrainStation>> searchStations(String term) async {
    final String q = term.trim();
    if (q.length < 2) return const <TrainStation>[];
    return matchStations(await stations(), q);
  }

  /// Every station the timetable knows, from memory, storage or the network.
  ///
  /// 396 rows and 15 KB, so it is worth holding: the picker then answers every
  /// keystroke without a request, and works while the connection is flaky.
  Future<List<TrainStation>> stations() async {
    final List<TrainStation>? held = _stations;
    if (held != null) return held;

    final ({List<TrainStation> stations, bool fresh}) stored =
        await _storedStations();
    if (stored.stations.isNotEmpty && stored.fresh) {
      return _stations = stored.stations;
    }

    try {
      final List<TrainStation> fetched = await _fetchStations();
      if (fetched.isNotEmpty) {
        await _storeStations(fetched);
        return _stations = fetched;
      }
    } catch (e) {
      // An expired list still names every station people search for.
      if (stored.stations.isEmpty) {
        throw TrainServiceException('network error ($e)');
      }
    }

    if (stored.stations.isEmpty) {
      throw const TrainServiceException('station list unavailable');
    }
    return _stations = stored.stations;
  }

  /// The stored copy and whether it is still within its TTL. Storage failing —
  /// as it does in a plain test binding — only costs us the cache.
  Future<({List<TrainStation> stations, bool fresh})> _storedStations() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final DateTime? fetchedAt =
          DateTime.tryParse(prefs.getString(_stationsAtKey) ?? '');
      return (
        stations: _decodeStations(
          prefs.getStringList(_stationsKey) ?? const <String>[],
        ),
        fresh: fetchedAt != null &&
            DateTime.now().difference(fetchedAt) < _stationsTtl,
      );
    } catch (_) {
      return (stations: const <TrainStation>[], fresh: false);
    }
  }

  Future<void> _storeStations(List<TrainStation> stations) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _stationsKey,
        stations.map((TrainStation s) => json.encode(s.toJson())).toList(),
      );
      await prefs.setString(
        _stationsAtKey,
        DateTime.now().toIso8601String(),
      );
    } catch (_) {
      // Nothing to do — the list is held in memory for this run either way.
    }
  }

  /// Asks the lookup with no term, which is what the operator's own front end
  /// does with a term it cannot encode, and is answered with every station.
  Future<List<TrainStation>> _fetchStations() async {
    final Uri uri = Uri.parse('$_base/api/stanica/')
        .replace(queryParameters: <String, String>{'term': ''});
    final http.Response response = await http.get(uri,
        headers: <String, String>{
          ..._headers,
          'Accept': 'application/json'
        }).timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw TrainServiceException('HTTP ${response.statusCode}');
    }

    final List<dynamic> decoded =
        json.decode(utf8.decode(response.bodyBytes)) as List<dynamic>;
    return decoded
        .cast<Map<String, dynamic>>()
        .map(TrainStation.fromJson)
        .where((TrainStation s) => s.isValid)
        .toList();
  }

  List<TrainStation> _decodeStations(List<String> raw) => raw
      .map((String s) {
        try {
          return TrainStation.fromJson(json.decode(s) as Map<String, dynamic>);
        } catch (_) {
          return null;
        }
      })
      .whereType<TrainStation>()
      .where((TrainStation s) => s.isValid)
      .toList();

  /// Direct services between two stations on [date].
  Future<List<TrainConnection>> connections({
    required TrainStation from,
    required TrainStation to,
    required DateTime date,
    String time = '0000',
  }) async {
    final Document doc = await _load(
      '$_base/direktni/${_name(from)}/${from.code}/${_name(to)}/${to.code}'
      '/${_date(date)}/$time/sr',
    );

    return _rows(doc, 11)
        .map(
          (List<String> c) => TrainConnection(
            number: c[0],
            departureTime: c[1],
            departureDate: c[2],
            arrivalTime: c[3],
            arrivalDate: c[4],
            delay: c[5],
            duration: c[6],
            rank: c[7],
            note: c[9],
          ),
        )
        .toList();
  }

  /// Departure or arrival board for a single station.
  Future<List<StationBoardEntry>> board({
    required TrainStation station,
    required DateTime date,
    BoardMode mode = BoardMode.departures,
    String time = '0000',
  }) async {
    final Document doc = await _load(
      '$_base/stanicni/${_name(station)}/${station.code}'
      '/${_date(date)}/$time/${mode.query}/999/sr',
    );

    return _rows(doc, 9)
        .map(
          (List<String> c) => StationBoardEntry(
            number: c[0],
            time: c[1],
            station: c[2],
            otherTime: c[3],
            rank: c[4],
            delay: c[6],
            note: c[7],
          ),
        )
        .toList();
  }

  Future<Document> _load(String url) async {
    late http.Response response;
    try {
      response = await http
          .get(Uri.parse(url), headers: _headers)
          .timeout(const Duration(seconds: 30));
    } catch (e) {
      throw TrainServiceException('network error ($e)');
    }
    if (response.statusCode != 200) {
      throw TrainServiceException('HTTP ${response.statusCode}');
    }
    return html_parser.parse(utf8.decode(response.bodyBytes));
  }

  /// Pulls the data rows out of a result table.
  ///
  /// Each result is rendered twice: a `tr.tsmall` for wide layouts and a
  /// `tr.tbig` repeating the same values for narrow ones. Only the former is
  /// read, and the header row is skipped because it uses `th` rather than `td`.
  List<List<String>> _rows(Document doc, int expectedCells) {
    final Element? results = doc.querySelector('#rezultati');
    if (results == null) return const <List<String>>[];

    final List<List<String>> rows = <List<String>>[];
    for (final Element tr in results.querySelectorAll('tr.tsmall')) {
      final List<Element> cells = tr.querySelectorAll('td');
      if (cells.length < expectedCells) continue;

      final List<String> values =
          cells.map((Element c) => c.text.trim()).toList();
      // The last cell is a "Detaljnije" link, and a run always has a number.
      if (values.first.isEmpty) continue;
      rows.add(values);
    }
    return rows;
  }

  /// The timetable expects the station name with spaces and no dots.
  static String _name(TrainStation station) => Uri.encodeComponent(
        station.name.replaceAll('-', ' ').replaceAll('.', '').trim(),
      );

  static String _date(DateTime d) =>
      '${_two(d.day)}.${_two(d.month)}.${d.year}';

  static String _two(int v) => v.toString().padLeft(2, '0');

  /// `HHmm`, the format the timetable uses in its URLs.
  static String formatTime(DateTime t) => '${_two(t.hour)}${_two(t.minute)}';

  // --- Recently used stations ----------------------------------------------

  Future<List<TrainStation>> recentStations() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return _decodeStations(prefs.getStringList(_recentKey) ?? <String>[]);
  }

  Future<void> rememberStation(TrainStation station) async {
    if (!station.isValid) return;
    final List<TrainStation> recent = await recentStations();
    recent.removeWhere((TrainStation s) => s.code == station.code);
    recent.insert(0, station);

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _recentKey,
      recent.take(8).map((TrainStation s) => json.encode(s.toJson())).toList(),
    );
  }
}

/// Raised when the timetable cannot be reached or no longer parses.
class TrainServiceException implements Exception {
  final String message;
  const TrainServiceException(this.message);

  @override
  String toString() => message;
}
