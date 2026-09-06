import 'package:flutter_test/flutter_test.dart';
import 'package:srbguide/data/train.dart';
import 'package:srbguide/utils/station_search.dart';

/// A slice of the real timetable, spelled the way it spells them.
final List<TrainStation> _network = <TrainStation>[
  const TrainStation(name: 'BEOGRAD CENTAR', code: '16052'),
  const TrainStation(name: 'NOVI BEOGRAD', code: '16003'),
  const TrainStation(name: 'NOVI SAD', code: '16808'),
  const TrainStation(name: 'NOVI SAD RANŽIRNA', code: '16870'),
  const TrainStation(name: 'NIŠ', code: '12551'),
  const TrainStation(name: 'NIŠEVAC', code: '14008'),
  const TrainStation(name: 'KRAGUJEVAC', code: '13217'),
  const TrainStation(name: 'SUBOTICA', code: '23450'),
  const TrainStation(name: 'VRŠAC', code: '22101'),
  const TrainStation(name: 'UŽICE', code: '15501'),
  const TrainStation(name: 'ZRENJANIN', code: '22506'),
  const TrainStation(name: 'PANČEVO-VAROŠ', code: '21005'),
  const TrainStation(name: 'ŠID', code: '17008'),
];

List<String> _names(String query) =>
    matchStations(_network, query).map((TrainStation s) => s.name).toList();

void main() {
  group('normalizeStation', () {
    test('brings both alphabets to the same spelling', () {
      expect(normalizeStation('Ниш'), normalizeStation('NIŠ'));
      expect(normalizeStation('NIŠ'), 'nis');
      expect(normalizeStation('Суботица'), 'subotica');
      expect(normalizeStation('Ужице'), normalizeStation('UŽICE'));
    });

    test('treats punctuation as a word break', () {
      expect(normalizeStation('PANČEVO-VAROŠ'), 'pancevo varos');
      expect(normalizeStation('BEOGRAD  CENTAR'), 'beograd centar');
      expect(
          normalizeStation('SUBOTICA JAV.SKLADIŠTA'), 'subotica jav skladista');
    });

    test('is empty for a query with nothing to match on', () {
      expect(normalizeStation('  ...  '), '');
    });
  });

  group('matchStations', () {
    test('finds a station typed in Russian', () {
      // The bug this exists for: the timetable answered "Белград" with all 396
      // stations, so the picker looked like it had stopped searching.
      expect(_names('Белград'), <String>['BEOGRAD CENTAR', 'NOVI BEOGRAD']);
      expect(_names('Ниш'), <String>['NIŠ', 'NIŠEVAC']);
      expect(_names('Нови Сад'), <String>['NOVI SAD', 'NOVI SAD RANŽIRNA']);
      expect(_names('Суботица'), <String>['SUBOTICA']);
    });

    test('absorbs the spelling differences between the two languages', () {
      // Крагуевац/Kragujevac and Белград/Beograd differ by one letter.
      expect(_names('Крагуевац'), <String>['KRAGUJEVAC']);
      expect(_names('Зренянин'), <String>['ZRENJANIN']);
      expect(_names('Вршац'), <String>['VRŠAC']);
      expect(_names('Панчево'), <String>['PANČEVO-VAROŠ']);
    });

    test('still works in Latin, with or without diacritics', () {
      expect(_names('nis'), <String>['NIŠ', 'NIŠEVAC']);
      expect(_names('niš'), <String>['NIŠ', 'NIŠEVAC']);
      expect(_names('uzice'), <String>['UŽICE']);
      expect(_names('novi sad'), <String>['NOVI SAD', 'NOVI SAD RANŽIRNA']);
    });

    test('matches inside the name, which the server could not', () {
      // The timetable's lookup is a prefix match: "centar" returned nothing.
      expect(_names('centar'), <String>['BEOGRAD CENTAR']);
      expect(_names('ranžirna'), <String>['NOVI SAD RANŽIRNA']);
    });

    test('puts the closest match first', () {
      expect(_names('beograd').first, 'BEOGRAD CENTAR');
      expect(_names('novi sad').first, 'NOVI SAD');
      expect(_names('niš').first, 'NIŠ');
    });

    test('answers an unknown station with nothing at all', () {
      expect(_names('zzzz'), isEmpty);
      expect(_names('Мадрид'), isEmpty);
      expect(_names('щщщщщ'), isEmpty);
    });

    test('does not let one typo match half the network', () {
      // Three letters plus an edit would reach NIŠ, ŠID and more.
      expect(_names('nid'), isEmpty);
    });

    test('honours the limit', () {
      expect(matchStations(_network, 'n', limit: 2), hasLength(lessThan(3)));
    });
  });
}
