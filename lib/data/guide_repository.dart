import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:srbguide/data/guide_dto.dart';
import 'package:srbguide/service/content_update_service.dart';
import 'package:srbguide/utils/search_stem.dart';

/// Loads the bundled guide once and serves it to every screen.
///
/// `assets/data/guide.json` is a couple of megabytes, so it is decoded a single
/// time and cached; the old code re-read and re-parsed it on every screen that
/// needed it.
class GuideRepository {
  GuideRepository._();

  static final GuideRepository instance = GuideRepository._();

  static const String _favouritesKey = 'favouriteArticleIds';
  static const String _legacyFavouritesKey = 'favorites';

  Future<GuideContent>? _pending;
  GuideContent? _cache;

  GuideContent get cachedOrEmpty => _cache ?? GuideContent.empty;

  Future<GuideContent> load() {
    final GuideContent? cached = _cache;
    if (cached != null) return Future<GuideContent>.value(cached);
    return _pending ??= _read();
  }

  Future<GuideContent> _read() async {
    // A guide downloaded since the last release wins over the bundled copy;
    // the asset is the fallback when there is none or it failed validation.
    String raw = '';
    try {
      raw = await ContentUpdateService.instance.cachedContent() ?? '';
    } catch (_) {
      raw = '';
    }
    if (raw.isEmpty) {
      raw = await rootBundle.loadString('assets/data/guide.json');
    }

    final GuideContent content = GuideContent.fromJson(
      json.decode(raw) as Map<String, dynamic>,
    );
    _cache = content;
    _pending = null;
    return content;
  }

  /// Forgets the parsed guide so the next [load] re-reads it. Used after a
  /// content update lands.
  void invalidate() {
    _cache = null;
    _pending = null;
  }

  /// Search across titles, summaries and body text.
  ///
  /// Terms are stemmed (see `utils/search_stem.dart`) so Russian inflection
  /// does not hide results, and every term has to match — typing two words
  /// should narrow the list, not widen it.
  List<SearchHit> search(
    GuideContent content,
    String query, {
    String? sectionSlug,
  }) {
    final List<String> terms = stemQuery(query);
    if (terms.isEmpty) return const <SearchHit>[];

    final List<SearchHit> hits = <SearchHit>[];
    for (final GuideArticle a in content.allArticles) {
      if (sectionSlug != null && a.sectionSlug != sectionSlug) continue;

      final String title = a.lowerTitle;
      final String lead = a.lowerLead;
      final String body = a.lowerBody;

      if (!terms.every((String t) =>
          title.contains(t) || lead.contains(t) || body.contains(t))) {
        continue;
      }

      // Rank by where the first term matched: a title hit is almost always
      // what the user meant.
      final int rank = title.contains(terms.first)
          ? 0
          : lead.contains(terms.first)
              ? 1
              : 2;

      hits.add(SearchHit(
        article: a,
        rank: rank,
        snippet: rank == 2 ? _snippet(a.description, terms.first) : a.lead,
      ));
    }

    hits.sort((SearchHit a, SearchHit b) {
      final int byRank = a.rank.compareTo(b.rank);
      return byRank != 0 ? byRank : a.article.title.compareTo(b.article.title);
    });
    return hits;
  }

  /// A short window of body text around [term], so a body-only hit shows why
  /// it matched instead of an unrelated summary.
  static String _snippet(String body, String term, {int radius = 60}) {
    final int at = body.toLowerCase().indexOf(term);
    if (at == -1) return '';
    final int start = (at - radius).clamp(0, body.length);
    final int end = (at + term.length + radius).clamp(0, body.length);
    final String cut = body
        .substring(start, end)
        .replaceAll(RegExp(r'[#>*`|]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return '${start > 0 ? '…' : ''}$cut${end < body.length ? '…' : ''}';
  }

  // --- Favourites ----------------------------------------------------------

  Future<Set<String>> favouriteIds() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String>? stored = prefs.getStringList(_favouritesKey);
    if (stored != null) return stored.toSet();

    // One-time migration: favourites used to be a {title: content} map, which
    // broke as soon as the article text changed. Match the old titles against
    // the current guide and store stable ids instead.
    final Set<String> migrated = await _migrateLegacyFavourites(prefs);
    await prefs.setStringList(_favouritesKey, migrated.toList());
    return migrated;
  }

  Future<Set<String>> _migrateLegacyFavourites(SharedPreferences prefs) async {
    final String? legacy = prefs.getString(_legacyFavouritesKey);
    if (legacy == null || legacy.isEmpty) return <String>{};

    Map<String, dynamic> decoded;
    try {
      decoded = json.decode(legacy) as Map<String, dynamic>;
    } catch (_) {
      return <String>{};
    }

    final GuideContent content = await load();
    final Set<String> ids = <String>{};
    for (final String oldTitle in decoded.keys) {
      final String needle =
          oldTitle.replaceAll(RegExp(r'^\W+'), '').trim().toLowerCase();
      for (final GuideArticle a in content.allArticles) {
        if (a.title.toLowerCase() == needle) {
          ids.add(a.id);
          break;
        }
      }
    }
    return ids;
  }

  Future<bool> isFavourite(String id) async =>
      (await favouriteIds()).contains(id);

  /// Adds or removes [id]; returns the new state.
  Future<bool> toggleFavourite(String id) async {
    final Set<String> ids = await favouriteIds();
    final bool added = ids.add(id);
    if (!added) ids.remove(id);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_favouritesKey, ids.toList());
    return added;
  }

  Future<List<GuideArticle>> favouriteArticles() async {
    final GuideContent content = await load();
    final Set<String> ids = await favouriteIds();
    return content.allArticles
        .where((GuideArticle a) => ids.contains(a.id))
        .toList();
  }

  // --- Reading progress ----------------------------------------------------

  static const String _recentKey = 'recentArticleIds';

  Future<void> markOpened(String id) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> recent = prefs.getStringList(_recentKey) ?? <String>[];
    recent.remove(id);
    recent.insert(0, id);
    await prefs.setStringList(_recentKey, recent.take(12).toList());
  }

  Future<List<GuideArticle>> recentArticles({int limit = 5}) async {
    final GuideContent content = await load();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> recent = prefs.getStringList(_recentKey) ?? <String>[];
    final Map<String, GuideArticle> byId = <String, GuideArticle>{
      for (final GuideArticle a in content.allArticles) a.id: a,
    };
    return recent
        .map((String id) => byId[id])
        .whereType<GuideArticle>()
        .take(limit)
        .toList();
  }
}

/// One search result, with the reason it matched.
class SearchHit {
  final GuideArticle article;

  /// 0 = title match, 1 = summary match, 2 = body match.
  final int rank;

  /// Text to show under the title: the summary, or a window of body text.
  final String snippet;

  const SearchHit({
    required this.article,
    required this.rank,
    required this.snippet,
  });
}
