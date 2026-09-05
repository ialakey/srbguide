import 'dart:async';

import 'package:flutter/material.dart';

import 'package:srbguide/data/guide_dto.dart';
import 'package:srbguide/data/guide_repository.dart';
import 'package:srbguide/localization/app_localizations.dart';
import 'package:srbguide/screens/article.dart';
import 'package:srbguide/widget/guide_tiles.dart';

/// Full-text search across every article.
///
/// The old `SearchDelegate` only searched the article you already had open;
/// this searches titles, summaries and body text across the whole guide, with
/// stemming so Russian inflection does not hide results.
class GuideSearchScreen extends StatefulWidget {
  const GuideSearchScreen({super.key});

  @override
  State<GuideSearchScreen> createState() => _GuideSearchScreenState();
}

class _GuideSearchScreenState extends State<GuideSearchScreen> {
  final GuideRepository _repository = GuideRepository.instance;
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();

  GuideContent _content = GuideContent.empty;
  List<SearchHit> _results = const <SearchHit>[];
  String? _sectionSlug;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _repository.load().then((GuideContent c) {
      if (mounted) setState(() => _content = c);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    // Searching 1.5 MB of text on every keystroke makes typing stutter.
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), _run);
  }

  void _run() {
    if (!mounted) return;
    setState(() {
      _results = _repository.search(
        _content,
        _controller.text,
        sectionSlug: _sectionSlug,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool hasQuery = _controller.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          focusNode: _focus,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: l10n.translate('search_placeholder'),
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: _onChanged,
        ),
        actions: <Widget>[
          if (hasQuery)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                _controller.clear();
                _run();
              },
            ),
        ],
        bottom: _content.sections.isEmpty
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(52),
                child: SizedBox(
                  height: 52,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(right: 8, bottom: 8),
                        child: FilterChip(
                          label: Text(l10n.translate('all')),
                          selected: _sectionSlug == null,
                          onSelected: (_) {
                            setState(() => _sectionSlug = null);
                            _run();
                          },
                        ),
                      ),
                      ..._content.sections.map(
                        (GuideSection s) => Padding(
                          padding: const EdgeInsets.only(right: 8, bottom: 8),
                          child: FilterChip(
                            label: Text(s.title),
                            selected: _sectionSlug == s.slug,
                            onSelected: (_) {
                              setState(() => _sectionSlug =
                                  _sectionSlug == s.slug ? null : s.slug);
                              _run();
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
      body: !hasQuery
          ? EmptyState(
              icon: Icons.search,
              message: l10n.translate('search_placeholder'),
            )
          : _results.isEmpty
              ? EmptyState(
                  icon: Icons.search_off,
                  message: l10n.translate('nothing_found'),
                )
              : Column(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                      child: Row(
                        children: <Widget>[
                          Text(
                            '${l10n.translate('found')}: ${_results.length}',
                            style: TextStyle(
                                fontSize: 12.5, color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
                        itemCount: _results.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (BuildContext context, int i) {
                          final SearchHit hit = _results[i];
                          return ArticleTile(
                            article: hit.article,
                            showSection: true,
                            subtitleOverride: hit.snippet,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    ArticleScreen(article: hit.article),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
