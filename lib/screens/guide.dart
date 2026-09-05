import 'package:flutter/material.dart';

import 'package:srbguide/data/guide_dto.dart';
import 'package:srbguide/data/guide_repository.dart';
import 'package:srbguide/localization/app_localizations.dart';
import 'package:srbguide/screens/article.dart';
import 'package:srbguide/screens/guide_search.dart';
import 'package:srbguide/utils/guide_icons.dart';
import 'package:srbguide/widget/guide_tiles.dart';

/// The guide, grouped into collapsible sections.
///
/// The old screen flattened all articles into one `Column` inside a
/// `SingleChildScrollView`, building every card up front. With 74 articles it
/// is a lazy `CustomScrollView` instead.
class GuideScreen extends StatefulWidget {
  const GuideScreen({super.key});

  @override
  State<GuideScreen> createState() => _GuideScreenState();
}

class _GuideScreenState extends State<GuideScreen> {
  final GuideRepository _repository = GuideRepository.instance;

  GuideContent? _content;
  final Set<String> _expanded = <String>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final GuideContent content = await _repository.load();
    if (!mounted) return;
    setState(() {
      _content = content;
      // Open the first section so the screen never looks empty.
      if (_expanded.isEmpty && content.sections.isNotEmpty) {
        _expanded.add(content.sections.first.slug);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final GuideContent? content = _content;

    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar.large(
            title: Text(l10n.translate('guide')),
            actions: <Widget>[
              IconButton(
                icon: const Icon(Icons.search),
                tooltip: l10n.translate('search'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const GuideSearchScreen(),
                  ),
                ),
              ),
            ],
          ),
          if (content == null)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
              sliver: SliverList.separated(
                itemCount: content.sections.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (BuildContext context, int i) {
                  final GuideSection section = content.sections[i];
                  return _SectionCard(
                    section: section,
                    expanded: _expanded.contains(section.slug),
                    onToggle: () => setState(() {
                      if (!_expanded.remove(section.slug)) {
                        _expanded.add(section.slug);
                      }
                    }),
                    onOpen: _openArticle,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openArticle(GuideArticle article) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ArticleScreen(article: article)),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final GuideSection section;
  final bool expanded;
  final VoidCallback onToggle;
  final ValueChanged<GuideArticle> onOpen;

  const _SectionCard({
    required this.section,
    required this.expanded,
    required this.onToggle,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Card(
          color: expanded ? scheme.secondaryContainer : null,
          child: InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: <Widget>[
                  Icon(
                    guideSectionIcon(section.icon),
                    color:
                        expanded ? scheme.onSecondaryContainer : scheme.primary,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          section.title,
                          style: const TextStyle(
                              fontSize: 15.5, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${section.items.length} ${l10n.translate('articles')}',
                          style: TextStyle(
                            fontSize: 12,
                            color: expanded
                                ? scheme.onSecondaryContainer
                                    .withValues(alpha: 0.8)
                                : scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: Icon(Icons.expand_more,
                        color: expanded
                            ? scheme.onSecondaryContainer
                            : scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              children: section.items
                  .map((GuideArticle a) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ArticleTile(
                          article: a,
                          onTap: () => onOpen(a),
                        ),
                      ))
                  .toList(),
            ),
          ),
          crossFadeState:
              expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 180),
          sizeCurve: Curves.easeOut,
        ),
      ],
    );
  }
}
