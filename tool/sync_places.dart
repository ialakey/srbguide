// Regenerates `assets/data/places.json` from https://stats.srb.guide/map.
//
//   dart run tool/sync_places.dart
//   dart run tool/sync_places.dart --out assets/data/places.json
//
// The catalogue of relocant-run businesses lives on stats.srb.guide. Its API
// requires auth, but the map page is server-rendered by SvelteKit and ships the
// full list in its hydration payload, which robots.txt allows us to read.
//
// Bundling the result means the map opens instantly and works offline; only the
// tiles need a connection.

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

const String kSource = 'https://stats.srb.guide/map';
const String kDefaultOut = 'assets/data/places.json';

Future<void> main(List<String> args) async {
  final String out = _argValue(args, '--out') ?? kDefaultOut;

  stdout.writeln('Fetching $kSource …');
  final String html = await _get(kSource);

  final List<Map<String, Object?>> places = _extractPlaces(html);
  if (places.isEmpty) {
    stderr.writeln('FAIL: no places found — the page layout probably changed');
    exit(1);
  }

  final Map<String, int> byCategory = <String, int>{};
  for (final Map<String, Object?> p in places) {
    final String c = (p['category'] ?? 'other') as String;
    byCategory[c] = (byCategory[c] ?? 0) + 1;
  }

  final Map<String, Object?> payload = <String, Object?>{
    'source': kSource,
    'syncedAt': DateTime.now().toUtc().toIso8601String(),
    'places': places,
  };

  final File file = File(out);
  await file.parent.create(recursive: true);
  await file.writeAsString(
    const JsonEncoder.withIndent('  ').convert(payload),
    encoding: utf8,
  );

  stdout.writeln('Wrote $out — ${places.length} places');
  final List<MapEntry<String, int>> sorted = byCategory.entries.toList()
    ..sort((MapEntry<String, int> a, MapEntry<String, int> b) =>
        b.value.compareTo(a.value));
  for (final MapEntry<String, int> e in sorted) {
    stdout.writeln('  ${e.value.toString().padLeft(4)}  ${e.key}');
  }
}

/// Pulls place records out of the SvelteKit hydration payload.
///
/// The payload is a JavaScript object literal, not JSON — keys are unquoted and
/// it contains `void 0` — so records are located by their `id`/`slug` header
/// and each field is then read out of that record's own window. Field order
/// varies between records (some carry `subcategory`, `instagram`, `chainId`),
/// so a single fixed-order pattern silently drops them.
List<Map<String, Object?>> _extractPlaces(String html) {
  final List<Map<String, Object?>> places = <Map<String, Object?>>[];
  final Set<String> seen = <String>{};

  final RegExp header = RegExp(r'\{id:"([0-9a-fA-F-]{36})",slug:"([^"]*)"');
  final List<RegExpMatch> starts = header.allMatches(html).toList();

  for (int i = 0; i < starts.length; i++) {
    final RegExpMatch m = starts[i];
    final String id = m.group(1)!;
    if (!seen.add(id)) continue;

    // Bound the window at the next record so fields cannot leak across.
    final int end = i + 1 < starts.length
        ? starts[i + 1].start
        : (m.start + 4000).clamp(0, html.length);
    final String window = html.substring(m.start, end);

    final double? lat = double.tryParse(_field(window, 'lat', quoted: false));
    final double? lng = double.tryParse(_field(window, 'lng', quoted: false));
    if (lat == null || lng == null) continue;
    // Serbia sits roughly in this box; anything else is a parse artefact.
    if (lat < 41 || lat > 47 || lng < 18 || lng > 23.5) continue;

    final String name = _field(window, 'name');
    if (name.isEmpty) continue;

    places.add(<String, Object?>{
      'id': id,
      'slug': m.group(2)!,
      'name': name,
      'description': _field(window, 'description'),
      'lat': lat,
      'lng': lng,
      'category': _field(window, 'category'),
      'subcategory': _field(window, 'subcategory'),
      'city': _field(window, 'city'),
      'opstina': _field(window, 'opstina'),
      'mapUrl': _googleUrl(window),
    });
  }

  places.sort((Map<String, Object?> a, Map<String, Object?> b) =>
      (a['name']! as String).compareTo(b['name']! as String));
  return places;
}

/// Reads one field out of a record window.
String _field(String window, String key, {bool quoted = true}) {
  // `\\\\` here is a single escaped backslash in the compiled pattern, which
  // is what lets the string matcher skip over `\"` inside a JS string literal.
  final RegExp re = quoted
      ? RegExp('(?:^|,)$key:("(?:[^"\\\\]|\\\\.)*"|void 0|null)')
      : RegExp('(?:^|,)$key:(-?[0-9]+\\.?[0-9]*)');
  final RegExpMatch? m = re.firstMatch(window);
  if (m == null) return '';
  return quoted ? _str(m.group(1)) : (m.group(1) ?? '');
}

/// The place's Google Maps link, which is what "open in maps" should use.
String _googleUrl(String window) {
  final RegExpMatch? m = RegExp(
    r'provider:"google",canonicalUrl:("(?:[^"\\]|\\.)*")',
  ).firstMatch(window);
  return m == null ? '' : _str(m.group(1));
}

/// Decodes a JS string literal, or returns `''` for `void 0` / `null`.
String _str(String? raw) {
  if (raw == null || raw == 'void 0' || raw == 'null') return '';
  if (!raw.startsWith('"')) return raw;
  try {
    return (json.decode(raw) as String).trim();
  } catch (_) {
    return raw.replaceAll('"', '').trim();
  }
}

Future<String> _get(String url) async {
  final http.Response response = await http.get(
    Uri.parse(url),
    headers: const <String, String>{
      'User-Agent':
          'srbguide-app-sync/1.0 (+https://github.com/ialakey/srbguide)',
      'Accept-Language': 'ru,en;q=0.8',
    },
  ).timeout(const Duration(seconds: 40));
  if (response.statusCode != 200) {
    throw StateError('HTTP ${response.statusCode} for $url');
  }
  return utf8.decode(response.bodyBytes);
}

String? _argValue(List<String> args, String flag) {
  final int i = args.indexOf(flag);
  if (i == -1 || i + 1 >= args.length) return null;
  return args[i + 1];
}
