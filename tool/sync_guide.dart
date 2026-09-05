// Regenerates `assets/data/guide.json` from https://www.srb.guide/.
//
//   dart run tool/sync_guide.dart
//   dart run tool/sync_guide.dart --out assets/data/guide.json --limit 5
//
// The guide is authored on srb.guide and mirrored into the app so it works
// offline. This tool re-scrapes it, converts each article to Markdown and
// records the source URL and last-modified date so every screen can credit the
// original. Run it whenever the site is updated, then ship a new release.
//
// It deliberately runs at build time rather than on-device: the app stays
// fully offline and a markup change on the site can never break a user's app,
// only this script.

import 'dart:convert';
import 'dart:io';

import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

const String kSite = 'https://www.srb.guide';
const String kDefaultOut = 'assets/data/guide.json';

/// Section slug -> icon key understood by the app (see `lib/utils/guide_icons.dart`)
/// and the order sections appear in. Titles/emoji come from the site itself.
const Map<String, String> kSectionIcons = <String, String>{
  'prologue': 'luggage',
  'personal': 'person',
  'banks': 'bank',
  'temporary-residence': 'home',
  'permanent-residence': 'verified',
  'business': 'work',
  'medicine': 'health',
  'vozila': 'car',
};

const List<String> kSectionOrder = <String>[
  'prologue',
  'personal',
  'banks',
  'temporary-residence',
  'permanent-residence',
  'business',
  'medicine',
  'vozila',
];

Future<void> main(List<String> args) async {
  final String out = _argValue(args, '--out') ?? kDefaultOut;
  final int? limit = int.tryParse(_argValue(args, '--limit') ?? '');

  stdout.writeln('Collecting guide URLs…');
  final List<String> urls = await _collectGuideUrls();
  final List<String> selected =
      limit == null ? urls : urls.take(limit).toList();
  stdout.writeln('  ${selected.length} pages');

  final Map<String, _Section> sections = <String, _Section>{};
  int index = 0;
  for (final String url in selected) {
    index++;
    stdout.write('  [$index/${selected.length}] $url … ');
    try {
      final _Article article = await _fetchArticle(url);
      final _Section section = sections.putIfAbsent(
        article.sectionSlug,
        () => _Section(
          slug: article.sectionSlug,
          title: article.sectionTitle,
          smile: article.sectionSmile,
        ),
      );
      section.items.add(article);
      stdout.writeln('ok (${article.description.length} chars)');
    } catch (e) {
      stdout.writeln('FAILED: $e');
      exitCode = 1;
    }
    // Be a polite scraper — this is someone else's site.
    await Future<void>.delayed(const Duration(milliseconds: 350));
  }

  final List<Map<String, Object?>> groups = <Map<String, Object?>>[];
  final List<String> orderedSlugs = <String>[
    ...kSectionOrder.where(sections.containsKey),
    ...sections.keys.where((String s) => !kSectionOrder.contains(s)),
  ];
  for (final String slug in orderedSlugs) {
    final _Section section = sections[slug]!;
    groups.add(<String, Object?>{
      'slug': section.slug,
      'group': section.title,
      'smile': section.smile,
      'icon': kSectionIcons[section.slug] ?? 'article',
      'items': section.items
          .map((_Article a) => <String, Object?>{
                'smile': a.smile,
                'title': a.title,
                'lead': a.lead,
                'description': a.description,
                'source': a.source,
                'updated': a.updated,
              })
          .toList(),
    });
  }

  final Map<String, Object?> payload = <String, Object?>{
    'source': kSite,
    'syncedAt': DateTime.now().toUtc().toIso8601String(),
    'ru': groups,
  };

  final File file = File(out);
  await file.parent.create(recursive: true);
  await file.writeAsString(
    const JsonEncoder.withIndent('  ').convert(payload),
    encoding: utf8,
  );

  final int items = groups.fold<int>(
      0,
      (int sum, Map<String, Object?> g) =>
          sum + (g['items']! as List<Object?>).length);
  stdout.writeln('Wrote $out — ${groups.length} sections, $items articles.');
}

String? _argValue(List<String> args, String flag) {
  final int i = args.indexOf(flag);
  if (i == -1 || i + 1 >= args.length) return null;
  return args[i + 1];
}

/// Guide URLs in the order the site presents them on the homepage, with any
/// pages that only appear in the sitemap appended.
Future<List<String>> _collectGuideUrls() async {
  final List<String> ordered = <String>[];

  final Document home = html_parser.parse(await _get('$kSite/'));
  for (final Element a in home.querySelectorAll('a')) {
    final String href = a.attributes['href'] ?? '';
    final String? url = _normalizeGuideUrl(href);
    if (url != null && !ordered.contains(url)) ordered.add(url);
  }

  final String sitemap = await _get('$kSite/sitemap.xml');
  final Iterable<RegExpMatch> locs =
      RegExp(r'<loc>(.*?)</loc>').allMatches(sitemap);
  final List<String> extra = <String>[];
  for (final RegExpMatch m in locs) {
    final String? url = _normalizeGuideUrl(m.group(1)!);
    if (url != null && !ordered.contains(url) && !extra.contains(url)) {
      extra.add(url);
    }
  }
  extra.sort();

  return <String>[...ordered, ...extra];
}

/// Returns a canonical `https://www.srb.guide/guides/<section>/<slug>/` URL,
/// or null when [href] is not an article (index pages, anchors, other sites).
String? _normalizeGuideUrl(String href) {
  if (href.isEmpty) return null;
  String path = href;
  if (path.startsWith(kSite)) path = path.substring(kSite.length);
  if (path.startsWith('http')) return null;
  final int hash = path.indexOf('#');
  if (hash != -1) path = path.substring(0, hash);
  if (!path.startsWith('/guides/')) return null;
  final List<String> parts =
      path.split('/').where((String p) => p.isNotEmpty).toList();
  // ['guides', section, slug]
  if (parts.length != 3) return null;
  return '$kSite/${parts.join('/')}/';
}

Future<String> _get(String url) async {
  final http.Response response = await http.get(
    Uri.parse(url),
    headers: const <String, String>{
      // srb.guide's robots.txt allows on-demand assistants; identify honestly.
      'User-Agent':
          'srbguide-app-sync/1.0 (+https://github.com/ialakey/srbguide)',
      'Accept-Language': 'ru,en;q=0.8',
    },
  ).timeout(const Duration(seconds: 30));
  if (response.statusCode != 200) {
    throw StateError('HTTP ${response.statusCode} for $url');
  }
  return utf8.decode(response.bodyBytes);
}

Future<_Article> _fetchArticle(String url) async {
  final Document doc = html_parser.parse(await _get(url));
  final Element? main = doc.querySelector('main');
  if (main == null) throw StateError('no <main>');

  final Element? h1 = main.querySelector('h1');
  if (h1 == null) throw StateError('no <h1>');
  final _TitleParts title = _splitEmoji(_text(h1));

  // Breadcrumb: Главная / <section> / <article>
  final List<Element> crumbs = main.querySelectorAll('ol.breadcrumb li');
  String sectionLabel = '';
  if (crumbs.length >= 2) sectionLabel = _text(crumbs[crumbs.length - 2]);
  final _TitleParts section = _splitEmoji(sectionLabel);

  final String slug = Uri.parse(url).pathSegments.length >= 2
      ? Uri.parse(url).pathSegments[1]
      : 'other';

  final Element? lead = main.querySelector('p.lead');
  final Element? modified = main.querySelector('.last-modified');

  final StringBuffer body = StringBuffer();
  for (final Element child in main.children) {
    if (_isChrome(child)) continue;
    final String md = _block(child);
    if (md.trim().isEmpty) continue;
    body.writeln(md.trimRight());
    body.writeln();
  }

  return _Article(
    smile: title.emoji,
    title: title.text,
    lead: lead == null ? '' : _text(lead),
    description: _tidy(body.toString()),
    source: url,
    updated: modified == null
        ? ''
        : _text(modified).replaceFirst(RegExp(r'^Обновлено\s*'), ''),
    sectionSlug: slug,
    sectionTitle: section.text.isEmpty ? slug : section.text,
    sectionSmile: section.emoji,
  );
}

/// Page furniture that is not article content.
bool _isChrome(Element el) {
  final String tag = el.localName ?? '';
  if (<String>['nav', 'aside', 'script', 'style', 'form', 'button', 'h1']
      .contains(tag)) {
    return true;
  }
  final Set<String> classes = el.classes;
  if (classes.contains('breadcrumb') ||
      classes.contains('last-modified') ||
      classes.contains('support-cta') ||
      classes.contains('page-footer-meta') ||
      classes.contains('lead')) {
    return true;
  }
  // The unclassed "support the author / report an error" block at the bottom.
  final String text = el.text;
  if (text.contains('написать автору на email') ||
      text.contains('Гайд делается на чистом энтузиазме')) {
    return true;
  }
  return false;
}

// ---------------------------------------------------------------------------
// HTML -> Markdown
// ---------------------------------------------------------------------------

String _block(Element el, {int depth = 0}) {
  final String tag = el.localName ?? '';
  switch (tag) {
    case 'h2':
      return '\n## ${_inlineOf(el)}\n';
    case 'h3':
      return '\n### ${_inlineOf(el)}\n';
    case 'h4':
    case 'h5':
    case 'h6':
      return '\n#### ${_inlineOf(el)}\n';
    case 'p':
      final String t = _inlineOf(el);
      return t.isEmpty ? '' : '$t\n';
    case 'ul':
    case 'ol':
      return _list(el, ordered: tag == 'ol', depth: depth);
    case 'table':
      return _table(el);
    case 'pre':
      return '\n```\n${el.text.trim()}\n```\n';
    case 'blockquote':
      return _quote(_children(el, depth: depth));
    case 'details':
      return _details(el, depth: depth);
    case 'figure':
      return _figure(el);
    case 'iframe':
      final String src = _absolute(el.attributes['src'] ?? '');
      return src.isEmpty ? '' : '\n[▶️ Видео]($src)\n';
    case 'img':
      return _image(el);
    case 'br':
      return '\n';
    case 'hr':
      return '\n---\n';
    case 'div':
    case 'section':
    case 'center':
    case 'article':
      if (el.classes.any((String c) => c.startsWith('alert'))) {
        return _quote(_children(el, depth: depth), marker: _alertMarker(el));
      }
      return _children(el, depth: depth);
    default:
      return _children(el, depth: depth);
  }
}

String _children(Element el, {int depth = 0}) {
  final StringBuffer out = StringBuffer();
  final StringBuffer inline = StringBuffer();

  void flushInline() {
    final String t = _collapse(inline.toString());
    if (t.isNotEmpty) out.writeln('$t\n');
    inline.clear();
  }

  for (final Node node in el.nodes) {
    if (node is Text) {
      inline.write(node.text);
    } else if (node is Element) {
      if (_isBlockLevel(node)) {
        flushInline();
        final String md = _block(node, depth: depth);
        if (md.trim().isNotEmpty) out.writeln(md.trimRight());
      } else {
        inline.write(_inline(node));
      }
    }
  }
  flushInline();
  return out.toString();
}

const Set<String> _blockTags = <String>{
  'p',
  'div',
  'ul',
  'ol',
  'table',
  'h1',
  'h2',
  'h3',
  'h4',
  'h5',
  'h6',
  'blockquote',
  'pre',
  'details',
  'figure',
  'section',
  'article',
  'center',
  'iframe',
  'hr',
  'nav',
  'aside',
  'li',
};

bool _isBlockLevel(Element el) => _blockTags.contains(el.localName);

/// Renders inline content of [el] (links, emphasis, code, images).
String _inlineOf(Element el) {
  final StringBuffer sb = StringBuffer();
  for (final Node node in el.nodes) {
    if (node is Text) {
      sb.write(node.text);
    } else if (node is Element) {
      sb.write(_inline(node));
    }
  }
  return _collapse(sb.toString());
}

String _inline(Element el) {
  final String tag = el.localName ?? '';
  switch (tag) {
    case 'a':
      // Heading anchor links render as a bare "#" — drop them.
      if (el.classes.contains('anchor')) return '';
      final String text = _inlineOf(el);
      if (text.isEmpty || text == '#') return '';
      final String href = _absolute(el.attributes['href'] ?? '');
      if (href.isEmpty) return text;
      return '[$text]($href)';
    case 'strong':
    case 'b':
      final String t = _inlineOf(el);
      return t.isEmpty ? '' : '**$t**';
    case 'em':
    case 'i':
      final String t = _inlineOf(el);
      return t.isEmpty ? '' : '*$t*';
    case 'code':
      final String t = el.text.trim();
      return t.isEmpty ? '' : '`$t`';
    case 'br':
      return '\n';
    case 'img':
      return _image(el).trim();
    case 'svg':
      return '';
    default:
      return _inlineOf(el);
  }
}

String _list(Element el, {required bool ordered, int depth = 0}) {
  final StringBuffer sb = StringBuffer();
  final String pad = '  ' * depth;
  int n = 0;
  for (final Element li in el.children) {
    if (li.localName != 'li') continue;
    n++;
    final String marker = ordered ? '$n.' : '-';

    // Split the item into its own inline text and any nested lists/blocks.
    final StringBuffer inline = StringBuffer();
    final StringBuffer nested = StringBuffer();
    for (final Node node in li.nodes) {
      if (node is Text) {
        inline.write(node.text);
      } else if (node is Element) {
        if (node.localName == 'ul' || node.localName == 'ol') {
          nested.write(
              _list(node, ordered: node.localName == 'ol', depth: depth + 1));
        } else if (_isBlockLevel(node)) {
          nested.write(_indent(_block(node, depth: depth + 1), '$pad  '));
        } else {
          inline.write(_inline(node));
        }
      }
    }

    final String text = _collapse(inline.toString());
    if (text.isEmpty && nested.isEmpty) continue;
    sb.writeln('$pad$marker $text'.trimRight());
    if (nested.isNotEmpty) sb.write(nested.toString());
  }
  final String body = sb.toString();
  return body.isEmpty ? '' : (depth == 0 ? '\n$body' : body);
}

String _table(Element el) {
  final List<List<String>> rows = <List<String>>[];
  for (final Element tr in el.querySelectorAll('tr')) {
    final List<Element> cells = tr.querySelectorAll('th, td');
    if (cells.isEmpty) continue;
    rows.add(cells
        .map((Element c) =>
            _inlineOf(c).replaceAll('|', r'\|').replaceAll('\n', ' '))
        .toList());
  }
  if (rows.isEmpty) return '';

  final int width = rows
      .map((List<String> r) => r.length)
      .reduce((int a, int b) => a > b ? a : b);
  for (final List<String> r in rows) {
    while (r.length < width) {
      r.add('');
    }
  }

  final StringBuffer sb = StringBuffer('\n');
  sb.writeln('| ${rows.first.join(' | ')} |');
  sb.writeln('|${List<String>.filled(width, ' --- ').join('|')}|');
  for (final List<String> r in rows.skip(1)) {
    sb.writeln('| ${r.join(' | ')} |');
  }
  return sb.toString();
}

String _details(Element el, {int depth = 0}) {
  final Element? summary = el.querySelector('summary');
  final String head = summary == null ? '' : _inlineOf(summary);
  summary?.remove();
  final String body = _children(el, depth: depth);
  final StringBuffer sb = StringBuffer('\n');
  if (head.isNotEmpty) sb.writeln('**$head**\n');
  sb.writeln(body.trim());
  return sb.toString();
}

String _figure(Element el) {
  final Element? img = el.querySelector('img');
  final Element? caption = el.querySelector('figcaption');
  final StringBuffer sb = StringBuffer('\n');
  if (img != null) sb.writeln(_image(img).trim());
  if (caption != null) {
    final String t = _inlineOf(caption);
    if (t.isNotEmpty) sb.writeln('\n*$t*');
  }
  return sb.toString();
}

String _image(Element el) {
  final String src =
      _absolute(el.attributes['src'] ?? el.attributes['data-src'] ?? '');
  if (src.isEmpty) return '';
  final String alt = (el.attributes['alt'] ?? '').replaceAll(']', '');
  return '\n![$alt]($src)\n';
}

String _alertMarker(Element el) {
  if (el.classes.contains('alert-danger')) return '> ⛔ ';
  if (el.classes.contains('alert-warning')) return '> ⚠️ ';
  if (el.classes.contains('alert-success')) return '> ✅ ';
  return '> ℹ️ ';
}

/// Wraps [body] in a Markdown blockquote.
///
/// Alerts nest on the site (an info box inside a warning box). Nested quote
/// markers are flattened to a single level, and when the inner block already
/// carries its own alert emoji the outer marker is not added again — otherwise
/// the output reads `> ⚠️ > ℹ️ …`.
String _quote(String body, {String marker = '> '}) {
  final List<String> lines = <String>[];
  for (final String raw in body.trim().split('\n')) {
    String t = raw.trim();
    while (t.startsWith('>')) {
      t = t.substring(1).trim();
    }
    lines.add(t);
  }
  while (lines.isNotEmpty && lines.first.isEmpty) {
    lines.removeAt(0);
  }
  while (lines.isNotEmpty && lines.last.isEmpty) {
    lines.removeLast();
  }
  if (lines.isEmpty) return '';

  final String effective =
      RegExp(r'^(⛔|⚠️|ℹ️|✅)').hasMatch(lines.first) ? '> ' : marker;

  final StringBuffer sb = StringBuffer('\n');
  bool first = true;
  for (final String line in lines) {
    if (line.isEmpty) {
      sb.writeln('>');
      continue;
    }
    sb.writeln(first ? '$effective$line' : '> $line');
    first = false;
  }
  return sb.toString();
}

String _indent(String text, String pad) => text
    .split('\n')
    .map((String l) => l.trim().isEmpty ? l : '$pad$l')
    .join('\n');

String _absolute(String href) {
  if (href.isEmpty) return '';
  if (href.startsWith('http://') || href.startsWith('https://')) return href;
  if (href.startsWith('//')) return 'https:$href';
  if (href.startsWith('#')) return '';
  if (href.startsWith('mailto:') || href.startsWith('tel:')) return href;
  return '$kSite${href.startsWith('/') ? '' : '/'}$href';
}

String _text(Element el) => _collapse(el.text);

String _collapse(String s) => s
    .replaceAll(' ', ' ')
    .replaceAll(RegExp(r'[ \t]+'), ' ')
    .replaceAll(RegExp(r' *\n *'), ' ')
    .trim();

/// Collapses runs of blank lines and strips the trailing anchor "#" that the
/// site appends to every heading.
String _tidy(String md) => md
    .replaceAll(RegExp(r'(#{2,4} .*?)#\s*$', multiLine: true), r'$1')
    .replaceAll(RegExp(r'\n{3,}'), '\n\n')
    .trim();

/// Splits a leading emoji off a title: "📇 Белый картон" -> ("📇", "Белый картон").
_TitleParts _splitEmoji(String raw) {
  final String s = raw.trim();
  if (s.isEmpty) return const _TitleParts('', '');
  final RegExpMatch? m = RegExp(
    r'^([\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}\u{2B00}-\u{2BFF}\u{1F1E6}-\u{1F1FF}\u{FE0F}\u{200D}\u{20E3}\u{2190}-\u{21FF}\u{2900}-\u{297F}]+)\s*(.*)$',
    unicode: true,
  ).firstMatch(s);
  if (m == null) return _TitleParts('', s);
  return _TitleParts(m.group(1)!.trim(), m.group(2)!.trim());
}

class _TitleParts {
  final String emoji;
  final String text;
  const _TitleParts(this.emoji, this.text);
}

class _Article {
  final String smile;
  final String title;
  final String lead;
  final String description;
  final String source;
  final String updated;
  final String sectionSlug;
  final String sectionTitle;
  final String sectionSmile;

  _Article({
    required this.smile,
    required this.title,
    required this.lead,
    required this.description,
    required this.source,
    required this.updated,
    required this.sectionSlug,
    required this.sectionTitle,
    required this.sectionSmile,
  });
}

class _Section {
  final String slug;
  final String title;
  final String smile;
  final List<_Article> items = <_Article>[];

  _Section({required this.slug, required this.title, required this.smile});
}
