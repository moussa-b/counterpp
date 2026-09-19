import 'package:counter/l10n/app_localizations.dart';
import 'package:counter/providers/counter_repository_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_counter_repository.dart';

/// Pumps [child] with everything a widget of this app expects around it: a
/// Riverpod scope whose repository is an in-memory fake, the
/// `AppLocalizations` delegates, and a `MaterialApp` to host routes, theming
/// and overlays such as modal bottom sheets.
///
/// Pass [repository] to keep using one you already seeded; otherwise an empty
/// [FakeCounterRepository] is created and returned.
///
/// Set [wrapInScaffold] to false for a widget that builds its own `Scaffold`,
/// which every screen does. Leave it on for the pieces under `lib/widgets/`,
/// since `ListTile`, `Card` and friends need a `Material` ancestor.
///
/// The real app themes with `GoogleFonts.latoTextTheme()`, which reaches for
/// the network the first time it runs. Tests stay on the default text theme so
/// nothing is fetched and no test depends on a font download.
Future<FakeCounterRepository> pumpApp(
  WidgetTester tester,
  Widget child, {
  FakeCounterRepository? repository,
  Locale locale = const Locale('en'),
  bool wrapInScaffold = true,
}) async {
  final FakeCounterRepository repo = repository ?? FakeCounterRepository();
  // The default test surface is 800x600, which is wider and much shorter than
  // any phone this app ships to. Screens built for a tall viewport overflow
  // there and the failure says nothing about real devices. Use a phone-shaped
  // surface so a reported overflow is one a user could actually hit.
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    ProviderScope(
      overrides: [counterRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff0000ff)),
          useMaterial3: true,
        ),
        home: wrapInScaffold ? Scaffold(body: child) : child,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

/// The English strings, read the way the widgets read them.
///
/// Asserting on `l10n(tester).counterName` instead of the literal keeps the
/// tests honest when a translation is reworded, and catches a widget that
/// hardcodes a string instead of going through `AppLocalizations`.
AppLocalizations l10n(WidgetTester tester) {
  // The Navigator sits below MaterialApp's Localizations, so its context can
  // resolve the delegates. The MaterialApp element itself cannot: Localizations
  // is its descendant, not its ancestor.
  return AppLocalizations.of(tester.element(find.byType(Navigator).first))!;
}
