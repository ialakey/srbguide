import 'package:flutter/material.dart';

import 'package:srbguide/localization/app_localizations.dart';
import 'package:srbguide/screens/author.dart';
import 'package:srbguide/screens/calculator.dart';
import 'package:srbguide/screens/deadlines.dart';
import 'package:srbguide/screens/exchange_rate.dart';
import 'package:srbguide/screens/journey.dart';
import 'package:srbguide/screens/map.dart';
import 'package:srbguide/screens/places.dart';
import 'package:srbguide/screens/settings.dart';
import 'package:srbguide/screens/tg_chats.dart';
import 'package:srbguide/screens/trains.dart';
import 'package:srbguide/screens/white_cardboard.dart';
import 'package:srbguide/service/url_launcher_helper.dart';

/// Everything that is not the guide itself: calculators, rates, maps, chats
/// and the external links that used to live in the navigation drawer.
class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    final List<_Entry> tools = <_Entry>[
      _Entry(
        icon: Icons.checklist_rtl,
        title: l10n.translate('my_path'),
        push: (_) => const JourneyScreen(),
      ),
      _Entry(
        icon: Icons.notifications_active_outlined,
        title: l10n.translate('deadlines'),
        push: (_) => const DeadlinesScreen(),
      ),
      _Entry(
        icon: Icons.event_available_outlined,
        title: l10n.translate('calculator_visarun'),
        push: (_) => const VisaFreeCalculatorScreen(),
      ),
      _Entry(
        icon: Icons.description_outlined,
        title: l10n.translate('create_whiteboard'),
        push: (_) => const CreateWhiteCardboardScreen(),
      ),
      _Entry(
        icon: Icons.currency_exchange,
        title: l10n.translate('exchange_rate'),
        push: (_) => const ExchangeRateScreen(),
      ),
      _Entry(
        icon: Icons.calculate_outlined,
        title: l10n.translate('flat_tax_calculator'),
        url:
            'https://eporezi.purs.gov.rs/kalkulator-pausalnog-poreza-i-doprinosa.html',
      ),
    ];

    final List<_Entry> places = <_Entry>[
      _Entry(
        icon: Icons.place_outlined,
        title: l10n.translate('places'),
        push: (_) => const PlacesScreen(),
      ),
      _Entry(
        icon: Icons.map_outlined,
        title: l10n.translate('maps'),
        push: (_) => const MapScreen(),
      ),
      _Entry(
        icon: Icons.train_outlined,
        title: l10n.translate('trains'),
        push: (_) => const TrainsScreen(),
      ),
      _Entry(
        icon: Icons.forum_outlined,
        title: l10n.translate('tg_chats'),
        push: (_) => const TgChatScreen(),
      ),
      _Entry(
        icon: Icons.apartment_outlined,
        title: l10n.translate('embassy'),
        url: 'https://belgrad.kdmid.ru/queue',
      ),
    ];

    final List<_Entry> about = <_Entry>[
      _Entry(
        icon: Icons.settings_outlined,
        title: l10n.translate('settings'),
        push: (_) => const SettingsScreen(),
      ),
      _Entry(
        icon: Icons.person_outline,
        title: l10n.translate('author'),
        push: (_) => const AuthorScreen(),
      ),
      _Entry(
        icon: Icons.privacy_tip_outlined,
        title: l10n.translate('privacy_policy'),
        url: 'https://github.com/ialakey/privacy_policy',
      ),
    ];

    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar.large(title: Text(l10n.translate('service'))),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
            sliver: SliverList(
              delegate: SliverChildListDelegate(<Widget>[
                _Group(title: l10n.translate('quick_actions'), entries: tools),
                const SizedBox(height: 20),
                _Group(title: l10n.translate('maps'), entries: places),
                const SizedBox(height: 20),
                _Group(title: l10n.translate('help'), entries: about),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  final String title;
  final List<_Entry> entries;

  const _Group({required this.title, required this.entries});

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
        ),
        Card(
          child: Column(
            children: <Widget>[
              for (int i = 0; i < entries.length; i++) ...<Widget>[
                if (i > 0)
                  Divider(height: 1, indent: 56, color: scheme.outlineVariant),
                ListTile(
                  shape: const RoundedRectangleBorder(),
                  leading: Icon(entries[i].icon, color: scheme.primary),
                  title: Text(entries[i].title,
                      style: const TextStyle(fontSize: 15)),
                  trailing: Icon(
                    entries[i].url != null
                        ? Icons.open_in_new
                        : Icons.chevron_right,
                    size: entries[i].url != null ? 18 : 22,
                    color: scheme.onSurfaceVariant,
                  ),
                  onTap: () {
                    final _Entry e = entries[i];
                    if (e.url != null) {
                      UrlLauncherHelper.launchURL(e.url!);
                    } else if (e.push != null) {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: e.push!),
                      );
                    }
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Entry {
  final IconData icon;
  final String title;
  final WidgetBuilder? push;
  final String? url;

  const _Entry({
    required this.icon,
    required this.title,
    this.push,
    this.url,
  });
}
