import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A relocant-run business from the stats.srb.guide catalogue.
class Place {
  final String id;
  final String name;
  final String description;
  final double lat;
  final double lng;

  /// Catalogue category key, e.g. `food`, `beauty`, `car`.
  final String category;

  /// City slug, e.g. `beograd`.
  final String city;

  /// Municipality, already in Cyrillic, e.g. `Вождовац`.
  final String opstina;

  /// Google Maps link for turn-by-turn directions.
  final String mapUrl;

  /// Smoking policy when it is known: `none` for a venue where smoking is
  /// banned, `alternative` where only smokeless devices are allowed. Empty for
  /// the businesses catalogue, which does not track it.
  final String smoking;

  const Place({
    required this.id,
    required this.name,
    required this.description,
    required this.lat,
    required this.lng,
    required this.category,
    required this.city,
    required this.opstina,
    required this.mapUrl,
    this.smoking = '',
  });

  factory Place.fromJson(Map<String, dynamic> json) => Place(
        id: (json['id'] ?? '') as String,
        name: (json['name'] ?? '') as String,
        description: (json['description'] ?? '') as String,
        lat: (json['lat'] as num?)?.toDouble() ?? 0,
        lng: (json['lng'] as num?)?.toDouble() ?? 0,
        category: (json['category'] ?? '') as String,
        city: (json['city'] ?? '') as String,
        opstina: (json['opstina'] ?? '') as String,
        mapUrl: (json['mapUrl'] ?? '') as String,
        smoking: (json['smoking'] ?? '') as String,
      );

  Place withSmoking(String value) => Place(
        id: id,
        name: name,
        description: description,
        lat: lat,
        lng: lng,
        category: category,
        city: city,
        opstina: opstina,
        mapUrl: mapUrl,
        smoking: value,
      );

  bool get isValid => name.isNotEmpty && lat != 0 && lng != 0;

  String get searchIndex =>
      '$name $description $city $opstina $category'.toLowerCase();
}

/// The catalogue plus where and when it came from.
class PlaceCatalogue {
  final String source;
  final DateTime? syncedAt;
  final List<Place> places;

  const PlaceCatalogue({
    required this.source,
    required this.syncedAt,
    required this.places,
  });

  static const PlaceCatalogue empty =
      PlaceCatalogue(source: '', syncedAt: null, places: <Place>[]);

  factory PlaceCatalogue.fromJson(Map<String, dynamic> json) {
    final List<dynamic> raw = (json['places'] ?? <dynamic>[]) as List<dynamic>;
    return PlaceCatalogue(
      source: (json['source'] ?? '') as String,
      syncedAt: DateTime.tryParse((json['syncedAt'] ?? '') as String),
      places: raw
          .cast<Map<String, dynamic>>()
          .map(Place.fromJson)
          .where((Place p) => p.isValid)
          .toList(),
    );
  }

  /// Folds a second catalogue into this one.
  ///
  /// The lists overlap: a handful of relocant-run cafés are also on the
  /// non-smoking map. Those are matched by name and proximity and marked in
  /// place, so the map does not end up with two pins on the same doorstep.
  PlaceCatalogue mergedWith(PlaceCatalogue other) {
    if (other.places.isEmpty) return this;

    final List<Place> merged = List<Place>.of(places);
    final Map<String, List<int>> byName = <String, List<int>>{};
    for (int i = 0; i < merged.length; i++) {
      byName.putIfAbsent(_nameKey(merged[i].name), () => <int>[]).add(i);
    }

    for (final Place p in other.places) {
      int? at;
      for (final int i in byName[_nameKey(p.name)] ?? const <int>[]) {
        if (_metresBetween(merged[i], p) <= 250) {
          at = i;
          break;
        }
      }
      if (at == null) {
        merged.add(p);
      } else if (merged[at].smoking.isEmpty && p.smoking.isNotEmpty) {
        merged[at] = merged[at].withSmoking(p.smoking);
      }
    }

    return PlaceCatalogue(
      source: source,
      syncedAt: syncedAt,
      places: merged,
    );
  }

  /// Smoking policies present, ordered as the filter row shows them.
  List<String> get smokingPolicies {
    const List<String> order = <String>['none', 'alternative'];
    return order
        .where((String v) => places.any((Place p) => p.smoking == v))
        .toList();
  }

  /// Categories present, ordered by how many places use them.
  List<String> get categories {
    final Map<String, int> counts = <String, int>{};
    for (final Place p in places) {
      if (p.category.isEmpty) continue;
      counts[p.category] = (counts[p.category] ?? 0) + 1;
    }
    final List<String> keys = counts.keys.toList()
      ..sort((String a, String b) => counts[b]!.compareTo(counts[a]!));
    return keys;
  }
}

/// Name reduced to letters and digits, so `Kaži Važi` and `Kazi Vazi!` are one
/// venue rather than two.
String _nameKey(String name) =>
    name.toLowerCase().replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), '');

/// Straight-line distance in metres. Fine at this scale, and no trigonometry
/// beyond one cosine.
double _metresBetween(Place a, Place b) {
  final double dLat = (a.lat - b.lat) * 111320;
  final double dLng =
      (a.lng - b.lng) * 111320 * math.cos(a.lat * math.pi / 180);
  return math.sqrt(dLat * dLat + dLng * dLng);
}

/// Icon and colour per catalogue category, so the map reads at a glance.
({IconData icon, Color color}) placeStyle(String category) {
  switch (category) {
    case 'food':
      return (icon: Icons.restaurant, color: const Color(0xFFE8590C));
    case 'bar':
      return (icon: Icons.local_bar, color: const Color(0xFF9C36B5));
    case 'shop':
      return (icon: Icons.storefront, color: const Color(0xFF1971C2));
    case 'beauty':
      return (icon: Icons.spa, color: const Color(0xFFC2255C));
    case 'education':
      return (icon: Icons.school, color: const Color(0xFF1098AD));
    case 'car':
      return (icon: Icons.directions_car, color: const Color(0xFF495057));
    case 'services':
      return (icon: Icons.handyman, color: const Color(0xFF5F3DC4));
    case 'entertainment':
      return (icon: Icons.celebration, color: const Color(0xFFD6336C));
    case 'sightseeing':
      return (icon: Icons.photo_camera, color: const Color(0xFF2F9E44));
    case 'electronics':
      return (icon: Icons.devices, color: const Color(0xFF364FC7));
    case 'clothing':
      return (icon: Icons.checkroom, color: const Color(0xFF862E9C));
    case 'medicina':
      return (icon: Icons.medical_services, color: const Color(0xFFE03131));
    case 'children':
      return (icon: Icons.child_care, color: const Color(0xFFF08C00));
    case 'sport':
      return (icon: Icons.fitness_center, color: const Color(0xFF2B8A3E));
    default:
      return (icon: Icons.place, color: const Color(0xFF6C757D));
  }
}

/// Icon and colour for a smoking policy.
({IconData icon, Color color}) smokingStyle(String smoking) =>
    smoking == 'alternative'
        ? (icon: Icons.air, color: const Color(0xFF0C8599))
        : (icon: Icons.smoke_free, color: const Color(0xFF2F9E44));

/// How a place is drawn on the map and in the list.
///
/// The non-smoking map carries no category, so those venues would otherwise
/// all be grey pins; their policy is the useful thing to show instead.
({IconData icon, Color color}) placeMarkerStyle(Place place) =>
    place.category.isEmpty && place.smoking.isNotEmpty
        ? smokingStyle(place.smoking)
        : placeStyle(place.category);

/// Localization key for a category label.
String placeCategoryKey(String category) => 'place_cat_$category';

/// Localization key for a smoking policy label.
String placeSmokingKey(String smoking) => 'place_smoking_$smoking';
