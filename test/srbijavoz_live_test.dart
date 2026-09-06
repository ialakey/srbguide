@Tags(<String>['live'])
library;

// Live smoke test against the Serbian Railways timetable.
// Run with: flutter test test/srbijavoz_live_test.dart
//
// The timetable is a server-rendered page, so the parser depends on its table
// layout. Only a live run tells us the layout still matches.

import 'package:flutter_test/flutter_test.dart';
import 'package:srbguide/data/train.dart';
import 'package:srbguide/service/srbijavoz_service.dart';

void main() {
  final SrbijavozService service = SrbijavozService.instance;

  test('station lookup returns codes', () async {
    final List<TrainStation> stations = await service.searchStations('beograd');
    // ignore: avoid_print
    print(
        'stations: ${stations.map((TrainStation s) => '${s.name}=${s.code}').join(', ')}');
    expect(stations, isNotEmpty);
    expect(stations.every((TrainStation s) => s.isValid), isTrue);
  }, timeout: const Timeout(Duration(seconds: 60)));

  test('the whole network is fetched, and searchable in Russian', () async {
    final List<TrainStation> all = await service.stations();
    // ignore: avoid_print
    print('network: ${all.length} stations');
    // The lookup answers a term it cannot spell with everything it has; if that
    // ever stops being true, the picker is back to one request per keystroke.
    expect(all.length, greaterThan(300));

    final List<TrainStation> found = await service.searchStations('Белград');
    // ignore: avoid_print
    print('Белград -> ${found.map((TrainStation s) => s.name).join(', ')}');
    expect(found, isNotEmpty);
    expect(found.first.name, contains('BEOGRAD'));
  }, timeout: const Timeout(Duration(seconds: 60)));

  test('direct connections parse', () async {
    final List<TrainStation> from =
        await service.searchStations('beograd centar');
    final List<TrainStation> to = await service.searchStations('petrovaradin');
    expect(from, isNotEmpty);
    expect(to, isNotEmpty);

    final List<TrainConnection> runs = await service.connections(
      from: from.first,
      to: to.first,
      date: DateTime.now(),
    );
    // ignore: avoid_print
    print('${from.first.name} -> ${to.first.name}: ${runs.length} runs');
    for (final TrainConnection c in runs.take(3)) {
      // ignore: avoid_print
      print('  ${c.number}  ${c.departureTime} -> ${c.arrivalTime}  '
          '(${c.duration})  ${c.rank}  ${c.offer}');
    }
    expect(runs, isNotEmpty);
    // The class of train and what it carries are published as icons; if the
    // parser goes back to reading cell text, both columns go quietly empty.
    expect(
      runs.any((TrainConnection c) => c.rank.isNotEmpty),
      isTrue,
      reason: 'no service class on any run',
    );
    expect(
      runs.any((TrainConnection c) => c.offer.isNotEmpty),
      isTrue,
      reason: 'no travel classes on any run',
    );
    for (final TrainConnection c in runs) {
      expect(c.number, isNotEmpty);
      expect(RegExp(r'^\d{1,2}:\d{2}$').hasMatch(c.departureTime), isTrue,
          reason: 'departure "${c.departureTime}" is not a time');
      expect(RegExp(r'^\d{1,2}:\d{2}$').hasMatch(c.arrivalTime), isTrue,
          reason: 'arrival "${c.arrivalTime}" is not a time');
    }
  }, timeout: const Timeout(Duration(seconds: 90)));

  test('station board parses', () async {
    final List<TrainStation> station =
        await service.searchStations('beograd centar');
    final List<StationBoardEntry> board = await service.board(
      station: station.first,
      date: DateTime.now(),
    );
    // ignore: avoid_print
    print('board ${station.first.name}: ${board.length} entries');
    for (final StationBoardEntry e in board.take(3)) {
      // ignore: avoid_print
      print('  ${e.time}  ${e.station}  (${e.number})  ${e.rank}');
    }
    expect(board, isNotEmpty);
    expect(
      board.any((StationBoardEntry e) => e.rank.isNotEmpty),
      isTrue,
      reason: 'no service class on any departure',
    );
    for (final StationBoardEntry e in board) {
      expect(e.number, isNotEmpty);
      expect(e.station, isNotEmpty);
      expect(RegExp(r'^\d{1,2}:\d{2}$').hasMatch(e.time), isTrue,
          reason: 'time "${e.time}" is not a time');
    }
  }, timeout: const Timeout(Duration(seconds: 90)));
}
