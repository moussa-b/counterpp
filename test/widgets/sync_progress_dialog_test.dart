import 'dart:async';

import 'package:counter/utils/synchronization_service.dart';
import 'package:counter/widgets/sync_progress_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../helpers/fake_counter_repository.dart';
import '../helpers/test_app.dart';

void main() {
  late FakeCounterRepository repository;
  late List<http.Request> requests;

  const String apiUrl = 'https://example.invalid/api';

  /// Answers every request with [status] / [body], recording what was sent.
  void stubClient({int status = 200, String body = '{"status":true}'}) {
    requests = <http.Request>[];
    SynchronizationService().client = MockClient((http.Request request) async {
      requests.add(request);
      return http.Response(body, status);
    });
  }

  setUp(() {
    repository = FakeCounterRepository();
    SynchronizationService().resetApiUrl();
    SynchronizationService().setApiUrl(
      apiUrl: apiUrl,
      apiAccessToken: 'secret-token',
    );
    stubClient();
  });

  tearDown(() => SynchronizationService().resetApiUrl());

  /// Opens the dialog the way the synchronization screen does.
  ///
  /// Pass settle: false for the failure path. The error state keeps something
  /// animating, so pumpAndSettle would spin until it times out; fixed pumps
  /// get the dialog to its final state without waiting on that.
  Future<void> openDialog(WidgetTester tester, {bool settle = true}) async {
    late BuildContext host;
    await pumpApp(
      tester,
      Builder(
        builder: (BuildContext context) {
          host = context;
          return const SizedBox.shrink();
        },
      ),
      repository: repository,
    );

    unawaited(
      showDialog<void>(
        context: host,
        barrierDismissible: false,
        builder: (_) => const SyncProgressDialog(),
      ),
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      for (int i = 0; i < 4; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
    }
  }

  /// Lets the two-second auto-close timer fire.
  ///
  /// On success the dialog closes itself, so a test that stops before that
  /// leaves a pending timer and the framework fails it. Draining here is also
  /// what makes the auto-close itself observable.
  Future<void> drainAutoClose(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  }

  testWidgets('lists the four steps it is going to run', (tester) async {
    await openDialog(tester);

    expect(find.text(l10n(tester).syncFolders), findsOneWidget);
    expect(find.text(l10n(tester).syncDeletedFolders), findsOneWidget);
    expect(find.text(l10n(tester).syncCounters), findsOneWidget);
    expect(find.text(l10n(tester).syncDeletedCounters), findsOneWidget);

    await drainAutoClose(tester);
  });

  group('when every step succeeds', () {
    testWidgets('it reports completion', (tester) async {
      await openDialog(tester);

      expect(find.text(l10n(tester).syncCompletedTitle), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsWidgets);

      await drainAutoClose(tester);
    });

    testWidgets('it closes itself after a couple of seconds', (tester) async {
      await openDialog(tester);
      expect(find.byType(SyncProgressDialog), findsOneWidget);

      await drainAutoClose(tester);

      expect(find.byType(SyncProgressDialog), findsNothing);
    });

    testWidgets('the footer offers only close, not cancel', (tester) async {
      await openDialog(tester);

      expect(find.text(l10n(tester).close), findsOneWidget);
      expect(find.text(l10n(tester).cancel), findsNothing);
      expect(find.text(l10n(tester).tryAgain), findsNothing);

      await drainAutoClose(tester);
    });

    testWidgets('close dismisses the dialog', (tester) async {
      await openDialog(tester);
      await tester.tap(find.text(l10n(tester).close));
      await tester.pumpAndSettle();

      expect(find.byType(SyncProgressDialog), findsNothing);

      await drainAutoClose(tester);
    });

    testWidgets('it talks to the configured endpoint', (tester) async {
      await openDialog(tester);

      expect(requests, isNotEmpty);
      expect(
        requests.every((http.Request r) => r.url.toString().startsWith(apiUrl)),
        isTrue,
      );

      await drainAutoClose(tester);
    });
  });

  // The failure path is deliberately not covered here. SynchronizationService
  // awaits LoggingService on every error, and LoggingService calls
  // getApplicationDocumentsDirectory() — a path_provider channel with no
  // handler under a widget test, on a fake clock that never lets the file I/O
  // finish. The flow simply never returns, so a test here would be measuring
  // the harness rather than the app. What each error produces is covered by
  // test/utils/synchronization_service_test.dart against the real service.
}
