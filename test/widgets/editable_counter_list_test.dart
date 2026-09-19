import 'package:counter/models/counter.dart';
import 'package:counter/models/folder.dart';
import 'package:counter/models/sorting_options.dart';
import 'package:counter/providers/counters_provider.dart';
import 'package:counter/widgets/counter_list_item.dart';
import 'package:counter/widgets/editable_counter_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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

  Future<void> pumpEditableList(WidgetTester tester) async {
    await pumpApp(
      tester,
      EditableCounterList(counters: counters),
      repository: repository,
    );
    // The notifier reorders its own state, so it has to be holding the folder
    // the list is showing. The screen does this before switching to edit mode.
    await tester
        .container()
        .read(countersProvider.notifier)
        .setFolderId(folder.id!);
    await tester.pumpAndSettle();
  }

  /// Drives the reorder the way ReorderableListView does once a drag lands.
  Future<void> reorder(WidgetTester tester, int from, int to) async {
    final ReorderableListView list = tester.widget<ReorderableListView>(
      find.byType(ReorderableListView),
    );
    // ReorderCallback returns void, so the async work it starts is only
    // observable by settling afterwards.
    list.onReorderItem!(from, to);
    await tester.pumpAndSettle();
  }

  /// The order the repository was told to persist.
  List<String> persistedOrder() {
    final List<Counter> sorted = repository.counters.values.toList()
      ..sort(
        (Counter a, Counter b) =>
            (a.orderInFolder ?? 0) - (b.orderInFolder ?? 0),
      );
    return sorted.map((Counter counter) => counter.name!).toList();
  }

  testWidgets('renders one row per counter, all inactive', (tester) async {
    await pumpEditableList(tester);

    expect(find.byType(CounterListItem), findsNWidgets(4));
    expect(
      tester
          .widgetList<CounterListItem>(find.byType(CounterListItem))
          .every((CounterListItem item) => !item.active),
      isTrue,
      reason: 'an active row would treat the start of a drag as a tap',
    );
  });

  testWidgets('uses onReorderItem, not the deprecated onReorder', (
    tester,
  ) async {
    // onReorder reports an unadjusted index. Wiring the callback to it again
    // would shift every downward move by one.
    await pumpEditableList(tester);

    final ReorderableListView list = tester.widget<ReorderableListView>(
      find.byType(ReorderableListView),
    );
    expect(list.onReorderItem, isNotNull);
    expect(list.onReorder, isNull);
  });

  group('reordering', () {
    testWidgets('moving a counter down persists the new order', (tester) async {
      await pumpEditableList(tester);

      await reorder(tester, 0, 2);

      expect(repository.calls, contains('reorderCounters(4)'));
      expect(persistedOrder(), <String>['B', 'C', 'A', 'D']);
    });

    testWidgets('moving a counter up persists the new order', (tester) async {
      await pumpEditableList(tester);

      await reorder(tester, 3, 1);

      expect(persistedOrder(), <String>['A', 'D', 'B', 'C']);
    });

    testWidgets('a reorder switches the sorting to custom', (tester) async {
      // Any stored sort would fight the manual order on the next load, so the
      // list takes ownership of the ordering.
      await pumpEditableList(tester);

      await reorder(tester, 0, 1);

      expect(repository.settings.counterSorting, SortingOptions.custom);
      expect(repository.calls, contains('updateSettings()'));
    });
  });
}
