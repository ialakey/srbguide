/// Light stemming for the guide search.
///
/// The guide is Russian, which inflects heavily: searching "банка" used to miss
/// every article that says "банки". A full morphological analyser would be
/// overkill (and slow over 1.5 MB of text), so only the *query* is stemmed and
/// the result is matched as a prefix against the raw text. "банка" becomes
/// "банк", which then matches "банки", "банков", "банковский".
library;

/// Russian inflectional endings, longest first so "ами" is tried before "и".
const List<String> _ruEndings = <String>[
  'ионных',
  'ионный',
  'ованные',
  'ования',
  'ами',
  'ями',
  'ах',
  'ях',
  'ов',
  'ев',
  'ей',
  'ой',
  'ый',
  'ий',
  'ая',
  'яя',
  'ое',
  'ее',
  'ые',
  'ие',
  'ам',
  'ям',
  'ом',
  'ем',
  'ую',
  'юю',
  'ешь',
  'ет',
  'ут',
  'ют',
  'ат',
  'ят',
  'ла',
  'ло',
  'ли',
  'ть',
  'а',
  'я',
  'о',
  'е',
  'ы',
  'и',
  'у',
  'ю',
  'ь',
  'й',
];

/// English endings, for the parts of the guide that are in English.
const List<String> _enEndings = <String>['ing', 'ies', 'es', 'ed', 's'];

/// Shortest stem we will accept. Below this, prefix matching produces noise —
/// "ВНЖ" stemmed to two letters would match half the guide.
const int _minStem = 4;

/// Reduces one word to a prefix that survives inflection.
String stemWord(String word) {
  final String w = word.toLowerCase().trim();
  if (w.length <= _minStem) return w;

  final bool cyrillic = RegExp(r'[а-яё]').hasMatch(w);
  for (final String ending in cyrillic ? _ruEndings : _enEndings) {
    if (w.length - ending.length >= _minStem && w.endsWith(ending)) {
      return w.substring(0, w.length - ending.length);
    }
  }
  return w;
}

/// Splits a query into stemmed terms, dropping punctuation and empties.
List<String> stemQuery(String query) {
  return query
      .toLowerCase()
      .split(RegExp(r'[^0-9a-zа-яё]+'))
      .where((String w) => w.isNotEmpty)
      .map(stemWord)
      .where((String w) => w.isNotEmpty)
      .toList();
}
