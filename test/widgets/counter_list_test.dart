import 'package:counter/models/counter.dart';
import 'package:counter/models/folder.dart';
import 'package:counter/models/settings.dart';
import 'package:counter/widgets/counter_list.dart';
import 'package:counter/widgets/counter_list_item.dart';
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
    // CounterList asks the wakelock plugin for its state from its constructor.
    wakelock = installFakeWakelock();
  });

  List<Counter> seedCounters(int count) {
    return <Counter>[
      for (int index = 0; index < count; index++)
        repository.seedCounter(name: 'Counter $index', folder: folder),
    ];
  }

  Future<void> pumpList(
    WidgetTester tester,
    List<Counter> counters, {
    Settings? settings,
  }) {
    return pumpApp(
      tester,
      CounterList(
        counters: counters,
        settings: settings ?? repository.settings,
      ),
      repository: repository,
    );
  }

  testWidgets('renders one row per counter', (tester) async {
    await pumpList(tester, seedCounters(3));

    expect(find.byType(CounterListItem), findsNWidgets(3));
    expect(find.text('Counter 0'), findsOneWidget);
    expect(find.text('Counter 2'), findsOneWidget);
  });

  testWidgets('an empty list renders nothing rather than failing', (
    tester,
  ) async {
    await pumpList(tester, <Counter>[]);

    expect(find.byType(CounterListItem), findsNothing);
  });

  testWidgets('each row carries a key built from the counter id', (
    tester,
  ) async {
    // The key has to change when the counter changes, or a reorder animates
    // the wrong row.
    final List<Counter> counters = seedCounters(2);

    await pumpList(tester, counters);

    final CounterListItem first = tester.widget<CounterListItem>(
      find.byType(CounterListItem).first,
    );
    expect(first.key, isA<ValueKey<String>>());
    expect(
      (first.key! as ValueKey<String>).value,
      startsWith('${counters.first.id}-'),
    );
  });

  testWidgets('the rows are active, so their buttons work', (tester) async {
    await pumpList(tester, seedCounters(1));

    final CounterListItem row = tester.widget<CounterListItem>(
      find.byType(CounterListItem),
    );
    expect(row.active, isTrue);
  });

  group('keep screen on', () {
    testWidgets('turns the wakelock on when the setting asks for it', (
      tester,
    ) async {
      final Settings settings = Settings()..keepScreenOn = true;

      await pumpList(tester, seedCounters(1), settings: settings);

      expect(wakelock.toggles, contains(true));
    });

    testWidgets('leaves it alone when the setting is unset', (tester) async {
      await pumpList(tester, seedCounters(1), settings: Settings());

      expect(wakelock.toggles, isEmpty);
    });

    testWidgets('does not toggle when it already matches', (tester) async {
      wakelock.enabledValue = true;
      final Settings settings = Settings()..keepScreenOn = true;

      await pumpList(tester, seedCounters(1), settings: settings);

      expect(wakelock.toggles, isEmpty);
    });
  });
}
