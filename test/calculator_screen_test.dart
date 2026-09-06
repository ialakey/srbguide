// The visa calculator screen: it has to render, take a trip, and show a result.

import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:srbguide/data/visa_rule.dart';
import 'package:srbguide/localization/app_localizations.dart';
import 'package:srbguide/screens/calculator.dart';
import 'package:srbguide/theme/app_theme.dart';

/// Hands the widget tree an already-loaded [AppLocalizations].
///
/// The real delegate reads its `.arb` from the asset bundle. That is real file
/// I/O, which makes no progress inside `pumpAndSettle`'s fake async once the
/// test framework has dropped the bundle cache — so from the second test in a
/// file onwards the app renders nothing at all. Loading the strings once in
/// `setUpAll`, where async is real, and returning them synchronously here keeps
/// every test deterministic.
class _LoadedLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _LoadedLocalizationsDelegate(this.value);

  final AppLocalizations value;

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AppLocalizations> load(Locale locale) =>
      SynchronousFuture<AppLocalizations>(value);

  @override
  bool shouldReload(_LoadedLocalizationsDelegate old) => false;
}

late AppLocalizations _english;

/// Pumps the screen on a phone-shaped surface.
///
/// The default 800x600 test window is too short for the screen's own list, and
/// a lazy `ListView` never builds what is off-screen — assertions about the
/// trips section would otherwise fail for the wrong reason.
Future<void> _pumpScreen(WidgetTester tester) async {
  // getInstance() caches its instance for the whole process, so without this
  // every test after the first reads the first one's values.
  SharedPreferences.resetStatic();

  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.5;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      locale: const Locale('en'),
      supportedLocales: const <Locale>[Locale('en'), Locale('ru')],
      localizationsDelegates: <LocalizationsDelegate<dynamic>>[
        _LoadedLocalizationsDelegate(_english),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const VisaFreeCalculatorScreen(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    _english = AppLocalizations();
    await _english.load(const Locale('en'));
  });

  testWidgets('renders the empty state and all three rules', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await _pumpScreen(tester);

    expect(find.text('30 days per entry'), findsOneWidget);
    expect(find.text('90 days in any 180'), findsOneWidget);
    expect(find.text('30 days in any 365'), findsOneWidget);
    expect(find.text('No trips recorded yet.'), findsOneWidget);
  });

  testWidgets('the trip editor opens and is actually laid out', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await _pumpScreen(tester);

    // With no trips yet the empty state carries the only add button.
    await tester.tap(find.widgetWithText(FilledButton, 'Add trip'));
    await tester.pumpAndSettle();

    // The sheet used to render with no height at all — invisible, and throwing
    // nothing — so this asserts on the painted size, not just on presence.
    expect(find.text('Entry date'), findsOneWidget);
    expect(find.text('Still in Serbia'), findsOneWidget);
    expect(tester.getSize(find.text('Save')).height, greaterThan(0));
  });

  testWidgets('a saved trip drives the day counter', (
    WidgetTester tester,
  ) async {
    // Entered nine days ago, so today is the tenth day of the stay. Today is
    // both a day used and a day still available, which is why 10 and 21 do not
    // add up to 30 — you may lawfully still be here today.
    final DateTime entry = addDays(dateOnly(DateTime.now()), -9);
    SharedPreferences.setMockInitialValues(<String, Object>{
      'visa_rule': 'perEntry30',
      'visa_stays': '[{"entry":"${entry.toIso8601String()}","exit":null}]',
    });
    await _pumpScreen(tester);

    expect(find.text('21'), findsOneWidget, reason: 'days left');
    expect(find.text('10 of 30 days used'), findsOneWidget);
    // The tile renders one string, "<date> -> Still in Serbia".
    expect(find.textContaining('Still in Serbia'), findsOneWidget);
  });

  testWidgets('the single date the old screen stored is carried over', (
    WidgetTester tester,
  ) async {
    // The old screen saved only an exit date, 29 days after the entry.
    final DateTime exit = addDays(dateOnly(DateTime.now()), 5);
    SharedPreferences.setMockInitialValues(<String, Object>{
      'exitDate': exit.toIso8601String(),
    });
    await _pumpScreen(tester);

    expect(find.text('6'), findsOneWidget, reason: 'today plus five days left');
    expect(find.text('No trips recorded yet.'), findsNothing);
  });

  testWidgets('an exhausted allowance is called out as an overstay', (
    WidgetTester tester,
  ) async {
    // Entered 40 days ago on a 30-day allowance and never left.
    final DateTime entry = addDays(dateOnly(DateTime.now()), -40);
    SharedPreferences.setMockInitialValues(<String, Object>{
      'visa_rule': 'perEntry30',
      'visa_stays': '[{"entry":"${entry.toIso8601String()}","exit":null}]',
    });
    await _pumpScreen(tester);

    expect(find.text('0'), findsOneWidget, reason: 'nothing left');
    expect(
      find.textContaining('Overstaying means a fine'),
      findsOneWidget,
      reason: 'the warning has to be on the card, not just implied',
    );
  });

  testWidgets('a rolling rule counts every day in the window', (
    WidgetTester tester,
  ) async {
    // 30 days in the country, then a visa run: the window does not reset.
    final DateTime entry = addDays(dateOnly(DateTime.now()), -40);
    final DateTime exit = addDays(entry, 29);
    SharedPreferences.setMockInitialValues(<String, Object>{
      'visa_rule': 'rolling90in180',
      'visa_stays': '[{"entry":"${entry.toIso8601String()}",'
          '"exit":"${exit.toIso8601String()}"}]',
    });
    await _pumpScreen(tester);

    expect(find.text('60'), findsOneWidget, reason: '90 less the 30 used');
    expect(find.text('30 of 90 days used'), findsOneWidget);
  });
}
