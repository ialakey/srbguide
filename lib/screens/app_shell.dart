import 'package:flutter/material.dart';

import 'package:srbguide/localization/app_localizations.dart';
import 'package:srbguide/screens/favourites.dart';
import 'package:srbguide/screens/guide.dart';
import 'package:srbguide/screens/home.dart';
import 'package:srbguide/screens/services.dart';

/// Root navigation.
///
/// Replaces the old drawer-plus-nested-`BottomNavigationBar` arrangement, where
/// each section carried its own bar and the drawer pushed new copies of screens
/// onto the stack. One Material 3 `NavigationBar` now owns the top level and
/// the tabs keep their state.
class AppShell extends StatefulWidget {
  /// Tab to open on launch, from the "main screen" setting.
  final int initialIndex;

  const AppShell({super.key, this.initialIndex = 0});

  @override
  State<AppShell> createState() => AppShellState();

  static AppShellState? of(BuildContext context) =>
      context.findAncestorStateOfType<AppShellState>();
}

class AppShellState extends State<AppShell> {
  late int _index = widget.initialIndex.clamp(0, 3);

  /// Lets other screens jump to a tab, e.g. "open the guide" from home.
  void goTo(int index) => setState(() => _index = index.clamp(0, 3));

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const <Widget>[
          HomeScreen(),
          GuideScreen(),
          ServicesScreen(),
          FavouritesScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: goTo,
        destinations: <NavigationDestination>[
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: l10n.translate('home'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.menu_book_outlined),
            selectedIcon: const Icon(Icons.menu_book),
            label: l10n.translate('guide'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.apps_outlined),
            selectedIcon: const Icon(Icons.apps),
            label: l10n.translate('service'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.bookmark_border),
            selectedIcon: const Icon(Icons.bookmark),
            label: l10n.translate('favourite'),
          ),
        ],
      ),
    );
  }
}
