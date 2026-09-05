import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:srbguide/localization/app_localizations.dart';
import 'package:srbguide/service/url_launcher_helper.dart';

/// About the author: contact links and ways to support the project.
class AuthorScreen extends StatelessWidget {
  const AuthorScreen({super.key});

  static const List<_Link> _links = <_Link>[
    _Link(
      icon: Icons.work_outline,
      label: 'LinkedIn',
      value: 'ilia-alakov',
      url: 'https://www.linkedin.com/in/ilia-alakov/',
    ),
    _Link(
      icon: Icons.code,
      label: 'GitHub',
      value: 'ialakey',
      url: 'https://github.com/ialakey',
    ),
    _Link(
      icon: Icons.article_outlined,
      label: 'Medium',
      value: '@alakov.ilia',
      url: 'https://medium.com/@alakov.ilia',
    ),
    _Link(
      icon: Icons.rss_feed,
      label: 'Habr',
      value: 'i_alakey',
      url: 'https://habr.com/ru/users/i_alakey/',
    ),
    _Link(
      icon: Icons.mail_outline,
      label: 'Email',
      value: 'alakov.ilia@gmail.com',
      url: 'mailto:alakov.ilia@gmail.com',
      copyValue: 'alakov.ilia@gmail.com',
    ),
  ];

  static const List<_Crypto> _crypto = <_Crypto>[
    _Crypto(
      coin: 'USDT',
      network: 'Tron (TRC20)',
      address: 'TUHt3r2ufuMabviaowEsQmynoV1tYE6DFg',
    ),
    _Crypto(
      coin: 'BTC',
      network: 'Bitcoin',
      address: '17RQZqoUcy4jmkk5ciYQAV3DfZU9MfBYX1',
    ),
    _Crypto(
      coin: 'ETH',
      network: 'Ethereum (ERC20)',
      address: '0xc3ca11d069f67ffa826ce6172f0e5466b66ef3f8',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.translate('author'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: <Widget>[
          Card(
            color: scheme.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: scheme.surface,
                    child: ClipOval(
                      child: Image.asset(
                        'assets/serbia.png',
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'Ilia Alakov',
                          style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.translate('info_by_author'),
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: scheme.onSecondaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          _Heading(l10n.translate('contacts')),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: <Widget>[
                for (int i = 0; i < _links.length; i++) ...<Widget>[
                  if (i > 0)
                    Divider(
                        height: 1, indent: 56, color: scheme.outlineVariant),
                  ListTile(
                    shape: const RoundedRectangleBorder(),
                    leading: Icon(_links[i].icon, color: scheme.primary),
                    title: Text(_links[i].label,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      _links[i].value,
                      style: TextStyle(
                          fontSize: 12.5, color: scheme.onSurfaceVariant),
                    ),
                    trailing: Icon(Icons.open_in_new,
                        size: 18, color: scheme.onSurfaceVariant),
                    onTap: () => UrlLauncherHelper.launchURL(_links[i].url),
                    onLongPress: _links[i].copyValue == null
                        ? null
                        : () => _copy(context, _links[i].copyValue!),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 22),
          _Heading(l10n.translate('support_author')),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    l10n.translate('crypto'),
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  ..._crypto.map(
                    (_Crypto c) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Text(
                                c.coin,
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                c.network,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: scheme.onSurfaceVariant),
                              ),
                              const Spacer(),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(Icons.copy, size: 18),
                                onPressed: () => _copy(context, c.address),
                              ),
                            ],
                          ),
                          SelectableText(
                            c.address,
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          _Heading(l10n.translate('links')),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: <Widget>[
                ListTile(
                  shape: const RoundedRectangleBorder(),
                  leading: Icon(Icons.source_outlined, color: scheme.primary),
                  title: const Text('github.com/ialakey/srbguide',
                      style: TextStyle(fontSize: 14)),
                  trailing: Icon(Icons.open_in_new,
                      size: 18, color: scheme.onSurfaceVariant),
                  onTap: () => UrlLauncherHelper.launchURL(
                      'https://github.com/ialakey/srbguide'),
                ),
                Divider(height: 1, indent: 56, color: scheme.outlineVariant),
                ListTile(
                  shape: const RoundedRectangleBorder(),
                  leading:
                      Icon(Icons.privacy_tip_outlined, color: scheme.primary),
                  title: Text(l10n.translate('privacy_policy'),
                      style: const TextStyle(fontSize: 14)),
                  trailing: Icon(Icons.open_in_new,
                      size: 18, color: scheme.onSurfaceVariant),
                  onTap: () => UrlLauncherHelper.launchURL(
                      'https://github.com/ialakey/privacy_policy'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Text(
            l10n.translate('content_source_note'),
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  void _copy(BuildContext context, String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.translate('copied')),
          duration: const Duration(seconds: 2),
        ),
      );
  }
}

class _Heading extends StatelessWidget {
  final String text;

  const _Heading(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(
          text,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      );
}

class _Link {
  final IconData icon;
  final String label;
  final String value;
  final String url;
  final String? copyValue;

  const _Link({
    required this.icon,
    required this.label,
    required this.value,
    required this.url,
    this.copyValue,
  });
}

class _Crypto {
  final String coin;
  final String network;
  final String address;

  const _Crypto({
    required this.coin,
    required this.network,
    required this.address,
  });
}
