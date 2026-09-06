/// A station in the Serbian Railways timetable.
class TrainStation {
  /// Display name as the timetable spells it, e.g. `BEOGRAD CENTAR`.
  final String name;

  /// Internal station code, e.g. `16052`. Required by every search.
  final String code;

  const TrainStation({required this.name, required this.code});

  factory TrainStation.fromJson(Map<String, dynamic> json) => TrainStation(
        name: (json['naziv'] ?? '') as String,
        code: (json['sifra'] ?? '').toString(),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'naziv': name,
        'sifra': code,
      };

  bool get isValid => name.isNotEmpty && code.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      other is TrainStation && other.code == code && other.name == name;

  @override
  int get hashCode => Object.hash(name, code);
}

/// One direct service between two stations.
class TrainConnection {
  final String number;
  final String departureTime;
  final String departureDate;
  final String arrivalTime;
  final String arrivalDate;

  /// Scheduled journey time, `HH:mm`.
  final String duration;

  /// Reported delay; empty when the operator has not published one.
  final String delay;

  /// Service class (`Soko`, `Regio`, ...) when given.
  final String rank;

  final String note;

  const TrainConnection({
    required this.number,
    required this.departureTime,
    required this.departureDate,
    required this.arrivalTime,
    required this.arrivalDate,
    required this.duration,
    required this.delay,
    required this.rank,
    required this.note,
  });

  bool get hasDelay => delay.trim().isNotEmpty && delay.trim() != '00:00';

  /// True when the service arrives on a later calendar day than it departs.
  bool get arrivesNextDay =>
      departureDate.isNotEmpty &&
      arrivalDate.isNotEmpty &&
      departureDate != arrivalDate;
}

/// One row of a station's departure or arrival board.
class StationBoardEntry {
  final String number;

  /// Time at the station being viewed.
  final String time;

  /// The other end of the journey — destination when viewing departures,
  /// origin when viewing arrivals.
  final String station;

  /// Time at that other end.
  final String otherTime;

  final String rank;
  final String delay;
  final String note;

  const StationBoardEntry({
    required this.number,
    required this.time,
    required this.station,
    required this.otherTime,
    required this.rank,
    required this.delay,
    required this.note,
  });

  bool get hasDelay => delay.trim().isNotEmpty && delay.trim() != '00:00';
}

/// Which way round a station board is read.
enum BoardMode {
  departures,
  arrivals;

  /// Value the timetable expects in the URL.
  String get query => this == BoardMode.departures ? 'polazak' : 'dolazak';
}
