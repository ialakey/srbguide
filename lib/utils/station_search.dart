/// Matching for the railway station picker.
///
/// The timetable's own lookup only understands Latin. Its front end strips
/// anything else out of the term before sending it, so "Белград" reaches the
/// server as an empty term — and an empty term is answered with all 396
/// stations. The picker showed that dump as if it were the search result,
/// which is why typing a station in Russian looked like the search was broken.
///
/// The whole list is 15 KB, so it is fetched once and matched here instead.
/// Russian and Serbian spell the same place differently — Белград/Beograd,
/// Крагуевац/Kragujevac — so on top of transliteration each word of the query
/// is allowed one character of slack against the station name.
library;

import 'package:srbguide/data/train.dart';

/// Cyrillic to Latin, in the convention Serbian itself uses (ж → z, я → ja),
/// extended with the Russian letters Serbian does not have.
const Map<String, String> _cyrillicToLatin = <String, String>{
  'а': 'a',
  'б': 'b',
  'в': 'v',
  'г': 'g',
  'д': 'd',
  'ђ': 'dj',
  'е': 'e',
  'ё': 'jo',
  'ж': 'z',
  'з': 'z',
  'и': 'i',
  'й': 'j',
  'ј': 'j',
  'к': 'k',
  'л': 'l',
  'љ': 'lj',
  'м': 'm',
  'н': 'n',
  'њ': 'nj',
  'о': 'o',
  'п': 'p',
  'р': 'r',
  'с': 's',
  'т': 't',
  'ћ': 'c',
  'у': 'u',
  'ф': 'f',
  'х': 'h',
  'ц': 'c',
  'ч': 'c',
  'џ': 'dz',
  'ш': 's',
  'щ': 'sc',
  'ъ': '',
  'ы': 'i',
  'ь': '',
  'э': 'e',
  'ю': 'ju',
  'я': 'ja',
};

/// Serbian Latin diacritics, folded so "nis" finds "NIŠ".
const Map<String, String> _diacriticsToAscii = <String, String>{
  'š': 's',
  'č': 'c',
  'ć': 'c',
  'ž': 'z',
  'đ': 'dj',
};

/// Lower-cased, transliterated, stripped of everything but letters and digits.
///
/// `NIŠ` and `Ниш` both come out as `nis`, so the two alphabets meet.
String normalizeStation(String value) {
  final StringBuffer out = StringBuffer();
  bool pendingSpace = false;

  for (final int rune in value.toLowerCase().runes) {
    final String ch = String.fromCharCode(rune);
    final String mapped = _cyrillicToLatin[ch] ?? _diacriticsToAscii[ch] ?? ch;

    final bool plain = RegExp(r'^[a-z0-9]*$').hasMatch(mapped);
    if (!plain || mapped.isEmpty) {
      // Hyphens, dots and anything else become a single separator: the
      // timetable writes both "NOVI SAD" and "PANČEVO-VAROŠ".
      if (!plain) pendingSpace = out.isNotEmpty;
      continue;
    }
    if (pendingSpace) {
      out.write(' ');
      pendingSpace = false;
    }
    out.write(mapped);
  }
  return out.toString();
}

/// Stations matching [query], best first.
///
/// Ranked exact, prefix, substring, then one-typo — so "beo" puts BEOGRAD
/// CENTAR above NOVI BEOGRAD, and "Белград" still finds both.
List<TrainStation> matchStations(
  List<TrainStation> stations,
  String query, {
  int limit = 40,
}) {
  final String q = normalizeStation(query);
  if (q.isEmpty) return const <TrainStation>[];
  final List<String> words = q.split(' ');

  final List<_Hit> hits = <_Hit>[];

  for (final TrainStation station in stations) {
    final String name = normalizeStation(station.name);
    final int rank;
    int at = 0;
    if (name == q) {
      rank = 0;
    } else if (name.startsWith(q)) {
      rank = 1;
    } else if (name.contains(q)) {
      rank = 2;
    } else {
      final int? typoAt = _typoMatch(name, words);
      if (typoAt == null) continue;
      rank = 3;
      at = typoAt;
    }
    hits.add(_Hit(rank, at, name.length, station));
  }

  // Rank, then how early in the name the match sits — "Белград" should offer
  // BEOGRAD CENTAR before NOVI BEOGRAD — then the shorter name.
  hits.sort((_Hit a, _Hit b) {
    if (a.rank != b.rank) return a.rank.compareTo(b.rank);
    if (a.at != b.at) return a.at.compareTo(b.at);
    if (a.length != b.length) return a.length.compareTo(b.length);
    return a.station.name.compareTo(b.station.name);
  });

  return hits.take(limit).map((_Hit h) => h.station).toList();
}

class _Hit {
  final int rank;
  final int at;
  final int length;
  final TrainStation station;

  const _Hit(this.rank, this.at, this.length, this.station);
}

/// Where the query first lands in [name] when every one of its words matches a
/// word of the name give or take one character, and null when one does not.
///
/// Short words are left out of the slack: at three letters one edit matches
/// half the network.
int? _typoMatch(String name, List<String> words) {
  final List<String> nameWords = name.split(' ');
  int? first;

  for (final String word in words) {
    final int at = nameWords.indexWhere((String w) =>
        word.length < 5 ? w.startsWith(word) : _withinOneEdit(w, word));
    if (at == -1) return null;
    first ??= at;
  }
  return first ?? 0;
}

/// Levenshtein distance of at most one, without building the matrix.
bool _withinOneEdit(String a, String b) {
  if ((a.length - b.length).abs() > 1) return false;

  int i = 0;
  int j = 0;
  bool edited = false;
  while (i < a.length && j < b.length) {
    if (a[i] == b[j]) {
      i++;
      j++;
      continue;
    }
    if (edited) return false;
    edited = true;
    // Substitution when the lengths match, otherwise skip the longer side.
    if (a.length == b.length) {
      i++;
      j++;
    } else if (a.length > b.length) {
      i++;
    } else {
      j++;
    }
  }
  // A leftover character on either side is the edit itself.
  return !(edited && (i < a.length || j < b.length));
}
