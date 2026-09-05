// Sanity-checks `assets/data/guide.json` before it is committed.
//
//   dart run tool/validate_guide.dart
//   dart run tool/validate_guide.dart --baseline /tmp/previous-guide.json
//
// The weekly sync workflow commits scraped third-party content without a human
// looking at it. If srb.guide changes its markup, `tool/sync_guide.dart` can
// still "succeed" while producing near-empty articles — this is the gate that
// stops that from shipping. Exits non-zero with a readable reason on failure.

import 'dart:convert';
import 'dart:io';

/// Absolute floors. Well below today's numbers (8 sections / 74 articles) so
/// normal editing on the site never trips them.
const int kMinSections = 6;
const int kMinArticles = 50;
const int kMinArticleChars = 200;
const int kMinTotalChars = 500000;

/// How much smaller than the previous version the guide may get before we
/// treat it as a broken scrape rather than an edit.
const double kMaxShrinkRatio = 0.75;

Future<void> main(List<String> args) async {
  final String path = _arg(args, '--path') ?? 'assets/data/guide.json';
  final String? baseline = _arg(args, '--baseline');

  final List<String> problems = <String>[];
  final List<String> notes = <String>[];

  final File file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('FAIL: $path does not exist');
    exit(1);
  }

  Map<String, dynamic> data;
  try {
    data = json.decode(await file.readAsString()) as Map<String, dynamic>;
  } catch (e) {
    stderr.writeln('FAIL: $path is not valid JSON: $e');
    exit(1);
  }

  final List<dynamic> sections = (data['ru'] ?? <dynamic>[]) as List<dynamic>;
  if (sections.length < kMinSections) {
    problems
        .add('only ${sections.length} sections (expected >= $kMinSections)');
  }

  int articles = 0;
  int totalChars = 0;
  final List<String> thin = <String>[];
  final Set<String> ids = <String>{};

  for (final dynamic rawSection in sections) {
    final Map<String, dynamic> section = rawSection as Map<String, dynamic>;
    final String sectionTitle = (section['group'] ?? '?') as String;
    if (sectionTitle.trim().isEmpty) {
      problems.add('a section has an empty title');
    }
    final List<dynamic> items =
        (section['items'] ?? <dynamic>[]) as List<dynamic>;
    if (items.isEmpty) problems.add('section "$sectionTitle" has no articles');

    for (final dynamic rawItem in items) {
      final Map<String, dynamic> item = rawItem as Map<String, dynamic>;
      articles++;
      final String title = (item['title'] ?? '') as String;
      final String body = (item['description'] ?? '') as String;
      final String source = (item['source'] ?? '') as String;

      if (title.trim().isEmpty) {
        problems.add('an article in "$sectionTitle" has no title');
      }
      if (source.isEmpty) {
        problems.add('article "$title" has no source URL');
      } else if (!ids.add(source)) {
        problems.add('duplicate source URL: $source');
      }
      if (body.length < kMinArticleChars) {
        thin.add('$title (${body.length} chars)');
      }
      totalChars += body.length;
    }
  }

  if (articles < kMinArticles) {
    problems.add('only $articles articles (expected >= $kMinArticles)');
  }
  if (totalChars < kMinTotalChars) {
    problems.add('only $totalChars chars of content '
        '(expected >= $kMinTotalChars)');
  }
  if (thin.isNotEmpty) {
    problems.add('${thin.length} suspiciously short article(s): '
        '${thin.take(5).join(', ')}');
  }

  if (baseline != null && File(baseline).existsSync()) {
    try {
      final Map<String, dynamic> old = json
          .decode(await File(baseline).readAsString()) as Map<String, dynamic>;
      int oldChars = 0;
      int oldArticles = 0;
      for (final dynamic s in (old['ru'] ?? <dynamic>[]) as List<dynamic>) {
        for (final dynamic i in ((s as Map<String, dynamic>)['items'] ??
            <dynamic>[]) as List<dynamic>) {
          oldArticles++;
          oldChars += ((i as Map<String, dynamic>)['description'] ?? '')
              .toString()
              .length;
        }
      }
      notes.add('baseline: $oldArticles articles, $oldChars chars');
      if (oldChars > 0 && totalChars < oldChars * kMaxShrinkRatio) {
        problems.add('content shrank from $oldChars to $totalChars chars '
            '(more than ${((1 - kMaxShrinkRatio) * 100).round()}%)');
      }
      if (oldArticles > 0 && articles < oldArticles - 5) {
        problems.add('article count dropped from $oldArticles to $articles');
      }
    } catch (e) {
      notes.add('baseline could not be read ($e) — skipping comparison');
    }
  }

  stdout.writeln('sections: ${sections.length}');
  stdout.writeln('articles: $articles');
  stdout.writeln('content:  $totalChars chars');
  for (final String n in notes) {
    stdout.writeln('note:     $n');
  }

  if (problems.isEmpty) {
    stdout.writeln('OK: guide.json looks healthy');
    return;
  }
  stderr.writeln('\nFAIL: guide.json did not pass validation:');
  for (final String p in problems) {
    stderr.writeln('  - $p');
  }
  exit(1);
}

String? _arg(List<String> args, String flag) {
  final int i = args.indexOf(flag);
  if (i == -1 || i + 1 >= args.length) return null;
  return args[i + 1];
}
