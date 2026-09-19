import 'package:counter/models/settings.dart';
import 'package:counter/screens/settings_screen.dart';
import 'package:counter/utils/synchronization_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_counter_repository.dart';
import '../helpers/test_app.dart';

void main() {
  const MethodChannel packageInfoChannel = MethodChannel(
    'dev.fluttercommunity.plus/package_info',
  );
  late FakeCounterRepository repository;

  setUpAll(() {
    // The screen shows the app version, which comes from a plugin channel with
    // no implementation in a test.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(packageInfoChannel, (MethodCall call) async {
          return <String, dynamic>{
            'appName': 'Counter++',
            'packageName': 'com.bdzapps.counter.counter',
            'version': '1.0.10',
            'buildNumber': '11',
          };
        });
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(packageInfoChannel, null);
  });

  setUp(() {
    repository = FakeCounterRepository();
    SynchronizationService().resetApiUrl();
  });

  tearDown(() => SynchronizationService().resetApiUrl());

  Future<void> pumpSettings(WidgetTester tester) {
    return pumpApp(
      tester,
      const SettingsScreen(),
      repository: repository,
      // The settings list is far taller than a phone; these tests are about
      // the entries, not the scrolling.
      surfaceSize: const Size(390, 2400),
    );
  }

  CheckboxListTile checkboxWithTitle(WidgetTester tester, String title) {
    return tester.widget<CheckboxListTile>(
      find.ancestor(
        of: find.text(title),
        matching: find.byType(CheckboxListTile),
      ),
    );
  }

  group('the sections', () {
    testWidgets('group the entries under headings', (tester) async {
      await pumpSettings(tester);

      expect(find.text(l10n(tester).controls), findsOneWidget);
      expect(find.text(l10n(tester).display), findsOneWidget);
      expect(find.text(l10n(tester).advanced), findsOneWidget);
    });

    testWidgets('offer the data entries', (tester) async {
      await pumpSettings(tester);

      expect(find.text(l10n(tester).deleteAllCounters), findsOneWidget);
      expect(find.text(l10n(tester).importData), findsOneWidget);
    });

    testWidgets('show the app version', (tester) async {
      await pumpSettings(tester);

      expect(find.text(l10n(tester).version), findsOneWidget);
      expect(find.text('1.0.10'), findsOneWidget);
    });
  });

  group('the toggles', () {
    testWidgets('start from what is stored', (tester) async {
      repository.settings = Settings()
        ..activateSounds = true
        ..activateVibrator = false
        ..keepScreenOn = true;

      await pumpSettings(tester);

      expect(
        checkboxWithTitle(tester, l10n(tester).activateSounds).value,
        isTrue,
      );
      expect(
        checkboxWithTitle(tester, l10n(tester).activateVibrator).value,
        isFalse,
      );
      expect(
        checkboxWithTitle(tester, l10n(tester).keepScreenOn).value,
        isTrue,
      );
    });

    testWidgets('an unset toggle reads as off rather than crashing', (
      tester,
    ) async {
      await pumpSettings(tester);

      expect(
        checkboxWithTitle(tester, l10n(tester).activateSounds).value,
        isFalse,
      );
    });

    testWidgets('turning sounds on writes it through', (tester) async {
      await pumpSettings(tester);
      await tester.tap(find.text(l10n(tester).activateSounds));
      await tester.pumpAndSettle();

      expect(repository.settings.activateSounds, isTrue);
      expect(repository.calls, contains('updateSettings()'));
    });

    testWidgets('turning vibration on writes it through', (tester) async {
      await pumpSettings(tester);
      await tester.tap(find.text(l10n(tester).activateVibrator));
      await tester.pumpAndSettle();

      expect(repository.settings.activateVibrator, isTrue);
    });

    testWidgets('turning keep-screen-on off again writes it through', (
      tester,
    ) async {
      repository.settings = Settings()..keepScreenOn = true;

      await pumpSettings(tester);
      await tester.tap(find.text(l10n(tester).keepScreenOn));
      await tester.pumpAndSettle();

      expect(repository.settings.keepScreenOn, isFalse);
    });
  });

  group('the synchronization entries', () {
    testWidgets('are hidden until synchronization is configured', (
      tester,
    ) async {
      await pumpSettings(tester);

      expect(find.text(l10n(tester).synchronizeData), findsNothing);
      expect(find.text(l10n(tester).recoverData), findsNothing);
    });

    testWidgets('appear once the service has a url and a token', (
      tester,
    ) async {
      // The screen asks the service, not the settings row, so configuring the
      // service is what turns these entries on.
      SynchronizationService().setApiUrl(
        apiUrl: 'https://example.invalid/api',
        apiAccessToken: 'stored-token',
      );

      await pumpSettings(tester);

      expect(find.text(l10n(tester).synchronizeData), findsOneWidget);
      expect(find.text(l10n(tester).recoverData), findsOneWidget);
    });
  });

  testWidgets('deleting all counters asks before doing it', (tester) async {
    repository.seedCounter(name: 'Verses');

    await pumpSettings(tester);
    await tester.tap(find.text(l10n(tester).deleteAllCounters));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(repository.counters, isNotEmpty);
  });
}
