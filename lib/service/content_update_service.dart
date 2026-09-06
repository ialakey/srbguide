import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pulls a newer `guide.json` between app releases.
///
/// The weekly workflow commits the re-scraped guide to `master`, so the file on
/// GitHub is always at least as fresh as the one bundled in the APK. Fetching
/// it here means a correction on srb.guide reaches users in days rather than
/// waiting for the next Play release.
///
/// Conditional on the stored `ETag`, so an unchanged guide costs one 304 and no
/// body transfer. The bundled asset stays the fallback: a failed or invalid
/// download never leaves the app without content.
class ContentUpdateService {
  ContentUpdateService._();

  static final ContentUpdateService instance = ContentUpdateService._();

  static const String _url =
      'https://raw.githubusercontent.com/ialakey/srbguide/master/assets/data/guide.json';

  static const String _etagKey = 'guideEtag';
  static const String _checkedKey = 'guideCheckedAt';
  static const String _fileName = 'guide.json';

  /// How often to look for a new guide. The content changes weekly at most.
  static const Duration _interval = Duration(hours: 24);

  /// The downloaded guide, or null when there is none / it is unusable.
  Future<String?> cachedContent() async {
    try {
      final File file = await _file();
      if (!file.existsSync()) return null;
      final String raw = await file.readAsString();
      return _isUsable(raw) ? raw : null;
    } catch (_) {
      return null;
    }
  }

  /// Checks for a newer guide unless it was checked recently.
  /// Returns true when a new version was stored.
  Future<bool> refreshIfDue({bool force = false}) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!force) {
      final DateTime? last =
          DateTime.tryParse(prefs.getString(_checkedKey) ?? '');
      if (last != null && DateTime.now().difference(last) < _interval) {
        return false;
      }
    }

    try {
      final String? etag = prefs.getString(_etagKey);
      final http.Response response = await http.get(
        Uri.parse(_url),
        headers: <String, String>{
          'User-Agent': 'srbguide-app',
          if (etag != null && !force) 'If-None-Match': etag,
        },
      ).timeout(const Duration(seconds: 45));

      // Record the attempt either way so a flaky network cannot turn into a
      // retry loop on every launch.
      await prefs.setString(_checkedKey, DateTime.now().toIso8601String());

      if (response.statusCode == 304) return false;
      if (response.statusCode != 200) return false;

      final String body = utf8.decode(response.bodyBytes);
      if (!_isUsable(body)) {
        debugPrint('Guide update rejected: failed validation');
        return false;
      }

      final File file = await _file();
      await file.parent.create(recursive: true);
      await file.writeAsString(body);

      final String? newEtag = response.headers['etag'];
      if (newEtag != null) await prefs.setString(_etagKey, newEtag);
      return true;
    } catch (e) {
      debugPrint('Guide update failed: $e');
      return false;
    }
  }

  /// Drops the downloaded copy and falls back to the bundled asset.
  Future<void> clear() async {
    try {
      final File file = await _file();
      if (file.existsSync()) await file.delete();
    } catch (_) {
      // Nothing to do — the asset is still there.
    }
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_etagKey);
    await prefs.remove(_checkedKey);
  }

  Future<DateTime?> lastCheckedAt() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return DateTime.tryParse(prefs.getString(_checkedKey) ?? '');
  }

  Future<File> _file() async {
    final Directory dir = await getApplicationSupportDirectory();
    return File('${dir.path}/$_fileName');
  }

  /// The same shape check `tool/validate_guide.dart` runs in CI, reduced to
  /// what matters on device: a truncated or rewritten file must never replace
  /// a working guide.
  static bool _isUsable(String raw) {
    try {
      final Map<String, dynamic> json_ =
          json.decode(raw) as Map<String, dynamic>;
      final List<dynamic> sections =
          (json_['ru'] ?? <dynamic>[]) as List<dynamic>;
      if (sections.length < 4) return false;

      int articles = 0;
      int chars = 0;
      for (final dynamic s in sections) {
        final List<dynamic> items = ((s as Map<String, dynamic>)['items'] ??
            <dynamic>[]) as List<dynamic>;
        for (final dynamic i in items) {
          articles++;
          chars += ((i as Map<String, dynamic>)['description'] ?? '')
              .toString()
              .length;
        }
      }
      return articles >= 40 && chars >= 300000;
    } catch (_) {
      return false;
    }
  }
}
