import 'package:flutter/material.dart';

import 'package:srbguide/data/currency_rate.dart';
import 'package:srbguide/data/guide_dto.dart';
import 'package:srbguide/data/deadline.dart';
import 'package:srbguide/data/deadline_repository.dart';
import 'package:srbguide/data/guide_repository.dart';
import 'package:srbguide/data/journey.dart';
import 'package:srbguide/localization/app_localizations.dart';
import 'package:srbguide/screens/app_shell.dart';
import 'package:srbguide/screens/article.dart';
import 'package:srbguide/screens/calculator.dart';
import 'package:srbguide/screens/deadlines.dart';
import 'package:srbguide/screens/exchange_rate.dart';
import 'package:srbguide/screens/guide_search.dart';
import 'package:srbguide/screens/journey.dart';
import 'package:srbguide/screens/settings.dart';
import 'package:srbguide/screens/white_cardboard.dart';
import 'package:srbguide/service/exchange_rate_service.dart';
import 'package:srbguide/utils/guide_icons.dart';
import 'package:srbguide/widget/guide_tiles.dart';

/// Landing screen: search, today's rate, the tools people open most, and a way
/// back into whatever they were last reading.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GuideRepository _repository = GuideRepository.instance;

  GuideContent _content = GuideContent.empty;
  List<GuideArticle> _recent = const <GuideArticle>[];
  OfficeRates? _rates;
  bool _ratesLoading = true;
  Deadline? _nextDeadline;
  ({int done, int total}) _journey = (done: 0, total: 0);

  @override
  void initState() {
    super.initState();
    _load();
    _loadRates();
  }

  Future<void> _load() async {
    final GuideContent content = await _repository.load();
    final List<GuideArticle> recent =
        await _repository.recentArticles(limit: 3);
    final Deadline? deadline = await DeadlineRepository.instance.next();
    final ({int done, int total}) journey =
        await JourneyRepository.instance.progress();
    if (!mounted) return;
    setState(() {
      _content = content;
      _recent = recent;
      _nextDeadline = deadline;
      _journey = journey;
    });
  }

  Future<void> _loadRates() async {
    setState(() => _ratesLoading = true);
    final List<OfficeRates> all = await ExchangeRateService.fetchAll();
    if (!mounted) return;
    setState(() {
      _rates = all
              .where((OfficeRates r) => !r.hasError && r.rates.isNotEmpty)
              .isNotEmpty
          ? all.firstWhere((OfficeRates r) => !r.hasError && r.rates.isNotEmpty)
          : null;
      _ratesLoading = false;
    });
  }

  Future<void> _refresh() async {
    await Future.wait(<Future<void>>[_load(), _loadRates()]);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          slivers: <Widget>[
            SliverAppBar.large(
              title: Text(l10n.translate('app_name')),
              actions: <Widget>[
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  tooltip: l10n.translate('settings'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const SettingsScreen(),
                    ),
                  ),
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
              sliver: SliverList(
                delegate: SliverChildListDelegate(<Widget>[
                  _SearchField(
                    hint: l10n.translate('search_guide'),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const GuideSearchScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _RateCard(
                    loading: _ratesLoading,
                    rates: _rates,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ExchangeRateScreen(),
                      ),
                    ),
                    onRetry: _loadRates,
                  ),
                  if (_nextDeadline != null) ...<Widget>[
                    const SizedBox(height: 14),
                    _NextDeadlineCard(
                      deadline: _nextDeadline!,
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const DeadlinesScreen(),
                          ),
                        );
                        _load();
                      },
                    ),
                  ],
                  const SizedBox(height: 14),
                  _JourneyCard(
                    progress: _journey,
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const JourneyScreen(),
                        ),
                      );
                      _load();
                    },
                  ),
                  const SizedBox(height: 24),
                  _SectionHeading(title: l10n.translate('quick_actions')),
                  const SizedBox(height: 10),
                  const _QuickActions(),
                  if (_recent.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 24),
                    _SectionHeading(title: l10n.translate('continue_reading')),
                    const SizedBox(height: 10),
                    ..._recent.map(
                      (GuideArticle a) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ArticleTile(
                          article: a,
                          onTap: () => _openArticle(a),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      _SectionHeading(title: l10n.translate('sections')),
                      TextButton(
                        onPressed: () => AppShell.of(context)?.goTo(1),
                        child: Text(l10n.translate('all_sections')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  _SectionGrid(sections: _content.sections),
                  const SizedBox(height: 24),
                  _AttributionNote(content: _content, style: theme),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openArticle(GuideArticle article) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ArticleScreen(article: article)),
    );
    _load();
  }
}

class _SearchField extends StatelessWidget {
  final String hint;
  final VoidCallback onTap;

  const _SearchField({required this.hint, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          child: Row(
            children: <Widget>[
              Icon(Icons.search, color: scheme.onSurfaceVariant),
              const SizedBox(width: 12),
              Text(hint, style: TextStyle(color: scheme.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RateCard extends StatelessWidget {
  final bool loading;
  final OfficeRates? rates;
  final VoidCallback onTap;
  final VoidCallback onRetry;

  const _RateCard({
    required this.loading,
    required this.rates,
    required this.onTap,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return Card(
      color: scheme.primaryContainer,
      child: InkWell(
        onTap: loading ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(Icons.currency_exchange,
                      size: 20, color: scheme.onPrimaryContainer),
                  const SizedBox(width: 8),
                  Text(
                    l10n.translate('exchange_rate'),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  const Spacer(),
                  if (rates != null)
                    Text(
                      rates!.office.name,
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            scheme.onPrimaryContainer.withValues(alpha: 0.75),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              if (loading)
                const SizedBox(
                  height: 30,
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              else if (rates == null)
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        l10n.translate('rates_error'),
                        style: TextStyle(color: scheme.onPrimaryContainer),
                      ),
                    ),
                    TextButton(
                      onPressed: onRetry,
                      child: Text(l10n.translate('retry')),
                    ),
                  ],
                )
              else
                Row(
                  children: rates!.rates
                      .take(3)
                      .map((CurrencyRate r) => Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  r.code,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: scheme.onPrimaryContainer
                                        .withValues(alpha: 0.75),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  r.sell,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: scheme.onPrimaryContainer,
                                  ),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The single most urgent deadline, so the thing with a date on it is the
/// first thing on the screen.
class _NextDeadlineCard extends StatelessWidget {
  final Deadline deadline;
  final VoidCallback onTap;

  const _NextDeadlineCard({required this.deadline, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final DateTime target = deadline.nextOccurrence;
    final DateTime now = DateTime.now();
    final int days = DateTime(target.year, target.month, target.day)
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;
    final bool urgent = days <= 3;

    return Card(
      color: urgent ? scheme.errorContainer : null,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: <Widget>[
              Icon(
                deadline.kind.icon,
                color: urgent ? scheme.onErrorContainer : scheme.primary,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      deadline.customTitle?.isNotEmpty == true
                          ? deadline.customTitle!
                          : l10n.translate(deadline.kind.titleKey),
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: urgent ? scheme.onErrorContainer : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      days < 0
                          ? l10n.translate('overdue')
                          : days == 0
                              ? l10n.translate('today')
                              : days == 1
                                  ? l10n.translate('tomorrow')
                                  : '$days ${l10n.translate('days_left_short')}',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: urgent
                            ? scheme.onErrorContainer.withValues(alpha: 0.85)
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: urgent
                      ? scheme.onErrorContainer
                      : scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

/// Relocation checklist progress.
class _JourneyCard extends StatelessWidget {
  final ({int done, int total}) progress;
  final VoidCallback onTap;

  const _JourneyCard({required this.progress, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    if (progress.total == 0) return const SizedBox.shrink();

    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(Icons.checklist_rtl, size: 20, color: scheme.primary),
                  const SizedBox(width: 10),
                  Text(
                    l10n.translate('my_path'),
                    style: const TextStyle(
                        fontSize: 14.5, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Text(
                    '${progress.done} / ${progress.total}',
                    style:
                        TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress.done / progress.total,
                  minHeight: 6,
                  backgroundColor: scheme.surfaceContainerHighest,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final List<_Action> actions = <_Action>[
      _Action(
        icon: Icons.event_available_outlined,
        label: l10n.translate('calculator_visarun'),
        builder: (_) => const VisaFreeCalculatorScreen(),
      ),
      _Action(
        icon: Icons.description_outlined,
        label: l10n.translate('create_whiteboard'),
        builder: (_) => const CreateWhiteCardboardScreen(),
      ),
    ];

    return Row(
      children: actions
          .map(
            (_Action a) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: a == actions.last ? 0 : 10),
                child: Card(
                  child: InkWell(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: a.builder),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Icon(a.icon,
                              color: Theme.of(context).colorScheme.primary),
                          const SizedBox(height: 12),
                          Text(
                            a.label,
                            style: const TextStyle(
                                fontSize: 13.5, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _Action {
  final IconData icon;
  final String label;
  final WidgetBuilder builder;

  const _Action({
    required this.icon,
    required this.label,
    required this.builder,
  });
}

class _SectionGrid extends StatelessWidget {
  final List<GuideSection> sections;

  const _SectionGrid({required this.sections});

  @override
  Widget build(BuildContext context) {
    if (sections.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: sections.map((GuideSection s) {
        return SizedBox(
          width: (MediaQuery.sizeOf(context).width - 32 - 10) / 2,
          child: Card(
            child: InkWell(
              onTap: () => AppShell.of(context)?.goTo(1),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(guideSectionIcon(s.icon), color: scheme.primary),
                    const SizedBox(height: 10),
                    Text(
                      s.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13.5, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${s.items.length} ${AppLocalizations.of(context)!.translate('articles')}',
                      style: TextStyle(
                          fontSize: 12, color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final String title;

  const _SectionHeading({required this.title});

  @override
  Widget build(BuildContext context) => Text(
        title,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
      );
}

/// Credits srb.guide, as agreed with the guide's author.
class _AttributionNote extends StatelessWidget {
  final GuideContent content;
  final ThemeData style;

  const _AttributionNote({required this.content, required this.style});

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = style.colorScheme;
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final DateTime? synced = content.syncedAt;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          l10n.translate('content_source_note'),
          style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
        ),
        if (synced != null) ...<Widget>[
          const SizedBox(height: 4),
          Text(
            '${l10n.translate('guide_updated')}: '
            '${synced.day.toString().padLeft(2, '0')}.'
            '${synced.month.toString().padLeft(2, '0')}.${synced.year}',
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}
