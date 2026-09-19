import 'package:counter/models/counter.dart';
import 'package:counter/models/folder.dart';
import 'package:counter/models/sorting_options.dart';
import 'package:counter/providers/counters_provider.dart';
import 'package:counter/widgets/counter_grid_item.dart';
import 'package:counter/widgets/editable_counter_grid.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';

import '../helpers/fake_counter_repository.dart';
import '../helpers/fake_wakelock.dart';
import '../helpers/test_app.dart';

void main() {
  late FakeCounterRepository repository;
  late Folder folder;
  late List<Counter> counters;

  setUp(() {
    repository = FakeCounterRepository();
    folder = repository.seedFolder('Work');
    counters = <Counter>[
      for (final String name in <String>['A', 'B', 'C', 'D'])
        repository.seedCounter(name: name, folder: folder),
    ];
    installFakeWakelock();
  });

  Future<void> pumpEditableGrid(WidgetTester tester) async {
    await pumpApp(
      tester,
      EditableCounterGrid(counters: counters),
      repository: repository,
    );
    await tester
        .container()
        .read(countersProvider.notifier)
        .setFolderId(folder.id!);
    await tester.pumpAndSettle();
  }

  /// ReorderableGridView reports the index the tile lands on, already adjusted
  /// for the removal. That is the same contract as onReorderItem, which is why
  /// the grid no longer passes `newIndex + 1`.
  Future<void> reorder(WidgetTester tester, int from, int to) async {
    final ReorderableGridView grid = tester.widget<ReorderableGridView>(
      find.byType(ReorderableGridView),
    );
    grid.onReorder(from, to);
    await tester.pumpAndSettle();
  }

  List<String> persistedOrder() {
    final List<Counter> sorted = repository.counters.values.toList()
      ..sort(
        (Counter a, Counter b) =>
            (a.orderInFolder ?? 0) - (b.orderInFolder ?? 0),
      );
    return sorted.map((Counter counter) => counter.name!).toList();
  }

  testWidgets('renders one tile per counter, all inactive', (tester) async {
    await pumpEditableGrid(tester);

    expect(find.byType(CounterGridItem), findsNWidgets(4));
    expect(
      tester
          .widgetList<CounterGridItem>(find.byType(CounterGridItem))
          .every((CounterGridItem item) => !item.active),
      isTrue,
      reason: 'an active tile would count up on the start of a drag',
    );
  });

  testWidgets('moving a tile down persists the new order', (tester) async {
    await pumpEditableGrid(tester);

    await reorder(tester, 0, 2);

    expect(repository.calls, contains('reorderCounters(4)'));
    expect(persistedOrder(), <String>['B', 'C', 'A', 'D']);
  });

  testWidgets('moving a tile up persists the new order', (tester) async {
    await pumpEditableGrid(tester);

    await reorder(tester, 3, 1);

    expect(persistedOrder(), <String>['A', 'D', 'B', 'C']);
  });

  testWidgets('the grid and the list agree on what an index means', (
    tester,
  ) async {
    // The grid used to pass `newIndex + 1` to compensate for the list's old
    // unadjusted index. Both now speak the same language, so the same drag
    // must land in the same place in either view.
    await pumpEditableGrid(tester);

    await reorder(tester, 1, 3);

    expect(persistedOrder(), <String>['A', 'C', 'D', 'B']);
  });

  testWidgets('a reorder switches the sorting to custom', (tester) async {
    await pumpEditableGrid(tester);

    await reorder(tester, 0, 1);

    expect(repository.settings.counterSorting, SortingOptions.custom);
  });
}
