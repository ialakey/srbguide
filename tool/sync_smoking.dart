// Regenerates `assets/data/smoking.json` from the "Lokali bez dima" map.
//
//   dart run tool/sync_smoking.dart
//   dart run tool/sync_smoking.dart --out assets/data/smoking.json
//
// The non-smoking venues used to be a Google My Maps link opened in a WebView.
// My Maps exports KML for free, so the points are pulled out here and bundled
// like the rest of the catalogue: the places screen then shows them as pins
// next to the relocant businesses, offline and without loading Google.
//
// Two layers are published on that map, and they mean different things:
//   Nepušački lokal      — smoking is banned outright     -> smoking: none
//   Bezdimna alternativa — only smokeless devices allowed -> smoking: alternative

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

const String kMapId = '1DhbU4mNbi0OVkoRSpKBqBmWqeRXU5vo';
const String kSource = 'https://www.google.com/maps/d/viewer?mid=$kMapId';
const String kUpstream = 'https://lokalibezdima.rs';
const String kDefaultOut = 'assets/data/smoking.json';

/// Layer name on the map -> the value stored on each place.
const Map<String, String> kLayers = <String, String>{
  'Nepušački lokal': 'none',
  'Bezdimna alternativa': 'alternative',
};

/// City centres used to label a point, with the radius that still counts as
/// that city. Only for the city filter — a point outside them all keeps `''`.
const List<({String slug, double lat, double lng, double km})> kCities =
    <({String slug, double lat, double lng, double km})>[
  (slug: 'beograd', lat: 44.8125, lng: 20.4612, km: 25),
  (slug: 'novi-sad', lat: 45.2551, lng: 19.8452, km: 20),
  (slug: 'nis', lat: 43.3209, lng: 21.8958, km: 15),
  (slug: 'subotica', lat: 46.1000, lng: 19.6650, km: 15),
  (slug: 'kragujevac', lat: 44.0128, lng: 20.9114, km: 15),
  (slug: 'zrenjanin', lat: 45.3836, lng: 20.3819, km: 15),
  (slug: 'pancevo', lat: 44.8708, lng: 20.6403, km: 12),
  (slug: 'cacak', lat: 43.8914, lng: 20.3497, km: 15),
];

Future<void> main(List<String> args) async {
  final String out = _argValue(args, '--out') ?? kDefaultOut;

  stdout.writeln('Fetching the KML export of $kSource …');
  final String kml = await _get(
    'https://www.google.com/maps/d/kml?mid=$kMapId&forcekml=1',
  );

  final List<Map<String, Object?>> places = _extractPlaces(kml);
  if (places.isEmpty) {
    stderr.writeln('FAIL: no placemarks found — the map or its layers changed');
    exit(1);
  }

  final Map<String, Object?> payload = <String, Object?>{
    'source': kSource,
    'upstream': kUpstream,
    'syncedAt': DateTime.now().toUtc().toIso8601String(),
    'places': places,
  };

  final File file = File(out);
  await file.parent.create(recursive: true);
  await file.writeAsString(
    const JsonEncoder.withIndent('  ').convert(payload),
    encoding: utf8,
  );

  stdout.writeln('Wrote $out — ${places.length} venues');
  for (final MapEntry<String, String> layer in kLayers.entries) {
    final int n = places.where((Map<String, Object?> p) {
      return p['smoking'] == layer.value;
    }).length;
    stdout.writeln('  ${n.toString().padLeft(4)}  ${layer.key}');
  }
}

/// Reads the placemarks of every known layer out of the KML document.
List<Map<String, Object?>> _extractPlaces(String kml) {
  final XmlDocument doc = XmlDocument.parse(kml);
  final List<Map<String, Object?>> places = <Map<String, Object?>>[];
  final Set<String> seen = <String>{};

  for (final XmlElement folder in doc.findAllElements('Folder')) {
    final String layer = _text(folder, 'name');
    final String? smoking = kLayers[layer];
    if (smoking == null) {
      stderr.writeln('Skipping unknown layer "$layer"');
      continue;
    }

    for (final XmlElement placemark in folder.findElements('Placemark')) {
      final String name = _text(placemark, 'name');
      final ({double lat, double lng})? point = _point(placemark);
      if (name.isEmpty || point == null) continue;

      // A venue listed on both layers keeps the stricter one, which is the
      // order kLayers is walked in.
      final String id = 'smoke-${_hash('$name|${point.lat}|${point.lng}')}';
      if (!seen.add(id)) continue;

      places.add(<String, Object?>{
        'id': id,
        'name': name,
        'description': _text(placemark, 'description'),
        'lat': point.lat,
        'lng': point.lng,
        // The map says nothing about what kind of venue this is, and guessing
        // "food" would put cafés under a filter they may not belong in.
        'category': '',
        'city': _city(point.lat, point.lng),
        'opstina': '',
        'mapUrl': 'https://www.google.com/maps/search/?api=1'
            '&query=${point.lat},${point.lng}',
        'smoking': smoking,
      });
    }
  }

  places.sort((Map<String, Object?> a, Map<String, Object?> b) =>
      (a['name']! as String).compareTo(b['name']! as String));
  return places;
}

/// `<coordinates>lng,lat,alt</coordinates>` of a Point placemark.
({double lat, double lng})? _point(XmlElement placemark) {
  final Iterable<XmlElement> points = placemark.findAllElements('Point');
  if (points.isEmpty) return null;
  final List<String> parts =
      _text(points.first, 'coordinates').split(',').map((String s) {
    return s.trim();
  }).toList();
  if (parts.length < 2) return null;

  final double? lng = double.tryParse(parts[0]);
  final double? lat = double.tryParse(parts[1]);
  if (lat == null || lng == null) return null;
  // Serbia plus a margin; anything else is a stray pin, not a venue.
  if (lat < 41 || lat > 47 || lng < 18 || lng > 23.5) return null;
  return (lat: lat, lng: lng);
}

String _text(XmlElement parent, String tag) {
  final Iterable<XmlElement> found = parent.findElements(tag);
  return found.isEmpty ? '' : found.first.innerText.trim();
}

String _city(double lat, double lng) {
  for (final ({String slug, double lat, double lng, double km}) c in kCities) {
    final double dLat = (lat - c.lat) * 111.32;
    final double dLng = (lng - c.lng) * 78.6;
    if (dLat * dLat + dLng * dLng <= c.km * c.km) return c.slug;
  }
  return '';
}

/// FNV-1a, so a venue keeps its id across syncs as long as it does not move.
String _hash(String value) {
  int hash = 0x811c9dc5;
  for (final int unit in utf8.encode(value)) {
    hash = ((hash ^ unit) * 0x01000193) & 0xffffffff;
  }
  return hash.toRadixString(16).padLeft(8, '0');
}

Future<String> _get(String url) async {
  final http.Response response = await http.get(
    Uri.parse(url),
    headers: const <String, String>{
      'User-Agent':
          'srbguide-app-sync/1.0 (+https://github.com/ialakey/srbguide)',
      'Accept-Language': 'sr,en;q=0.8',
    },
  ).timeout(const Duration(seconds: 60));
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
