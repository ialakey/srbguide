// Regenerates `assets/data/tg_chats.json` from https://stats.srb.guide/channels.
//
//   dart run tool/sync_chats.dart
//   dart run tool/sync_chats.dart --out assets/data/tg_chats.json --max-pages 3
//
// The chat directory used to be a hand-maintained list that went stale. The
// catalogue on stats.srb.guide tracks the same chats along with their topic,
// size and whether they are still active, and robots.txt allows reading it.
//
// The output keeps the original `name` / `url` / `group` keys so existing
// screens keep working, and adds the catalogue's extra fields.

import 'dart:convert';
import 'dart:io';

import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

const String kSource = 'https://stats.srb.guide/channels';
const String kDefaultOut = 'assets/data/tg_chats.json';

/// Stop before this many pages no matter what the site reports, so a paging
/// bug cannot turn into an unbounded crawl of someone else's server.
const int kPageCeiling = 40;

Future<void> main(List<String> args) async {
  final String out = _argValue(args, '--out') ?? kDefaultOut;
  final int maxPages =
      int.tryParse(_argValue(args, '--max-pages') ?? '') ?? kPageCeiling;

  final List<Map<String, Object?>> chats = <Map<String, Object?>>[];
  final Set<String> seen = <String>{};

  for (int page = 1; page <= maxPages; page++) {
    stdout.write('  page $page … ');
    final String html = await _get('$kSource?page=$page');
    final List<Map<String, Object?>> found = _parsePage(html);

    if (found.isEmpty) {
      stdout.writeln('empty, stopping');
      break;
    }

    int added = 0;
    for (final Map<String, Object?> c in found) {
      if (seen.add(c['url']! as String)) {
        chats.add(c);
        added++;
      }
    }
    stdout.writeln('${found.length} found, $added new');

    // Every entry on this page was already known — we have wrapped around.
    if (added == 0) break;

    // Be a polite scraper.
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }

  if (chats.length < 50) {
    stderr.writeln('FAIL: only ${chats.length} chats — the page layout '
        'probably changed');
    exit(1);
  }

  chats.sort((Map<String, Object?> a, Map<String, Object?> b) {
    final int byMembers =
        ((b['members'] ?? 0) as int).compareTo((a['members'] ?? 0) as int);
    if (byMembers != 0) return byMembers;
    return (a['name']! as String).compareTo(b['name']! as String);
  });

  final File file = File(out);
  await file.parent.create(recursive: true);
  await file.writeAsString(
    const JsonEncoder.withIndent('  ').convert(chats),
    encoding: utf8,
  );

  final Map<String, int> byGroup = <String, int>{};
  for (final Map<String, Object?> c in chats) {
    final String g = (c['group'] ?? '') as String;
    byGroup[g] = (byGroup[g] ?? 0) + 1;
  }

  stdout.writeln('Wrote $out — ${chats.length} chats');
  final List<MapEntry<String, int>> sorted = byGroup.entries.toList()
    ..sort((MapEntry<String, int> a, MapEntry<String, int> b) =>
        b.value.compareTo(a.value));
  for (final MapEntry<String, int> e in sorted.take(12)) {
    stdout.writeln('  ${e.value.toString().padLeft(4)}  ${e.key}');
  }
}

List<Map<String, Object?>> _parsePage(String html) {
  final Document doc = html_parser.parse(html);
  final List<Map<String, Object?>> chats = <Map<String, Object?>>[];

  for (final Element card in doc.querySelectorAll('a[href^="/channels/"]')) {
    final String href = card.attributes['href'] ?? '';
    final String slug = href.replaceFirst('/channels/', '').trim();
    if (slug.isEmpty || slug.contains('/')) continue;

    // The card carries a bold name line and a smaller "type · @user · topic".
    final Element? nameEl = card.querySelector('div.font-semibold');
    final String name = nameEl == null ? '' : _clean(nameEl.text);
    if (name.isEmpty) continue;

    String kind = '';
    String username = '';
    String group = '';
    for (final Element meta in card.querySelectorAll('div.text-xs')) {
      final String text = _clean(meta.text);
      if (!text.contains('@')) continue;
      final List<String> parts =
          text.split('·').map((String p) => p.trim()).toList();
      for (final String part in parts) {
        if (part.startsWith('@')) {
          username = part.substring(1);
        } else if (kind.isEmpty && part.length < 20) {
          kind = part;
        } else if (group.isEmpty) {
          group = part;
        }
      }
      break;
    }

    final String body = _clean(card.text);
    chats.add(<String, Object?>{
      // Original keys, kept so existing screens keep working.
      'name': name,
      'url': 'https://t.me/${username.isEmpty ? slug : username}',
      'group': group.isEmpty ? 'Разное' : group,
      // Catalogue extras.
      'username': username.isEmpty ? slug : username,
      'kind': kind,
      'members': _members(body),
      'active': body.contains('живой'),
    });
  }

  return chats;
}

/// Subscriber count, e.g. `33 903 участников` -> 33903.
int _members(String text) {
  final RegExpMatch? m = RegExp(r'([\d][\d\s  ]*)\s*участник').firstMatch(text);
  if (m == null) return 0;
  final String digits = (m.group(1) ?? '').replaceAll(RegExp(r'[^\d]'), '');
  return int.tryParse(digits) ?? 0;
}

String _clean(String s) =>
    s.replaceAll(' ', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();

Future<String> _get(String url) async {
  final http.Response response = await http.get(
    Uri.parse(url),
    headers: const <String, String>{
      'User-Agent':
          'srbguide-app-sync/1.0 (+https://github.com/ialakey/srbguide)',
      'Accept-Language': 'ru,en;q=0.8',
    },
  ).timeout(const Duration(seconds: 40));
  if (response.statusCode != 200) {
    throw StateError('HTTP ${response.statusCode} for $url');
  }
  return utf8.decode(response.bodyBytes);
}

String? _argValue(List<String> args, String flag) {
  final int i = args.indexOf(flag);
  if (i == -1 || i + 1 >= args.length) return null;
  return args[i + 1];
}
