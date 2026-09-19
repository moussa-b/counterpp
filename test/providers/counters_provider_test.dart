import 'package:counter/models/counter.dart';
import 'package:counter/models/folder.dart';
import 'package:counter/models/sorting_options.dart';
import 'package:counter/providers/counters_provider.dart';
import 'package:counter/repository/database_counter_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_container.dart';
import '../helpers/test_database.dart';

void main() {
  initializeTestDatabaseFactory();

  late ProviderContainer container;
  late DatabaseCounterRepository repository;
  late CountersNotifier notifier;

  setUp(() async {
    final result = await openTestContainer();
    container = result.container;
    repository = result.repository;
    notifier = container.read(countersProvider.notifier);
  });

  Future<Counter> createCounter(String name, Folder folder, {int count = 0}) {
    return repository.createCounter(
      Counter(name: name, counterCount: count, folder: folder, step: 1),
    );
  }

  /// The counters the notifier currently exposes, in order.
  ///
  /// Every mutator calls `update(...)` without awaiting it, so the new state
  /// lands a microtask after the method's own future completes. Draining the
  /// event queue here keeps that detail out of each test. The UI never notices
  /// because it rebuilds on the state change rather than on the call.
  Future<List<String>> names() async {
    await pumpEventQueue();
    return container
        .read(countersProvider)
        .value!
        .map((Counter counter) => counter.name!)
        .toList();
  }

  /// The order the database actually persisted, which is what survives a
  /// restart. `custom` sorting reads `orderInFolder`.
  Future<List<String>> persistedNames(int folderId) async {
    final List<Counter> counters = await repository.getCountersByFolderIdSorted(
      folderId,
      SortingOptions.custom,
    );
    return counters.map((Counter counter) => counter.name!).toList();
  }

  group('setFolderId', () {
    test('loads the counters of that folder', () async {
      final Folder folder = await repository.createFolder('Work');
      await createCounter('Alpha', folder);
      await createCounter('Beta', folder);

      await notifier.setFolderId(folder.id!);

      expect(await names(), <String>['Alpha', 'Beta']);
    });

    test('leaves out the counters of other folders', () async {
      final Folder work = await repository.createFolder('Work');
      final Folder home = await repository.createFolder('Home');
      await createCounter('Alpha', work);
      await createCounter('Elsewhere', home);

      await notifier.setFolderId(work.id!);

      expect(await names(), <String>['Alpha']);
    });

    test(
      'folder id 0 empties the list instead of loading everything',
      () async {
        final Folder folder = await repository.createFolder('Work');
        await createCounter('Alpha', folder);
        await notifier.setFolderId(folder.id!);
        expect(await names(), isNotEmpty);

        await notifier.setFolderId(0);

        expect(await names(), isEmpty);
      },
    );
  });

  group('addCounter', () {
    test('appends a counter created in the folder being shown', () async {
      final Folder folder = await repository.createFolder('Work');
      await notifier.setFolderId(folder.id!);

      final Counter? created = await notifier.addCounter(
        Counter(name: 'Alpha', counterCount: 0, folder: folder, step: 1),
      );

      expect(created, isNotNull);
      expect(await names(), <String>['Alpha']);
    });

    test('does not append a counter created in another folder', () async {
      final Folder work = await repository.createFolder('Work');
      final Folder home = await repository.createFolder('Home');
      await notifier.setFolderId(work.id!);

      await notifier.addCounter(
        Counter(name: 'Elsewhere', counterCount: 0, folder: home, step: 1),
      );

      expect(await names(), isEmpty);
    });
  });

  group('updateCounter', () {
    test('replaces the counter in place, keeping its position', () async {
      final Folder folder = await repository.createFolder('Work');
      await createCounter('Alpha', folder);
      final Counter beta = await createCounter('Beta', folder);
      await createCounter('Gamma', folder);
      await notifier.setFolderId(folder.id!);

      beta.name = 'Renamed';
      await notifier.updateCounter(beta);

      expect(await names(), <String>['Alpha', 'Renamed', 'Gamma']);
    });
  });

  group('deleteCounter', () {
    test('drops the counter from the list', () async {
      final Folder folder = await repository.createFolder('Work');
      final Counter alpha = await createCounter('Alpha', folder);
      await createCounter('Beta', folder);
      await notifier.setFolderId(folder.id!);

      final bool deleted = await notifier.deleteCounter(alpha);

      expect(deleted, isTrue);
      expect(await names(), <String>['Beta']);
    });
  });

  group('duplicateCounterById', () {
    test('appends a copy with the suffix and a zeroed count', () async {
      final Folder folder = await repository.createFolder('Work');
      final Counter alpha = await createCounter('Alpha', folder, count: 42);
      await notifier.setFolderId(folder.id!);

      final Counter? copy = await notifier.duplicateCounterById(
        alpha.id!,
        suffix: ' (copy)',
      );

      expect(copy!.name, 'Alpha (copy)');
      expect(copy.counterCount, 0);
      expect(await names(), <String>['Alpha', 'Alpha (copy)']);
    });

    test('keeps the original count when asked not to reset it', () async {
      final Folder folder = await repository.createFolder('Work');
      final Counter alpha = await createCounter('Alpha', folder, count: 42);
      await notifier.setFolderId(folder.id!);

      final Counter? copy = await notifier.duplicateCounterById(
        alpha.id!,
        resetValue: false,
      );

      expect(copy!.counterCount, 42);
    });
  });

  group('resetCounterById', () {
    test('zeroes the count both in the list and in the database', () async {
      final Folder folder = await repository.createFolder('Work');
      final Counter alpha = await createCounter('Alpha', folder, count: 7);
      await notifier.setFolderId(folder.id!);

      final bool reset = await notifier.resetCounterById(alpha.id!);

      expect(reset, isTrue);
      await pumpEventQueue();
      expect(container.read(countersProvider).value!.single.counterCount, 0);
      expect((await repository.getCounterById(alpha.id!)).counterCount, 0);
    });
  });

  group('a counter outside the list being shown', () {
    // The bottom sheet can act on a counter the notifier is not currently
    // holding. indexWhere returns -1 there, and indexing with it used to throw
    // a RangeError that took the app down.
    test('resetCounterById does not blow up', () async {
      final Folder folder = await repository.createFolder('Work');
      final Counter elsewhere = await createCounter('Elsewhere', folder);
      await notifier.setFolderId(0);

      expect(await notifier.resetCounterById(elsewhere.id!), isTrue);
      expect(await names(), isEmpty);
      expect((await repository.getCounterById(elsewhere.id!)).counterCount, 0);
    });

    test('updateCounter does not blow up', () async {
      final Folder work = await repository.createFolder('Work');
      final Folder home = await repository.createFolder('Home');
      final Counter elsewhere = await createCounter('Elsewhere', home);
      await notifier.setFolderId(work.id!);

      elsewhere.name = 'Renamed';
      expect(await notifier.updateCounter(elsewhere), isNotNull);
      expect(await names(), isEmpty);
    });
  });

  group('onReorder', () {
    // newIndex is the index the counter ends up at once it has been removed
    // from oldIndex. That is what ReorderableListView.onReorderItem and
    // ReorderableGridView.onReorder both report, and getting it wrong shifts
    // every move by one.
    Future<Folder> seedFourCounters() async {
      final Folder folder = await repository.createFolder('Work');
      for (final String name in <String>['A', 'B', 'C', 'D']) {
        await createCounter(name, folder);
      }
      await notifier.setFolderId(folder.id!);
      expect(await names(), <String>['A', 'B', 'C', 'D']);
      return folder;
    }

    test(
      'moving an item down lands it on the index it was dropped at',
      () async {
        final Folder folder = await seedFourCounters();

        await notifier.onReorder(0, 2);

        expect(await names(), <String>['B', 'C', 'A', 'D']);
        expect(await persistedNames(folder.id!), <String>['B', 'C', 'A', 'D']);
      },
    );

    test('moving an item up lands it on the index it was dropped at', () async {
      final Folder folder = await seedFourCounters();

      await notifier.onReorder(3, 1);

      expect(await names(), <String>['A', 'D', 'B', 'C']);
      expect(await persistedNames(folder.id!), <String>['A', 'D', 'B', 'C']);
    });

    test('moving to the last index puts the item at the end', () async {
      final Folder folder = await seedFourCounters();

      await notifier.onReorder(0, 3);

      expect(await names(), <String>['B', 'C', 'D', 'A']);
      expect(await persistedNames(folder.id!), <String>['B', 'C', 'D', 'A']);
    });

    test('reordering onto the same index changes nothing', () async {
      final Folder folder = await seedFourCounters();

      await notifier.onReorder(1, 1);

      expect(await names(), <String>['A', 'B', 'C', 'D']);
      expect(await persistedNames(folder.id!), <String>['A', 'B', 'C', 'D']);
    });

    test('the new order survives a reload from the database', () async {
      final Folder folder = await seedFourCounters();
      await notifier.onReorder(0, 2);

      // Sorting has to be custom for orderInFolder to be honoured, which is
      // what the screens set after a manual reorder.
      final settings = await repository.getSettings();
      settings.counterSorting = SortingOptions.custom;
      await repository.updateSettings(settings);
      await notifier.setFolderId(folder.id!);

      expect(await names(), <String>['B', 'C', 'A', 'D']);
    });
  });
}
