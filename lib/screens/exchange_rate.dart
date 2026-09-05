import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:srbguide/data/currency_rate.dart';
import 'package:srbguide/localization/app_localizations.dart';
import 'package:srbguide/service/exchange_rate_service.dart';
import 'package:srbguide/service/url_launcher_helper.dart';

/// Live rates from the Belgrade exchange offices the guide recommends.
///
/// Offices are queried in parallel and each card reports its own state, so one
/// site being down no longer leaves the whole screen empty. The best rate is
/// highlighted, the NBS reference rate is shown as a yardstick, and the last
/// successful fetch is cached so the screen still works offline.
class ExchangeRateScreen extends StatefulWidget {
  const ExchangeRateScreen({super.key});

  @override
  State<ExchangeRateScreen> createState() => _ExchangeRateScreenState();
}

class _ExchangeRateScreenState extends State<ExchangeRateScreen> {
  List<OfficeRates> _results = const <OfficeRates>[];
  bool _loading = true;
  bool _isOffline = false;
  DateTime? _loadedAt;
  String _currency = 'EUR';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    // Paint whatever we already have while the network call is in flight.
    final ({List<OfficeRates> offices, DateTime? at}) cache =
        await ExchangeRateService.cached();
    if (mounted && cache.offices.isNotEmpty && _results.isEmpty) {
      setState(() {
        _results = cache.offices;
        _loadedAt = cache.at;
        _isOffline = true;
      });
    }

    final List<OfficeRates> results = await ExchangeRateService.fetchAll();
    if (!mounted) return;

    final bool anyLive =
        results.any((OfficeRates r) => !r.hasError && r.rates.isNotEmpty);
    setState(() {
      if (anyLive) {
        _results = results;
        _loadedAt = DateTime.now();
        _isOffline = false;
      } else if (cache.offices.isNotEmpty) {
        _results = cache.offices;
        _loadedAt = cache.at;
        _isOffline = true;
      } else {
        _results = results;
      }
      _loading = false;
    });
  }

  List<String> get _availableCurrencies {
    final Set<String> codes = <String>{};
    for (final OfficeRates office in _results) {
      for (final CurrencyRate rate in office.rates) {
        codes.add(rate.code);
      }
    }
    return kPreferredCurrencyOrder.where(codes.contains).toList();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final DateTime? at = _loadedAt;
    final List<String> currencies = _availableCurrencies;
    if (currencies.isNotEmpty && !currencies.contains(_currency)) {
      _currency = currencies.first;
    }

    final BestRate? best = ExchangeRateService.bestSell(_results, _currency);
    final String? reference =
        ExchangeRateService.referenceRate(_results, _currency);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('exchange_rate')),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.translate('refresh'),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: _loading && _results.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                children: <Widget>[
                  if (_isOffline)
                    _Banner(
                      icon: Icons.cloud_off,
                      text: l10n.translate('offline_rates'),
                    ),
                  if (currencies.length > 1) ...<Widget>[
                    SegmentedButton<String>(
                      segments: currencies
                          .map((String c) => ButtonSegment<String>(
                                value: c,
                                label: Text(c),
                              ))
                          .toList(),
                      selected: <String>{_currency},
                      showSelectedIcon: false,
                      onSelectionChanged: (Set<String> s) =>
                          setState(() => _currency = s.first),
                    ),
                    const SizedBox(height: 14),
                  ],
                  if (best != null)
                    _BestRateCard(
                      code: _currency,
                      best: best,
                      reference: reference,
                    ),
                  const SizedBox(height: 14),
                  _Converter(code: _currency, rate: best?.rate),
                  const SizedBox(height: 18),
                  if (at != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10, left: 4),
                      child: Text(
                        '${l10n.translate('updated_at')} '
                        '${at.hour.toString().padLeft(2, '0')}:'
                        '${at.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                            fontSize: 12, color: scheme.onSurfaceVariant),
                      ),
                    ),
                  ..._results.map(
                    (OfficeRates r) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _OfficeCard(
                        result: r,
                        onRetry: _load,
                        bestOfficeName: best?.officeName,
                        highlighted: _currency,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _Banner extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Banner({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 18, color: scheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant)),
          ),
        ],
      ),
    );
  }
}

class _BestRateCard extends StatelessWidget {
  final String code;
  final BestRate best;
  final String? reference;

  const _BestRateCard({
    required this.code,
    required this.best,
    this.reference,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return Card(
      color: scheme.primaryContainer,
      child: InkWell(
        onTap: () => UrlLauncherHelper.launchURL(best.officeUrl),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(Icons.trending_down,
                      size: 19, color: scheme.onPrimaryContainer),
                  const SizedBox(width: 8),
                  Text(
                    '${l10n.translate('best_rate')} · $code',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    best.officeName,
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onPrimaryContainer.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: <Widget>[
                  Text(
                    best.rate.sell,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'RSD',
                    style: TextStyle(
                      fontSize: 14,
                      color: scheme.onPrimaryContainer.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
              if (reference != null) ...<Widget>[
                const SizedBox(height: 6),
                Text(
                  '${l10n.translate('nbs_rate')}: $reference',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: scheme.onPrimaryContainer.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Converts between the selected currency and dinars using the best sell rate.
class _Converter extends StatefulWidget {
  final String code;
  final CurrencyRate? rate;

  const _Converter({required this.code, required this.rate});

  @override
  State<_Converter> createState() => _ConverterState();
}

class _ConverterState extends State<_Converter> {
  final TextEditingController _controller = TextEditingController(text: '100');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final double? rate = widget.rate?.sellValue;
    final double amount =
        double.tryParse(_controller.text.replaceAll(',', '.')) ?? 0;
    final String result =
        rate == null ? '—' : (amount * rate).toStringAsFixed(2);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              l10n.translate('converter'),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                SizedBox(
                  width: 130,
                  child: TextField(
                    controller: _controller,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    decoration: InputDecoration(
                      labelText: l10n.translate('amount'),
                      suffixText: widget.code,
                      isDense: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 14),
                Icon(Icons.arrow_forward, color: scheme.onSurfaceVariant),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Text(
                        result,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'RSD',
                        style: TextStyle(
                            fontSize: 12, color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OfficeCard extends StatelessWidget {
  final OfficeRates result;
  final VoidCallback onRetry;
  final String? bestOfficeName;
  final String highlighted;

  const _OfficeCard({
    required this.result,
    required this.onRetry,
    required this.highlighted,
    this.bestOfficeName,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final bool isBest = result.office.name == bestOfficeName;

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          InkWell(
            onTap: () => UrlLauncherHelper.launchURL(result.office.url),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
              child: Row(
                children: <Widget>[
                  Text(
                    result.office.name,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  if (isBest) ...<Widget>[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        l10n.translate('best_rate'),
                        style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: scheme.onPrimary),
                      ),
                    ),
                  ],
                  const Spacer(),
                  Icon(Icons.open_in_new,
                      size: 17, color: scheme.onSurfaceVariant),
                ],
              ),
            ),
          ),
          if (result.hasError)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Row(
                children: <Widget>[
                  Icon(Icons.cloud_off,
                      size: 18, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.translate('rates_error'),
                      style: TextStyle(
                          fontSize: 13, color: scheme.onSurfaceVariant),
                    ),
                  ),
                  TextButton(
                    onPressed: onRetry,
                    child: Text(l10n.translate('retry')),
                  ),
                ],
              ),
            )
          else if (result.rates.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                l10n.translate('no_rates'),
                style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: <Widget>[
                        const SizedBox(width: 52),
                        Expanded(
                          child: Text(
                            l10n.translate('buy'),
                            textAlign: TextAlign.end,
                            style: TextStyle(
                                fontSize: 11.5, color: scheme.onSurfaceVariant),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            l10n.translate('sell'),
                            textAlign: TextAlign.end,
                            style: TextStyle(
                                fontSize: 11.5, color: scheme.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...result.rates.map(
                    (CurrencyRate r) => Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 6, horizontal: 6),
                      decoration: r.code == highlighted
                          ? BoxDecoration(
                              color: scheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(10),
                            )
                          : null,
                      margin: const EdgeInsets.only(bottom: 2),
                      child: Row(
                        children: <Widget>[
                          SizedBox(
                            width: 46,
                            child: Text(
                              r.code,
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              r.buy,
                              textAlign: TextAlign.end,
                              style: const TextStyle(fontSize: 15),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              r.sell,
                              textAlign: TextAlign.end,
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
