import 'package:flutter/material.dart';

import 'package:srbguide/data/guide_dto.dart';

/// One article row, used by the guide list, search results, favourites and the
/// "continue reading" strip on home.
class ArticleTile extends StatelessWidget {
  final GuideArticle article;
  final VoidCallback onTap;

  /// Shows the section name under the title — useful in search results and
  /// favourites, redundant inside a section list.
  final bool showSection;

  /// Replaces the summary line — search results use it to show the matching
  /// snippet instead of an unrelated summary.
  final String? subtitleOverride;

  final Widget? trailing;

  const ArticleTile({
    super.key,
    required this.article,
    required this.onTap,
    this.showSection = false,
    this.subtitleOverride,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final String subtitle = subtitleOverride?.isNotEmpty == true
        ? subtitleOverride!
        : showSection
            ? article.sectionTitle
            : article.lead;

    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  article.smile.isEmpty ? '📄' : article.smile,
                  style: const TextStyle(fontSize: 19),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      article.title,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    if (subtitle.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.35,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...<Widget>[
                const SizedBox(width: 8),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-screen empty state with an icon and message.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 44, color: scheme.onSurfaceVariant),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14.5),
            ),
            if (action != null) ...<Widget>[
              const SizedBox(height: 18),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
