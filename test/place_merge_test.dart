import 'package:flutter_test/flutter_test.dart';
import 'package:srbguide/data/place.dart';

Place _place(
  String name, {
  double lat = 44.8125,
  double lng = 20.4612,
  String category = 'food',
  String smoking = '',
}) =>
    Place(
      id: name,
      name: name,
      description: '',
      lat: lat,
      lng: lng,
      category: category,
      city: 'beograd',
      opstina: '',
      mapUrl: '',
      smoking: smoking,
    );

PlaceCatalogue _catalogue(List<Place> places) => PlaceCatalogue(
      source: 'test',
      syncedAt: null,
      places: places,
    );

void main() {
  group('mergedWith', () {
    test('marks the same venue instead of adding a second pin', () {
      final PlaceCatalogue merged =
          _catalogue(<Place>[_place('Le Bol')]).mergedWith(_catalogue(<Place>[
        _place('Le Bol', category: '', smoking: 'none'),
      ]));

      expect(merged.places, hasLength(1));
      expect(merged.places.single.category, 'food');
      expect(merged.places.single.smoking, 'none');
    });

    test('matches through punctuation and case', () {
      final PlaceCatalogue merged = _catalogue(<Place>[_place('Kaži Važi')])
          .mergedWith(_catalogue(<Place>[
        _place('KAŽI VAŽI!', category: '', smoking: 'alternative'),
      ]));

      expect(merged.places, hasLength(1));
      expect(merged.places.single.smoking, 'alternative');
    });

    test('keeps a namesake in another city as its own place', () {
      // Same name, ~90 km away: two different venues.
      final PlaceCatalogue merged =
          _catalogue(<Place>[_place('Kofilin')]).mergedWith(_catalogue(<Place>[
        _place(
          'Kofilin',
          lat: 45.2551,
          lng: 19.8452,
          category: '',
          smoking: 'none',
        ),
      ]));

      expect(merged.places, hasLength(2));
      expect(merged.places.first.smoking, isEmpty);
    });

    test('never downgrades a policy already on the catalogue', () {
      final PlaceCatalogue merged =
          _catalogue(<Place>[_place('Gurme', smoking: 'none')])
              .mergedWith(_catalogue(<Place>[
        _place('Gurme', category: '', smoking: 'alternative'),
      ]));

      expect(merged.places, hasLength(1));
      expect(merged.places.single.smoking, 'none');
    });

    test('keeps the source and timestamp of the base catalogue', () {
      final PlaceCatalogue base = PlaceCatalogue(
        source: 'https://stats.srb.guide/map',
        syncedAt: DateTime.utc(2026, 9, 5),
        places: <Place>[_place('Sonder')],
      );
      final PlaceCatalogue merged = base
          .mergedWith(_catalogue(<Place>[_place('Ananda', smoking: 'none')]));

      expect(merged.source, 'https://stats.srb.guide/map');
      expect(merged.syncedAt, DateTime.utc(2026, 9, 5));
      expect(merged.places, hasLength(2));
    });

    test('an empty second catalogue changes nothing', () {
      final PlaceCatalogue base = _catalogue(<Place>[_place('Sonder')]);
      expect(base.mergedWith(PlaceCatalogue.empty), same(base));
    });
  });

  group('smokingPolicies', () {
    test('lists only the policies present, strictest first', () {
      final PlaceCatalogue catalogue = _catalogue(<Place>[
        _place('a', smoking: 'alternative'),
        _place('b'),
        _place('c', smoking: 'none'),
      ]);
      expect(catalogue.smokingPolicies, <String>['none', 'alternative']);
    });

    test('is empty for a catalogue that tracks no policy', () {
      expect(_catalogue(<Place>[_place('a')]).smokingPolicies, isEmpty);
    });
  });

  group('placeMarkerStyle', () {
    test('falls back to the smoking policy when there is no category', () {
      final Place p = _place('a', category: '', smoking: 'none');
      expect(placeMarkerStyle(p), smokingStyle('none'));
    });

    test('keeps the category icon when the venue has one', () {
      final Place p = _place('a', smoking: 'none');
      expect(placeMarkerStyle(p), placeStyle('food'));
    });
  });
}
