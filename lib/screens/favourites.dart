import 'package:flutter/material.dart';

import 'package:srbguide/data/guide_dto.dart';
import 'package:srbguide/data/guide_repository.dart';
import 'package:srbguide/localization/app_localizations.dart';
import 'package:srbguide/screens/app_shell.dart';
import 'package:srbguide/screens/article.dart';
import 'package:srbguide/widget/guide_tiles.dart';

/// Saved articles.
///
/// Favourites are stored as article ids rather than a snapshot of the article
/// text, so a saved article now follows the guide when it is updated.
class FavouritesScreen extends StatefulWidget {
  const FavouritesScreen({super.key});

  @override
  State<FavouritesScreen> createState() => _FavouritesScreenState();
}

class _FavouritesScreenState extends State<FavouritesScreen>
    with WidgetsBindingObserver {
  final GuideRepository _repository = GuideRepository.instance;

  List<GuideArticle>? _articles;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final List<GuideArticle> articles = await _repository.favouriteArticles();
    if (!mounted) return;
    setState(() => _articles = articles);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final List<GuideArticle>? articles = _articles;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.translate('favourite'))),
      body: articles == null
          ? const Center(child: CircularProgressIndicator())
          : articles.isEmpty
              ? EmptyState(
                  icon: Icons.bookmark_border,
                  message: l10n.translate('no_favourite_message'),
                  action: FilledButton.tonal(
                    onPressed: () => AppShell.of(context)?.goTo(1),
                    child: Text(l10n.translate('guide')),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                    itemCount: articles.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (BuildContext context, int i) {
                      final GuideArticle a = articles[i];
                      return ArticleTile(
                        article: a,
                        showSection: true,
                        trailing: IconButton(
                          icon: const Icon(Icons.bookmark),
                          tooltip: l10n.translate('delete_favourite'),
                          onPressed: () async {
                            await _repository.toggleFavourite(a.id);
                            _load();
                          },
                        ),
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => ArticleScreen(article: a),
                            ),
                          );
                          _load();
                        },
                      );
                    },
                  ),
                ),
    );
  }
}
