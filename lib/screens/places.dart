import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:srbguide/data/place.dart';
import 'package:srbguide/localization/app_localizations.dart';
import 'package:srbguide/service/url_launcher_helper.dart';
import 'package:srbguide/widget/guide_tiles.dart';

/// Map of relocant-run businesses and non-smoking venues.
///
/// Tiles come from OpenStreetMap, which needs no API key or billing account —
/// the Google Maps SDK would need both. Both catalogues are bundled, so the
/// list works with no connection and only the tiles need one.
///
/// This screen replaced the old "Maps" screen, which was a dropdown of Google
/// My Maps links in a WebView: the venues it pointed at are now pins here.
class PlacesScreen extends StatefulWidget {
  const PlacesScreen({super.key});

  @override
  State<PlacesScreen> createState() => _PlacesScreenState();
}

class _PlacesScreenState extends State<PlacesScreen> {
  /// Belgrade, where most of the catalogue is.
  static const LatLng _initialCentre = LatLng(44.8125, 20.4612);

  final MapController _map = MapController();
  final TextEditingController _search = TextEditingController();

  /// Google Maps search the old maps screen linked to. There is no bundled
  /// list of exchange offices — the search finds the ones that are open now.
  static const String _exchangeOfficesUrl =
      'https://www.google.com/maps/search/Мењачница';

  PlaceCatalogue _catalogue = PlaceCatalogue.empty;
  String? _category;
  String? _smoking;
  bool _mapView = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    _map.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final PlaceCatalogue businesses = await _asset('places.json');
      // The non-smoking map is a separate feed with its own refresh cycle, so
      // a failure there must not cost us the businesses.
      final PlaceCatalogue smoking = await _asset('smoking.json');
      if (!mounted) return;
      setState(() {
        _catalogue = businesses.mergedWith(smoking);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<PlaceCatalogue> _asset(String name) async {
    try {
      final String raw = await rootBundle.loadString('assets/data/$name');
      return PlaceCatalogue.fromJson(json.decode(raw) as Map<String, dynamic>);
    } catch (_) {
      return PlaceCatalogue.empty;
    }
  }

  List<Place> get _visible {
    final String q = _search.text.trim().toLowerCase();
    return _catalogue.places.where((Place p) {
      if (_category != null && p.category != _category) return false;
      if (_smoking != null && p.smoking != _smoking) return false;
      if (q.isNotEmpty && !p.searchIndex.contains(q)) return false;
      return true;
    }).toList();
  }

  void _openPlace(Place place) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => _PlaceSheet(place: place),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final List<Place> visible = _visible;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('places')),
        actions: <Widget>[
          IconButton(
            tooltip: _mapView
                ? l10n.translate('list_view')
                : l10n.translate('map_view'),
            icon: Icon(_mapView ? Icons.list : Icons.map_outlined),
            onPressed: () => setState(() => _mapView = !_mapView),
          ),
          IconButton(
            tooltip: l10n.translate('exchange_offices'),
            icon: const Icon(Icons.currency_exchange),
            onPressed: () => UrlLauncherHelper.launchURL(_exchangeOfficesUrl),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: TextField(
                    controller: _search,
                    decoration: InputDecoration(
                      hintText: l10n.translate('search_places'),
                      prefixIcon: const Icon(Icons.search),
                      isDense: true,
                      suffixIcon: _search.text.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                _search.clear();
                                setState(() {});
                              },
                            ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(l10n.translate('all')),
                          selected: _category == null && _smoking == null,
                          onSelected: (_) => setState(() {
                            _category = null;
                            _smoking = null;
                          }),
                        ),
                      ),
                      // Smoking first: it is the one filter people come to the
                      // map with rather than browse by.
                      ..._catalogue.smokingPolicies.map(
                        (String v) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            avatar: Icon(
                              smokingStyle(v).icon,
                              size: 16,
                              color: smokingStyle(v).color,
                            ),
                            label: Text(l10n.translate(placeSmokingKey(v))),
                            selected: _smoking == v,
                            onSelected: (bool on) => setState(() {
                              _smoking = on ? v : null;
                              _category = null;
                            }),
                          ),
                        ),
                      ),
                      ..._catalogue.categories.map(
                        (String c) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            avatar: Icon(
                              placeStyle(c).icon,
                              size: 16,
                              color: placeStyle(c).color,
                            ),
                            label: Text(l10n.translate(placeCategoryKey(c))),
                            selected: _category == c,
                            onSelected: (bool on) => setState(() {
                              _category = on ? c : null;
                              _smoking = null;
                            }),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
                  child: Row(
                    children: <Widget>[
                      Text(
                        '${visible.length} ${l10n.translate('places_count')}',
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _mapView
                      ? _MapView(
                          controller: _map,
                          centre: _initialCentre,
                          places: visible,
                          onTap: _openPlace,
                        )
                      : _ListView(places: visible, onTap: _openPlace),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                  child: Text(
                    l10n.translate('places_source'),
                    style: TextStyle(
                      fontSize: 10.5,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _MapView extends StatelessWidget {
  final MapController controller;
  final LatLng centre;
  final List<Place> places;
  final ValueChanged<Place> onTap;

  const _MapView({
    required this.controller,
    required this.centre,
    required this.places,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: controller,
      options: MapOptions(
        initialCenter: centre,
        initialZoom: 12,
        minZoom: 6,
        maxZoom: 18,
        // Serbia plus a margin, so panning cannot get lost at sea.
        cameraConstraint: CameraConstraint.contain(
          bounds: LatLngBounds(
            const LatLng(41.5, 18.0),
            const LatLng(47.0, 23.5),
          ),
        ),
      ),
      children: <Widget>[
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          // OSM's tile policy requires identifying the client.
          userAgentPackageName: 'com.alakey.serbiaguide',
          maxZoom: 19,
        ),
        MarkerLayer(
          markers: places
              .map(
                (Place p) => Marker(
                  point: LatLng(p.lat, p.lng),
                  width: 34,
                  height: 34,
                  child: _Pin(place: p, onTap: () => onTap(p)),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _Pin extends StatelessWidget {
  final Place place;
  final VoidCallback onTap;

  const _Pin({required this.place, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ({IconData icon, Color color}) style = placeMarkerStyle(place);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: style.color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(style.icon, size: 17, color: Colors.white),
      ),
    );
  }
}

class _ListView extends StatelessWidget {
  final List<Place> places;
  final ValueChanged<Place> onTap;

  const _ListView({required this.places, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    if (places.isEmpty) {
      return EmptyState(
        icon: Icons.search_off,
        message: l10n.translate('no_places_found'),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      itemCount: places.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (BuildContext context, int i) {
        final Place p = places[i];
        final ({IconData icon, Color color}) style = placeMarkerStyle(p);
        return Card(
          child: InkWell(
            onTap: () => onTap(p),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: style.color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(style.icon, size: 19, color: style.color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          p.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (p.opstina.isNotEmpty) ...<Widget>[
                          const SizedBox(height: 2),
                          Text(
                            p.opstina,
                            style: TextStyle(
                              fontSize: 12,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        if (p.smoking.isNotEmpty) ...<Widget>[
                          const SizedBox(height: 6),
                          _SmokingBadge(smoking: p.smoking),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PlaceSheet extends StatelessWidget {
  final Place place;

  const _PlaceSheet({required this.place});

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final ({IconData icon, Color color}) style = placeMarkerStyle(place);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: style.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(style.icon, color: style.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      place.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (place.opstina.isNotEmpty)
                      Text(
                        place.opstina,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (place.smoking.isNotEmpty) ...<Widget>[
            const SizedBox(height: 14),
            _SmokingBadge(smoking: place.smoking),
          ],
          if (place.description.isNotEmpty) ...<Widget>[
            const SizedBox(height: 14),
            Text(
              place.description,
              style: const TextStyle(fontSize: 14, height: 1.45),
            ),
          ],
          if (place.mapUrl.isNotEmpty) ...<Widget>[
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () => UrlLauncherHelper.launchURL(place.mapUrl),
              icon: const Icon(Icons.directions),
              label: Text(l10n.translate('open_in_maps')),
            ),
          ],
        ],
      ),
    );
  }
}

/// Marks what the non-smoking map says about a venue.
class _SmokingBadge extends StatelessWidget {
  final String smoking;

  const _SmokingBadge({required this.smoking});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final ({IconData icon, Color color}) style = smokingStyle(smoking);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: style.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(style.icon, size: 14, color: style.color),
          const SizedBox(width: 5),
          Text(
            l10n.translate(placeSmokingKey(smoking)),
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: style.color,
            ),
          ),
        ],
      ),
    );
  }
}
