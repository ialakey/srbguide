/// Guide content model.
///
/// The JSON is produced by `tool/sync_guide.dart` from srb.guide and bundled
/// as `assets/data/guide.json`, so the app works with no network at all.
class GuideArticle {
  // Note: not `const` — the lowercase caches below are filled lazily.
  /// Leading emoji from the article title, e.g. `📇`.
  final String smile;

  /// Title without the emoji.
  final String title;

  /// One-sentence summary shown under the title and on list rows.
  final String lead;

  /// Full article body in Markdown.
  final String description;

  /// Canonical URL on srb.guide. Doubles as this article's stable id.
  final String source;

  /// Human-readable last-modified date from the site, e.g. `August 31, 2026`.
  final String updated;

  /// Title of the section this article belongs to, filled in on load.
  final String sectionTitle;

  /// Section slug, e.g. `personal`.
  final String sectionSlug;

  GuideArticle({
    required this.smile,
    required this.title,
    required this.lead,
    required this.description,
    required this.source,
    required this.updated,
    required this.sectionTitle,
    required this.sectionSlug,
  });

  /// Stable identifier used for favourites and deep links.
  String get id => source.isNotEmpty ? source : '$sectionSlug/$title';

  String get displayTitle => smile.isEmpty ? title : '$smile $title';

  factory GuideArticle.fromJson(
    Map<String, dynamic> json, {
    required String sectionTitle,
    required String sectionSlug,
  }) {
    return GuideArticle(
      smile: (json['smile'] ?? '') as String,
      title: (json['title'] ?? '') as String,
      lead: (json['lead'] ?? '') as String,
      description: (json['description'] ?? '') as String,
      source: (json['source'] ?? '') as String,
      updated: (json['updated'] ?? '') as String,
      sectionTitle: sectionTitle,
      sectionSlug: sectionSlug,
    );
  }

  /// Lowercased title/summary/body, built once and reused.
  ///
  /// Search runs on every keystroke; lowercasing 1.5 MB of article text each
  /// time made typing stutter. These are computed on first use and then held
  /// for the life of the (cached) article.
  String get lowerTitle => _lowerTitle ??= title.toLowerCase();
  String get lowerLead => _lowerLead ??= lead.toLowerCase();
  String get lowerBody => _lowerBody ??= description.toLowerCase();

  String? _lowerTitle;
  String? _lowerLead;
  String? _lowerBody;

  /// Lowercased haystack used when matching across every field at once.
  String get searchIndex =>
      '$lowerTitle $lowerLead ${sectionTitle.toLowerCase()} $lowerBody';
}

/// A top-level group of articles, e.g. "🏦 Банки".
class GuideSection {
  final String slug;
  final String title;
  final String smile;

  /// Icon key mapped to a Material icon by `lib/utils/guide_icons.dart`.
  final String icon;

  final List<GuideArticle> items;

  const GuideSection({
    required this.slug,
    required this.title,
    required this.smile,
    required this.icon,
    required this.items,
  });

  factory GuideSection.fromJson(Map<String, dynamic> json) {
    final String title = (json['group'] ?? '') as String;
    final String slug = (json['slug'] ?? title) as String;
    final List<dynamic> raw = (json['items'] ?? <dynamic>[]) as List<dynamic>;
    return GuideSection(
      slug: slug,
      title: title,
      smile: (json['smile'] ?? '') as String,
      icon: (json['icon'] ?? 'article') as String,
      items: raw
          .cast<Map<String, dynamic>>()
          .map((Map<String, dynamic> e) => GuideArticle.fromJson(
                e,
                sectionTitle: title,
                sectionSlug: slug,
              ))
          .toList(),
    );
  }
}

/// The whole guide plus provenance for the attribution shown in the UI.
class GuideContent {
  /// Site the content came from, e.g. `https://www.srb.guide`.
  final String source;

  /// When `tool/sync_guide.dart` last regenerated the bundle.
  final DateTime? syncedAt;

  final List<GuideSection> sections;

  const GuideContent({
    required this.source,
    required this.syncedAt,
    required this.sections,
  });

  static const GuideContent empty =
      GuideContent(source: '', syncedAt: null, sections: <GuideSection>[]);

  List<GuideArticle> get allArticles =>
      sections.expand((GuideSection s) => s.items).toList();

  factory GuideContent.fromJson(Map<String, dynamic> json) {
    final List<dynamic> raw = (json['ru'] ?? <dynamic>[]) as List<dynamic>;
    return GuideContent(
      source: (json['source'] ?? 'https://www.srb.guide') as String,
      syncedAt: DateTime.tryParse((json['syncedAt'] ?? '') as String),
      sections:
          raw.cast<Map<String, dynamic>>().map(GuideSection.fromJson).toList(),
    );
  }
}
