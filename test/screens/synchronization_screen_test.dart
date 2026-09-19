import 'package:counter/models/settings.dart';
import 'package:counter/screens/synchronization_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_counter_repository.dart';
import '../helpers/test_app.dart';

void main() {
  late FakeCounterRepository repository;

  setUp(() {
    repository = FakeCounterRepository();
  });

  Future<void> pumpScreen(WidgetTester tester) {
    return pumpApp(
      tester,
      const SynchronizationScreen(),
      repository: repository,
      wrapInScaffold: false,
      // The form plus its buttons is taller than a phone; these tests are
      // about the form, not the scrolling.
      surfaceSize: const Size(390, 1400),
    );
  }

  Finder fieldWithLabel(String label) {
    return find.ancestor(
      of: find.text(label),
      matching: find.byType(TextFormField),
    );
  }

  ElevatedButton buttonWithLabel(WidgetTester tester, String label) {
    return tester.widget<ElevatedButton>(
      find.ancestor(
        of: find.text(label),
        matching: find.byType(ElevatedButton),
      ),
    );
  }

  testWidgets('asks for the url, the user and the password', (tester) async {
    await pumpScreen(tester);

    expect(
      find.text(l10n(tester).synchronizationConfiguration),
      findsOneWidget,
    );
    expect(fieldWithLabel(l10n(tester).synchronizationUrl), findsOneWidget);
    expect(fieldWithLabel(l10n(tester).username), findsOneWidget);
    expect(fieldWithLabel(l10n(tester).password), findsOneWidget);
  });

  testWidgets('validate is disabled until the connection is proven', (
    tester,
  ) async {
    // Saving credentials that were never checked would leave sync silently
    // broken, so the button stays dead until a test succeeds.
    await pumpScreen(tester);

    expect(buttonWithLabel(tester, l10n(tester).validate).onPressed, isNull);
  });

  testWidgets('the test button is offered from the start', (tester) async {
    await pumpScreen(tester);

    expect(
      buttonWithLabel(tester, l10n(tester).testConnection).onPressed,
      isNotNull,
    );
  });

  testWidgets('testing with an empty form is refused before any request', (
    tester,
  ) async {
    await pumpScreen(tester);
    await tester.tap(find.text(l10n(tester).testConnection));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsNothing);
    expect(find.text(l10n(tester).validate), findsOneWidget);
  });

  testWidgets('a failed connection says so and leaves validate dead', (
    tester,
  ) async {
    // flutter_test answers every real HTTP request with a 400, which is
    // exactly the unreachable-server case this screen has to survive.
    await pumpScreen(tester);
    await tester.enterText(
      fieldWithLabel(l10n(tester).synchronizationUrl),
      'https://example.invalid/api',
    );
    await tester.enterText(
      fieldWithLabel(l10n(tester).username),
      'someone@example.invalid',
    );
    await tester.enterText(fieldWithLabel(l10n(tester).password), 'secret');
    await tester.tap(find.text(l10n(tester).testConnection));
    await tester.pumpAndSettle();

    expect(
      find.text(l10n(tester).errorWhenTestTheSynchronization),
      findsOneWidget,
    );
    expect(buttonWithLabel(tester, l10n(tester).validate).onPressed, isNull);
  });

  testWidgets('it opens on an empty form, even once sync is configured', (
    tester,
  ) async {
    // The screen does not prefill from the stored settings, so the url and the
    // credentials have to be typed again on every visit. Pinning it here so a
    // future change to prefill is a deliberate one, not a surprise.
    repository.settings = Settings()
      ..synchronizationApiUrl = 'https://example.invalid/api'
      ..synchronizationAccessToken = 'stored-token';

    await pumpScreen(tester);

    expect(
      find.widgetWithText(TextFormField, 'https://example.invalid/api'),
      findsNothing,
    );
    expect(buttonWithLabel(tester, l10n(tester).validate).onPressed, isNull);
  });

  testWidgets('the password is hidden until asked for', (tester) async {
    await pumpScreen(tester);

    expect(find.byIcon(Icons.visibility), findsOneWidget);

    await tester.tap(find.byIcon(Icons.visibility));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.visibility_off), findsOneWidget);
  });
}
