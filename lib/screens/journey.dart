import 'package:flutter/material.dart';

import 'package:srbguide/data/journey.dart';
import 'package:srbguide/localization/app_localizations.dart';
import 'package:srbguide/screens/article.dart';

/// "My path" — the relocation checklist.
///
/// The guide answers "how do I do X"; this answers "what is X right now",
/// which is the question a newcomer actually has.
class JourneyScreen extends StatefulWidget {
  const JourneyScreen({super.key});

  @override
  State<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends State<JourneyScreen> {
  final JourneyRepository _repository = JourneyRepository.instance;

  List<JourneyStage>? _stages;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final List<JourneyStage> stages = await _repository.stages();
    if (!mounted) return;
    setState(() => _stages = stages);
  }

  Future<void> _toggle(JourneyStep step) async {
    await _repository.toggle(step.slug);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final List<JourneyStage>? stages = _stages;
    final ColorScheme scheme = Theme.of(context).colorScheme;

    final int done = stages == null
        ? 0
        : stages.fold<int>(0, (int s, JourneyStage st) => s + st.doneCount);
    final int total = stages == null
        ? 0
        : stages.fold<int>(0, (int s, JourneyStage st) => s + st.steps.length);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('my_path')),
        actions: <Widget>[
          if (done > 0)
            IconButton(
              tooltip: l10n.translate('journey_reset'),
              icon: const Icon(Icons.restart_alt),
              onPressed: () async {
                await _repository.reset();
                await _load();
              },
            ),
        ],
      ),
      body: stages == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: <Widget>[
                Card(
                  color: scheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Text(
                              l10n.translate('progress'),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: scheme.onPrimaryContainer,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '$done / $total',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: scheme.onPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: total == 0 ? 0 : done / total,
                            minHeight: 8,
                            backgroundColor: scheme.onPrimaryContainer
                                .withValues(alpha: 0.15),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ...stages.map((JourneyStage stage) => _StageCard(
                      stage: stage,
                      onToggle: _toggle,
                      onOpen: (JourneyStep s) async {
                        if (s.article == null) return;
                        await Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ArticleScreen(article: s.article!),
                          ),
                        );
                      },
                    )),
              ],
            ),
    );
  }
}

class _StageCard extends StatelessWidget {
  final JourneyStage stage;
  final ValueChanged<JourneyStep> onToggle;
  final ValueChanged<JourneyStep> onOpen;

  const _StageCard({
    required this.stage,
    required this.onToggle,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final bool complete = stage.doneCount == stage.steps.length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Row(
              children: <Widget>[
                if (complete)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Icon(Icons.check_circle,
                        size: 18, color: scheme.primary),
                  ),
                Text(
                  l10n.translate(stage.titleKey),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Text(
                  '${stage.doneCount}/${stage.steps.length}',
                  style:
                      TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Card(
            child: Column(
              children: <Widget>[
                for (int i = 0; i < stage.steps.length; i++) ...<Widget>[
                  if (i > 0)
                    Divider(
                        height: 1, indent: 56, color: scheme.outlineVariant),
                  ListTile(
                    shape: const RoundedRectangleBorder(),
                    leading: Checkbox(
                      value: stage.steps[i].done,
                      onChanged: (_) => onToggle(stage.steps[i]),
                    ),
                    title: Text(
                      stage.steps[i].title,
                      style: TextStyle(
                        fontSize: 14.5,
                        decoration: stage.steps[i].done
                            ? TextDecoration.lineThrough
                            : null,
                        color: stage.steps[i].done
                            ? scheme.onSurfaceVariant
                            : scheme.onSurface,
                      ),
                    ),
                    trailing: Icon(Icons.chevron_right,
                        color: scheme.onSurfaceVariant),
                    onTap: () => onOpen(stage.steps[i]),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
