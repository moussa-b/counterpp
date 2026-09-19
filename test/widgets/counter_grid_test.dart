import 'package:counter/models/counter.dart';
import 'package:counter/models/folder.dart';
import 'package:counter/models/settings.dart';
import 'package:counter/widgets/counter_grid.dart';
import 'package:counter/widgets/counter_grid_item.dart';
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

  List<Counter> seedCounters(int count) {
    return <Counter>[
      for (int index = 0; index < count; index++)
        repository.seedCounter(name: 'Counter $index', folder: folder),
    ];
  }

  Future<void> pumpGrid(
    WidgetTester tester,
    List<Counter> counters, {
    Settings? settings,
  }) {
    return pumpApp(
      tester,
      CounterGrid(
        counters: counters,
        settings: settings ?? repository.settings,
      ),
      repository: repository,
    );
  }

  testWidgets('renders one tile per counter, two to a row', (tester) async {
    await pumpGrid(tester, seedCounters(4));

    expect(find.byType(CounterGridItem), findsNWidgets(4));
    final SliverGridDelegateWithFixedCrossAxisCount delegate =
        tester.widget<GridView>(find.byType(GridView)).gridDelegate
            as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, 2);
  });

  testWidgets('an empty grid renders nothing rather than failing', (
    tester,
  ) async {
    await pumpGrid(tester, <Counter>[]);

    expect(find.byType(CounterGridItem), findsNothing);
  });

  testWidgets('each tile carries a key built from the counter id', (
    tester,
  ) async {
    final List<Counter> counters = seedCounters(2);

    await pumpGrid(tester, counters);

    final CounterGridItem first = tester.widget<CounterGridItem>(
      find.byType(CounterGridItem).first,
    );
    expect(
      (first.key! as ValueKey<String>).value,
      startsWith('${counters.first.id}-'),
    );
  });

  testWidgets('the tiles are active, so tapping them counts', (tester) async {
    await pumpGrid(tester, seedCounters(1));

    expect(
      tester.widget<CounterGridItem>(find.byType(CounterGridItem)).active,
      isTrue,
    );
  });

  testWidgets('keep screen on reaches the wakelock', (tester) async {
    final Settings settings = Settings()..keepScreenOn = true;

    await pumpGrid(tester, seedCounters(1), settings: settings);

    expect(wakelock.toggles, contains(true));
  });
}
