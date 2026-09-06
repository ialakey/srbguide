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

/// Localization key for a category label.
String placeCategoryKey(String category) => 'place_cat_$category';
