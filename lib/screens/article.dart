import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:srbguide/data/guide_dto.dart';
import 'package:srbguide/data/guide_repository.dart';
import 'package:srbguide/localization/app_localizations.dart';
import 'package:srbguide/service/url_launcher_helper.dart';
import 'package:srbguide/widget/markdown/guide_markdown.dart';

/// Reader for a single guide article.
class ArticleScreen extends StatefulWidget {
  final GuideArticle article;

  const ArticleScreen({super.key, required this.article});

  @override
  State<ArticleScreen> createState() => _ArticleScreenState();
}

class _ArticleScreenState extends State<ArticleScreen> {
  static const String _textSizeKey = 'textSize';

  final GuideRepository _repository = GuideRepository.instance;
  final ScrollController _scrollController = ScrollController();

  double _textSize = 15;
  bool _isFavourite = false;

  @override
  void initState() {
    super.initState();
    _restoreState();
    _repository.markOpened(widget.article.id);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _restoreState() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool favourite = await _repository.isFavourite(widget.article.id);
    if (!mounted) return;
    setState(() {
      _textSize = prefs.getDouble(_textSizeKey) ?? 15;
      _isFavourite = favourite;
    });
  }

  Future<void> _setTextSize(double value) async {
    setState(() => _textSize = value);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_textSizeKey, value);
  }

  Future<void> _toggleFavourite() async {
    final bool added = await _repository.toggleFavourite(widget.article.id);
    if (!mounted) return;
    setState(() => _isFavourite = added);
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            added
                ? l10n.translate('added_to_favourite')
                : l10n.translate('removed_from_favourite'),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  void _openTextSizeSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext sheetContext) => _TextSizeSheet(
        value: _textSize,
        onChanged: _setTextSize,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final GuideArticle article = widget.article;
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: <Widget>[
          SliverAppBar(
            pinned: true,
            title: Text(
              article.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 17),
            ),
            actions: <Widget>[
              IconButton(
                tooltip: _isFavourite
                    ? l10n.translate('delete_favourite')
                    : l10n.translate('add_favourite'),
                icon: Icon(
                  _isFavourite ? Icons.bookmark : Icons.bookmark_border,
                  color: _isFavourite ? scheme.primary : null,
                ),
                onPressed: _toggleFavourite,
              ),
              IconButton(
                tooltip: l10n.translate('text_size'),
                icon: const Icon(Icons.format_size),
                onPressed: _openTextSizeSheet,
              ),
              IconButton(
                tooltip: l10n.translate('open_source'),
                icon: const Icon(Icons.open_in_new),
                onPressed: article.source.isEmpty
                    ? null
                    : () => UrlLauncherHelper.launchURL(article.source),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate(<Widget>[
                _Header(article: article),
                const SizedBox(height: 16),
                GuideMarkdown(
                  data: article.description,
                  textSize: _textSize,
                  onTapLink: _openLink,
                ),
                const SizedBox(height: 28),
                _SourceFooter(article: article),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openLink(String href) async {
    // In-page anchors from the source site cannot be resolved offline; open the
    // original article instead of failing silently.
    if (href.startsWith('#')) {
      if (widget.article.source.isNotEmpty) {
        await UrlLauncherHelper.launchURL('${widget.article.source}$href');
      }
      return;
    }
    try {
      await UrlLauncherHelper.launchURL(href);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                '${AppLocalizations.of(context)!.translate('cant_open_link')}: $href')),
      );
    }
  }
}

class _Header extends StatelessWidget {
  final GuideArticle article;

  const _Header({required this.article});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (article.smile.isNotEmpty) ...<Widget>[
              Text(article.smile, style: const TextStyle(fontSize: 30)),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                article.title,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            Chip(
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              label: Text(article.sectionTitle,
                  style: const TextStyle(fontSize: 12)),
            ),
            if (article.updated.isNotEmpty)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(Icons.update, size: 14, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    article.updated,
                    style:
                        TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
          ],
        ),
        if (article.lead.isNotEmpty) ...<Widget>[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: scheme.secondaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              article.lead,
              style: TextStyle(
                fontSize: 14.5,
                height: 1.45,
                color: scheme.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Credits srb.guide on every article and links back to the original.
class _SourceFooter extends StatelessWidget {
  final GuideArticle article;

  const _SourceFooter({required this.article});

  @override
  Widget build(BuildContext context) {
    if (article.source.isEmpty) return const SizedBox.shrink();
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return Card(
      child: InkWell(
        onTap: () => UrlLauncherHelper.launchURL(article.source),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: <Widget>[
              Icon(Icons.link, color: scheme.onSurfaceVariant),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      l10n.translate('source_srb_guide'),
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      article.source,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 12, color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _TextSizeSheet extends StatefulWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const _TextSizeSheet({required this.value, required this.onChanged});

  @override
  State<_TextSizeSheet> createState() => _TextSizeSheetState();
}

class _TextSizeSheetState extends State<_TextSizeSheet> {
  late double _value = widget.value;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            l10n.translate('text_size'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              const Text('A', style: TextStyle(fontSize: 13)),
              Expanded(
                child: Slider(
                  value: _value,
                  min: 12,
                  max: 24,
                  divisions: 12,
                  label: _value.toStringAsFixed(0),
                  onChanged: (double v) {
                    setState(() => _value = v);
                    widget.onChanged(v);
                  },
                ),
              ),
              const Text('A', style: TextStyle(fontSize: 24)),
            ],
          ),
        ],
      ),
    );
  }
}
