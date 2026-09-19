import 'package:counter/models/counter.dart';
import 'package:counter/models/folder.dart';
import 'package:counter/models/settings.dart';
import 'package:counter/widgets/counter_progress.dart';
import 'package:counter/widgets/counter_widget.dart';
import 'package:counter/widgets/loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_counter_repository.dart';
import '../helpers/fake_wakelock.dart';
import '../helpers/test_app.dart';

void main() {
  late FakeCounterRepository repository;
  late FakeWakelock wakelock;
  late Folder folder;

  setUp(() {
    repository = FakeCounterRepository();
    folder = repository.seedFolder('Work');
    wakelock = installFakeWakelock();
  });

  Counter seed({String name = 'Verses', int count = 0, int? limit}) {
    return repository.seedCounter(
      name: name,
      folder: folder,
      count: count,
      limit: limit,
    );
  }

  /// Pumps the widget and hands back the reset callback it publishes, which is
  /// what the counter screen wires to the app bar button.
  Future<void Function()?> pumpCounter(
    WidgetTester tester,
    int counterId,
  ) async {
    void Function()? resetCounter;
    await pumpApp(
      tester,
      CounterWidget(
        counterId: counterId,
        builder: (BuildContext context, void Function() reset) {
          resetCounter = reset;
        },
      ),
      repository: repository,
    );
    return resetCounter;
  }

  testWidgets('shows the value once the counter has loaded', (tester) async {
    final Counter counter = seed(count: 7);

    await pumpCounter(tester, counter.id!);

    expect(find.byType(LoadingIndicator), findsNothing);
    expect(find.text('7'), findsOneWidget);
    expect(find.byType(CounterProgress), findsOneWidget);
  });

  group('the name', () {
    testWidgets('is shown for a counter the user created', (tester) async {
      seed(name: 'Built-in'); // takes id 1
      final Counter counter = seed(name: 'Verses');

      await pumpCounter(tester, counter.id!);

      expect(find.text('Verses'), findsOneWidget);
    });

    testWidgets('is hidden for the built-in counter', (tester) async {
      // Id 1 is the home tab's own counter. The tab already says what it is,
      // so repeating the name above the ring would be noise.
      final Counter builtIn = seed(name: 'Built-in');
      expect(builtIn.id, 1);

      await pumpCounter(tester, builtIn.id!);

      expect(find.text('Built-in'), findsNothing);
    });
  });

  testWidgets('shows the objective when the counter has a limit', (
    tester,
  ) async {
    final Counter counter = seed(limit: 20);

    await pumpCounter(tester, counter.id!);

    expect(find.text('${l10n(tester).objective} : 20'), findsOneWidget);
  });

  testWidgets('shows no objective without a limit', (tester) async {
    final Counter counter = seed();

    await pumpCounter(tester, counter.id!);

    expect(find.textContaining(l10n(tester).objective), findsNothing);
  });

  group('counting', () {
    testWidgets('tapping the ring counts up', (tester) async {
      final Counter counter = seed(count: 0);

      await pumpCounter(tester, counter.id!);
      await tester.tap(find.byType(CounterProgress));
      await tester.pumpAndSettle();

      expect(find.text('1'), findsOneWidget);
      expect(repository.calls, contains('incrementCounterById(${counter.id})'));
    });

    testWidgets('the -1 button counts down', (tester) async {
      final Counter counter = seed(count: 4);

      await pumpCounter(tester, counter.id!);
      await tester.tap(find.text('-1'));
      await tester.pumpAndSettle();

      expect(find.text('3'), findsOneWidget);
      expect(repository.calls, contains('decrementCounterById(${counter.id})'));
    });

    testWidgets('the -1 button is disabled at zero', (tester) async {
      final Counter counter = seed(count: 0);

      await pumpCounter(tester, counter.id!);

      final ElevatedButton button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, '-1'),
      );
      expect(button.onPressed, isNull);
    });
  });

  testWidgets('the published reset callback zeroes the counter', (
    tester,
  ) async {
    final Counter counter = seed(count: 9);

    final void Function()? reset = await pumpCounter(tester, counter.id!);
    reset!();
    await tester.pumpAndSettle();

    expect(repository.calls, contains('resetCounterById(${counter.id})'));
    expect(find.text('0'), findsOneWidget);
  });

  group('keep screen on', () {
    testWidgets('turns the wakelock on when the setting asks for it', (
      tester,
    ) async {
      repository.settings = Settings()..keepScreenOn = true;
      final Counter counter = seed();

      await pumpCounter(tester, counter.id!);

      expect(wakelock.toggles, contains(true));
    });

    testWidgets('leaves it alone when the setting is unset', (tester) async {
      final Counter counter = seed();

      await pumpCounter(tester, counter.id!);

      expect(wakelock.toggles, isEmpty);
    });
  });
}
