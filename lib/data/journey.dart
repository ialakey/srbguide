import 'package:shared_preferences/shared_preferences.dart';

import 'package:srbguide/data/guide_dto.dart';
import 'package:srbguide/data/guide_repository.dart';

/// One step of the relocation checklist, backed by a guide article.
class JourneyStep {
  /// Article slug on srb.guide, e.g. `personal/beli-karton`. Matched against
  /// the article's source URL so steps survive the guide being re-scraped.
  final String slug;

  /// The article this step explains, once resolved against the guide.
  final GuideArticle? article;

  final bool done;

  const JourneyStep({
    required this.slug,
    required this.article,
    required this.done,
  });

  String get title => article?.title ?? slug;

  String get smile => article?.smile ?? '•';
}

/// A phase of the move, e.g. "First days".
class JourneyStage {
  final String titleKey;
  final List<JourneyStep> steps;

  const JourneyStage({required this.titleKey, required this.steps});

  int get doneCount => steps.where((JourneyStep s) => s.done).length;
}

/// The relocation checklist.
///
/// The guide is a set of articles; the order in which you actually have to do
/// things is knowledge that lives on srb.guide's homepage and in people's
/// heads. This encodes it so a newcomer can see what to do next instead of
/// guessing which of 74 articles applies today.
class JourneyRepository {
  JourneyRepository._();

  static final JourneyRepository instance = JourneyRepository._();

  static const String _key = 'journeyDoneSlugs';

  /// Stage -> ordered article slugs. Slugs, not titles, because titles change.
  static const Map<String, List<String>> plan = <String, List<String>>{
    'journey_stage_before': <String>[
      'prologue/prepare',
      'prologue/flight-tickets',
      'personal/visa-calculator',
    ],
    'journey_stage_first_days': <String>[
      'personal/beli-karton',
      'personal/rent',
      'personal/mobile',
      'banks/exchange',
      'personal/public-transport',
    ],
    'journey_stage_basis': <String>[
      'prologue/forms-of-entrepreneurship',
      'business/open',
      'business/accountant',
      'business/tax',
    ],
    'journey_stage_bank': <String>[
      'banks/who-opens',
      'banks/general',
      'personal/izjava',
    ],
    'journey_stage_residence': <String>[
      'temporary-residence/insurance',
      'personal/eid-gov',
      'temporary-residence/online',
      'temporary-residence/offline',
      'temporary-residence/id-card',
    ],
    'journey_stage_after': <String>[
      'personal/state-insurance',
      'business/electron-signature',
      'business/eporezi',
      'vozila/replacing-driving-license',
    ],
  };

  Future<Set<String>> doneSlugs() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_key) ?? <String>[]).toSet();
  }

  Future<Set<String>> toggle(String slug) async {
    final Set<String> done = await doneSlugs();
    if (!done.add(slug)) done.remove(slug);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, done.toList());
    return done;
  }

  Future<void> reset() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  /// Builds the checklist, resolving each slug against the bundled guide.
  /// Steps whose article no longer exists are dropped rather than shown broken.
  Future<List<JourneyStage>> stages() async {
    final GuideContent content = await GuideRepository.instance.load();
    final Set<String> done = await doneSlugs();

    final Map<String, GuideArticle> bySlug = <String, GuideArticle>{
      for (final GuideArticle a in content.allArticles)
        if (_slugOf(a.source) != null) _slugOf(a.source)!: a,
    };

    final List<JourneyStage> result = <JourneyStage>[];
    plan.forEach((String stage, List<String> slugs) {
      final List<JourneyStep> steps = <JourneyStep>[];
      for (final String slug in slugs) {
        final GuideArticle? article = bySlug[slug];
        if (article == null) continue;
        steps.add(JourneyStep(
          slug: slug,
          article: article,
          done: done.contains(slug),
        ));
      }
      if (steps.isNotEmpty) {
        result.add(JourneyStage(titleKey: stage, steps: steps));
      }
    });
    return result;
  }

  /// `https://www.srb.guide/guides/personal/beli-karton/` -> `personal/beli-karton`
  static String? _slugOf(String source) {
    if (source.isEmpty) return null;
    final List<String> parts = Uri.parse(source)
        .pathSegments
        .where((String p) => p.isNotEmpty)
        .toList();
    if (parts.length < 3 || parts.first != 'guides') return null;
    return '${parts[1]}/${parts[2]}';
  }

  /// Convenience for the home screen progress card.
  Future<({int done, int total})> progress() async {
    final List<JourneyStage> all = await stages();
    int done = 0;
    int total = 0;
    for (final JourneyStage s in all) {
      done += s.doneCount;
      total += s.steps.length;
    }
    return (done: done, total: total);
  }
}
