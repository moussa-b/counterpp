import 'package:counter/models/counter.dart';
import 'package:counter/models/folder.dart';
import 'package:counter/models/sorting_options.dart';
import 'package:counter/providers/folders_provider.dart';
import 'package:counter/repository/database_counter_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_container.dart';
import '../helpers/test_database.dart';

void main() {
  initializeTestDatabaseFactory();

  late ProviderContainer container;
  late DatabaseCounterRepository repository;
  late FoldersNotifier notifier;

  setUp(() async {
    final result = await openTestContainer();
    container = result.container;
    repository = result.repository;
    notifier = container.read(foldersProvider.notifier);
    // build() hits the database, so nothing is readable until it resolves.
    await container.read(foldersProvider.future);
  });

  /// The folders the notifier currently exposes, in order.
  ///
  /// Mutators call `update(...)` without awaiting it, so the new state lands a
  /// microtask later. See the same helper in counters_provider_test.
  Future<List<String>> names() async {
    await pumpEventQueue();
    return container
        .read(foldersProvider)
        .value!
        .map((Folder folder) => folder.name!)
        .toList();
  }

  Future<List<String>> persistedNames() async {
    final List<Folder> folders = await repository.getAllFoldersSorted(
      SortingOptions.custom,
    );
    return folders.map((Folder folder) => folder.name!).toList();
  }

  group('build', () {
    test('starts from what the database holds', () async {
      expect(await names(), isEmpty);
    });
  });

  group('addFolder', () {
    test('appends the created folder', () async {
      final Folder? created = await notifier.addFolder('Work');

      expect(created!.id, greaterThan(0));
      expect(await names(), <String>['Work']);
    });
  });

  group('renameFolder', () {
    test('replaces the folder in place, keeping its position', () async {
      await notifier.addFolder('Work');
      final Folder? home = await notifier.addFolder('Home');
      await notifier.addFolder('Study');

      await notifier.renameFolder(home!.id!, 'Renamed');

      expect(await names(), <String>['Work', 'Renamed', 'Study']);
    });
  });

  group('deleteFolderById', () {
    test('drops the folder from the list', () async {
      final Folder? work = await notifier.addFolder('Work');
      await notifier.addFolder('Home');

      final bool deleted = await notifier.deleteFolderById(work!.id!);

      expect(deleted, isTrue);
      expect(await names(), <String>['Home']);
    });
  });

  group('duplicateFolderById', () {
    test('appends a copy carrying the suffix', () async {
      final Folder? work = await notifier.addFolder('Work');

      final Folder? copy = await notifier.duplicateFolderById(
        work!.id!,
        suffix: ' (copy)',
      );

      expect(copy!.name, 'Work (copy)');
      expect(await names(), <String>['Work', 'Work (copy)']);
    });

    test('copies the folder but not the counters inside it', () async {
      final Folder? work = await notifier.addFolder('Work');
      await repository.createCounter(
        Counter(name: 'Alpha', counterCount: 3, folder: work, step: 1),
      );

      final Folder? copy = await notifier.duplicateFolderById(work!.id!);

      expect(await repository.getCountersByFolderId(copy!.id!), isEmpty);
    });
  });

  group('resetAllCountersForFolderId', () {
    test('zeroes every counter in the folder', () async {
      final Folder? work = await notifier.addFolder('Work');
      final Counter alpha = await repository.createCounter(
        Counter(name: 'Alpha', counterCount: 5, folder: work, step: 1),
      );
      final Counter beta = await repository.createCounter(
        Counter(name: 'Beta', counterCount: 9, folder: work, step: 1),
      );

      expect(await notifier.resetAllCountersForFolderId(work!.id!), isTrue);

      expect((await repository.getCounterById(alpha.id!)).counterCount, 0);
      expect((await repository.getCounterById(beta.id!)).counterCount, 0);
    });
  });

  group('deleteAllCountersForFolderId', () {
    test('empties the folder and shows it as holding none', () async {
      final Folder? work = await notifier.addFolder('Work');
      await repository.createCounter(
        Counter(name: 'Alpha', counterCount: 5, folder: work, step: 1),
      );
      notifier.refresh();
      await pumpEventQueue();

      final bool cleared = await notifier.deleteAllCountersForFolderId(
        work!.id!,
      );

      expect(cleared, isTrue);
      expect(await repository.getCountersByFolderId(work.id!), isEmpty);
      await pumpEventQueue();
      expect(container.read(foldersProvider).value!.single.counterNumber, 0);
    });
  });

  group('onReorder', () {
    // newIndex is the index the folder ends up at once it has been removed
    // from oldIndex, matching ReorderableListView.onReorderItem.
    Future<void> seedFourFolders() async {
      for (final String name in <String>['A', 'B', 'C', 'D']) {
        await notifier.addFolder(name);
      }
      expect(await names(), <String>['A', 'B', 'C', 'D']);
    }

    test(
      'moving a folder down lands it on the index it was dropped at',
      () async {
        await seedFourFolders();

        await notifier.onReorder(0, 2);

        expect(await names(), <String>['B', 'C', 'A', 'D']);
        expect(await persistedNames(), <String>['B', 'C', 'A', 'D']);
      },
    );

    test(
      'moving a folder up lands it on the index it was dropped at',
      () async {
        await seedFourFolders();

        await notifier.onReorder(3, 1);

        expect(await names(), <String>['A', 'D', 'B', 'C']);
        expect(await persistedNames(), <String>['A', 'D', 'B', 'C']);
      },
    );

    test('reordering onto the same index changes nothing', () async {
      await seedFourFolders();

      await notifier.onReorder(2, 2);

      expect(await names(), <String>['A', 'B', 'C', 'D']);
      expect(await persistedNames(), <String>['A', 'B', 'C', 'D']);
    });

    test('the new order survives a refresh from the database', () async {
      await seedFourFolders();
      await notifier.onReorder(0, 2);

      final settings = await repository.getSettings();
      settings.folderSorting = SortingOptions.custom;
      await repository.updateSettings(settings);
      notifier.refresh();
      await pumpEventQueue();

      expect(await names(), <String>['B', 'C', 'A', 'D']);
    });
  });
}
