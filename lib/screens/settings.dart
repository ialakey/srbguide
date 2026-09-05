import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:srbguide/dialogs/confirm.dart';
import 'package:srbguide/dialogs/success.dart';
import 'package:srbguide/localization/app_localizations.dart';
import 'package:srbguide/main.dart';
import 'package:srbguide/provider/language_provider.dart';
import 'package:srbguide/service/url_launcher_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const List<String> _tabKeys = <String>[
    'home',
    'guide',
    'service',
    'favourite',
  ];

  SharedPreferences? _prefs;
  int _startTab = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _prefs = prefs;
      _startTab = prefs.getInt('mainTabIndex') ?? 0;
    });
  }

  Future<void> _setStartTab(int index) async {
    setState(() => _startTab = index);
    await _prefs?.setInt('mainTabIndex', index);
  }

  Future<void> _setLocale(String code) async {
    Provider.of<LanguageProvider>(context, listen: false)
        .updateLocale(Locale(code, ''));
  }

  void _confirmClear() {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    CustomConfirmationDialog.show(
      context: context,
      title: l10n.translate('confirmation'),
      text: l10n.translate('confirm_clear_data'),
      iconPath: 'assets/gifs_24x24/warning.gif',
      confirmBtnText: l10n.translate('yes'),
      cancelBtnText: l10n.translate('no'),
      onConfirmBtnTap: () async {
        Navigator.of(context).pop();
        await _prefs?.clear();
        if (!mounted) return;
        setState(() => _startTab = 0);
        CustomSuccessDialog.show(
          context: context,
          title: '${l10n.translate('cleared')}!',
        );
      },
      onCancelBtnTap: () => Navigator.of(context).pop(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final LanguageProvider language = Provider.of<LanguageProvider>(context);
    final MainScreenState? root = MainScreen.of(context);
    final bool isDark = root?.themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.translate('settings'))),
      body: _prefs == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: <Widget>[
                _Heading(l10n.translate('settings')),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: <Widget>[
                      SwitchListTile(
                        secondary: Icon(
                          isDark ? Icons.dark_mode : Icons.light_mode,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        title: Text(l10n
                            .translate(isDark ? 'dark_theme' : 'light_theme')),
                        value: isDark,
                        onChanged: (bool v) => root?.setThemeMode(
                            v ? ThemeMode.dark : ThemeMode.light),
                      ),
                      const Divider(height: 1, indent: 56),
                      ListTile(
                        shape: const RoundedRectangleBorder(),
                        leading: Icon(Icons.translate,
                            color: Theme.of(context).colorScheme.primary),
                        title: Text(l10n.translate('language')),
                        trailing: SegmentedButton<String>(
                          style: const ButtonStyle(
                            visualDensity: VisualDensity.compact,
                          ),
                          segments: <ButtonSegment<String>>[
                            ButtonSegment<String>(
                              value: 'ru',
                              label: Text(l10n.translate('russian')),
                            ),
                            ButtonSegment<String>(
                              value: 'en',
                              label: Text(l10n.translate('english')),
                            ),
                          ],
                          selected: <String>{
                            language.selectedLocale.languageCode
                          },
                          showSelectedIcon: false,
                          onSelectionChanged: (Set<String> s) =>
                              _setLocale(s.first),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _Heading(l10n.translate('main_screen')),
                const SizedBox(height: 8),
                Card(
                  child: RadioGroup<int>(
                    groupValue: _startTab,
                    onChanged: (int? v) => _setStartTab(v ?? 0),
                    child: Column(
                      children: <Widget>[
                        for (int i = 0; i < _tabKeys.length; i++)
                          RadioListTile<int>(
                            value: i,
                            title: Text(l10n.translate(_tabKeys[i])),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _Heading(l10n.translate('data')),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: <Widget>[
                      ListTile(
                        shape: const RoundedRectangleBorder(),
                        leading: Icon(Icons.delete_outline,
                            color: Theme.of(context).colorScheme.error),
                        title: Text(l10n.translate('clear_data')),
                        onTap: _confirmClear,
                      ),
                      const Divider(height: 1, indent: 56),
                      ListTile(
                        shape: const RoundedRectangleBorder(),
                        leading: Icon(Icons.privacy_tip_outlined,
                            color: Theme.of(context).colorScheme.primary),
                        title: Text(l10n.translate('privacy_policy')),
                        trailing: const Icon(Icons.open_in_new, size: 18),
                        onTap: () => UrlLauncherHelper.launchURL(
                            'https://github.com/ialakey/privacy_policy'),
                      ),
                    ],
                  ),
                ),
              ],
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
