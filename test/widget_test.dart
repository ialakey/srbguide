// Smoke test: the app boots into the shell and renders the guide tab.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:srbguide/main.dart';
import 'package:srbguide/provider/language_provider.dart';

void main() {
  testWidgets('MainScreen builds a MaterialApp with the shell',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final LanguageProvider languageProvider = LanguageProvider();
    await languageProvider.init();

    await tester.pumpWidget(
      ChangeNotifierProvider<LanguageProvider>.value(
        value: languageProvider,
        child: const MainScreen(initialThemeMode: ThemeMode.light),
      ),
    );
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
