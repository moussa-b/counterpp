import 'package:counter/models/counter.dart';
import 'package:counter/models/folder.dart';
import 'package:counter/models/sorting_options.dart';
import 'package:counter/models/statistics.dart';
import 'package:counter/repository/database_counter_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_database.dart';

/// Ids 1 are the built-in "Default folder" / "Default counter" seeded by
/// counter_table_populate.sql. They back the home tab and must never appear in
/// user-facing lists, statistics or synchronization payloads.
const int builtInFolderId = 1;
const int builtInCounterId = 1;

void main() {
  initializeTestDatabaseFactory();

  late DatabaseCounterRepository repository;

  setUp(() async {
    repository = await openTestRepository();
  });

  Future<Folder> createFolder(String name) => repository.createFolder(name);

  /// The history triggers only fire when an access token is stored, so tests
  /// that assert on pending deletions have to opt in first.
  Future<void> enableSynchronizationToken() async {
    final settings = await repository.getSettings();
    settings.synchronizationAccessToken = 'test-token';
    settings.synchronizationApiUrl = 'https://example.invalid/api';
    await repository.updateSettings(settings);
  }

  Future<Counter> createCounter(String name, {Folder? folder, int count = 0}) {
    return repository.createCounter(
      Counter(name: name, counterCount: count, folder: folder, step: 1),
    );
  }

  group('getAllCountersToSynchronize', () {
    test('returns a counter that has never been synchronized', () async {
      final Folder folder = await createFolder('Work');
      final Counter counter = await createCounter('Verses', folder: folder);

      final List<Counter> pending = await repository
          .getAllCountersToSynchronize();

      expect(pending.map((Counter c) => c.id), contains(counter.id));
    });

    test('returns a counter modified after its last synchronization', () async {
      final Folder folder = await createFolder('Work');
      final Counter counter = await createCounter('Verses', folder: folder);
      await repository.updateCountersSynchronizationTimestamp([counter.id!]);
      expect(await repository.getAllCountersToSynchronize(), isEmpty);

      // Timestamps have millisecond resolution, so without this the update can
      // land in the same millisecond as the synchronization marker.
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await repository.incrementCounterById(counter.id!);

      final List<Counter> pending = await repository
          .getAllCountersToSynchronize();
      expect(pending.map((Counter c) => c.id), contains(counter.id));
    });

    test('drops a counter synchronized after its last modification', () async {
      final Folder folder = await createFolder('Work');
      final Counter counter = await createCounter('Verses', folder: folder);
      await repository.incrementCounterById(counter.id!);
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await repository.updateCountersSynchronizationTimestamp([counter.id!]);

      expect(await repository.getAllCountersToSynchronize(), isEmpty);
    });

    test(
      'never returns the built-in counter, even once it carries a stale marker',
      () async {
        // Regression: the WHERE clause read `id > 1 AND sync IS NULL OR sync <
        // lastMod`, which SQLite groups as `(id > 1 AND sync IS NULL) OR (sync <
        // lastMod)`. The id guard silently stopped applying to the second branch,
        // so the internal counter leaked into the payload sent to the server.
        await repository.updateCountersSynchronizationTimestampByFolderId(
          builtInFolderId,
        );
        await Future<void>.delayed(const Duration(milliseconds: 5));
        await repository.incrementCounterById(builtInCounterId);

        final List<Counter> pending = await repository
            .getAllCountersToSynchronize();

        expect(
          pending.map((Counter c) => c.id),
          isNot(contains(builtInCounterId)),
        );
      },
    );
  });

  group('getAllFoldersToSynchronize', () {
    test('returns a new folder but never the built-in one', () async {
      final Folder folder = await createFolder('Work');

      final List<Folder> pending = await repository
          .getAllFoldersToSynchronize();

      expect(pending.map((Folder f) => f.id), contains(folder.id));
      expect(pending.map((Folder f) => f.id), isNot(contains(builtInFolderId)));
    });
  });

  group('ordering', () {
    test(
      'a counter created after a deletion does not reuse a live order',
      () async {
        // Regression: order came from `1 + COUNT(*)`. After deleting one of three
        // counters the count no longer matched the highest order, so the next
        // counter was handed an order that was already taken and the two rows
        // sorted arbitrarily.
        final Folder folder = await createFolder('Work');
        final Counter first = await createCounter('First', folder: folder);
        final Counter second = await createCounter('Second', folder: folder);
        final Counter third = await createCounter('Third', folder: folder);

        await repository.deleteCounterById(second.id!);
        final Counter fourth = await createCounter('Fourth', folder: folder);

        final List<Counter> counters = await repository.getCountersByFolderId(
          folder.id!,
        );
        final List<int> orders =
            counters.map((Counter c) => c.orderInFolder!).toList()..sort();
        expect(
          orders.toSet(),
          hasLength(orders.length),
          reason: 'orderInFolder must stay unique',
        );
        expect(fourth.orderInFolder, greaterThan(third.orderInFolder!));
        expect(
          counters.map((Counter c) => c.id),
          containsAll(<int>[first.id!, third.id!, fourth.id!]),
        );

        final List<int> globalOrders = (await repository.getAllCounters())
            .map((Counter c) => c.counterOrder!)
            .toList();
        expect(
          globalOrders.toSet(),
          hasLength(globalOrders.length),
          reason: 'counterOrder must stay unique',
        );
      },
    );

    test(
      'a folder created after a deletion does not reuse a live order',
      () async {
        final Folder first = await createFolder('First');
        final Folder second = await createFolder('Second');
        await repository.deleteFolderById(first.id!);
        final Folder third = await createFolder('Third');

        expect(third.folderOrder, greaterThan(second.folderOrder!));
        final List<int> orders = (await repository.getAllFolders())
            .map((Folder f) => f.folderOrder!)
            .toList();
        expect(orders.toSet(), hasLength(orders.length));
      },
    );

    test(
      'a counter created without a folder gets a null orderInFolder',
      () async {
        final Counter counter = await createCounter('Loose');

        expect(counter.folder, isNull);
        expect(counter.orderInFolder, isNull);
        expect(counter.counterOrder, isNotNull);
      },
    );
  });

  group('statistics', () {
    test('a reset records exactly one RESET entry', () async {
      final Folder folder = await createFolder('Work');
      final Counter counter = await createCounter(
        'Verses',
        folder: folder,
        count: 12,
      );

      await repository.resetCounterById(counter.id!);

      final List<Statistics> statistics = await repository.getAllStatistics();
      expect(statistics, hasLength(1));
      expect(statistics.single.type, StatisticsType.RESET);
      expect(statistics.single.counterId, counter.id);
      expect(statistics.single.folderId, folder.id);
      expect((await repository.getCounterById(counter.id!)).counterCount, 0);
    });

    test('resetting an unknown counter records nothing', () async {
      // Regression: addStatistics ran before the affected row count was
      // checked, so a reset that updated zero rows still charted as a reset.
      final bool updated = await repository.resetCounterById(9999);

      expect(updated, isFalse);
      expect(await repository.getAllStatistics(), isEmpty);
    });

    test('increment and decrement record their own type and value', () async {
      final Folder folder = await createFolder('Work');
      final Counter counter = await createCounter('Verses', folder: folder);

      await repository.incrementCounterById(counter.id!, value: 3);
      await repository.decrementCounterById(counter.id!, value: 2);

      final List<Statistics> statistics = await repository.getAllStatistics();
      expect(
        statistics.map((Statistics s) => s.type),
        containsAll(<StatisticsType>[
          StatisticsType.INCREMENT,
          StatisticsType.DECREMENT,
        ]),
      );
      expect(
        statistics
            .firstWhere((Statistics s) => s.type == StatisticsType.INCREMENT)
            .value,
        3,
      );
      expect(
        statistics
            .firstWhere((Statistics s) => s.type == StatisticsType.DECREMENT)
            .value,
        2,
      );
      expect((await repository.getCounterById(counter.id!)).counterCount, 1);
    });

    test('incrementing an unknown counter records nothing', () async {
      expect(await repository.incrementCounterById(9999), isFalse);
      expect(await repository.getAllStatistics(), isEmpty);
    });

    test('the built-in counter is never tracked', () async {
      await repository.incrementCounterById(builtInCounterId, value: 5);
      await repository.resetCounterById(builtInCounterId);

      expect(await repository.getAllStatistics(), isEmpty);
    });

    test('addStatisticsForFolder honours the requested type', () async {
      // Regression: the method took a StatisticsType but hardcoded RESET, so
      // any other type would have been charted as a reset.
      final Folder folder = await createFolder('Work');
      await createCounter('First', folder: folder);
      await createCounter('Second', folder: folder);

      await repository.addStatisticsForFolder(
        folder.id!,
        StatisticsType.INCREMENT,
      );

      final List<Statistics> statistics = await repository.getAllStatistics();
      expect(statistics, hasLength(2));
      expect(
        statistics.every((Statistics s) => s.type == StatisticsType.INCREMENT),
        isTrue,
      );
    });

    test('resetting a whole folder records one entry per counter', () async {
      final Folder folder = await createFolder('Work');
      await createCounter('First', folder: folder, count: 4);
      await createCounter('Second', folder: folder, count: 7);

      await repository.resetAllCountersForFolderId(folder.id!);

      final List<Statistics> statistics = await repository.getAllStatistics();
      expect(statistics, hasLength(2));
      expect(
        statistics.every((Statistics s) => s.type == StatisticsType.RESET),
        isTrue,
      );
      final List<Counter> counters = await repository.getCountersByFolderId(
        folder.id!,
      );
      expect(counters.every((Counter c) => c.counterCount == 0), isTrue);
    });

    test('getCounterStatistics filters on the requested window', () async {
      final Folder folder = await createFolder('Work');
      final Counter counter = await createCounter('Verses', folder: folder);
      await repository.incrementCounterById(counter.id!);

      final DateTime now = DateTime.now();
      final List<Statistics> inWindow = await repository.getCounterStatistics(
        counter.id!,
        now.subtract(const Duration(minutes: 1)),
        now.add(const Duration(minutes: 1)),
      );
      final List<Statistics> outOfWindow = await repository
          .getCounterStatistics(
            counter.id!,
            now.subtract(const Duration(days: 2)),
            now.subtract(const Duration(days: 1)),
          );

      expect(inWindow, hasLength(1));
      expect(outOfWindow, isEmpty);
    });
  });

  group('updateCounter', () {
    test('accepts a counter that has no folder', () async {
      // Regression: the update read counter.folder!.id and threw for any
      // counter whose folderId was NULL.
      final Folder folder = await createFolder('Work');
      final Counter counter = await createCounter('Verses', folder: folder);

      counter.folder = null;
      counter.name = 'Renamed';
      final Counter updated = await repository.updateCounter(counter);

      expect(updated.name, 'Renamed');
      expect(updated.folder, isNull);
      expect((await repository.getCounterById(counter.id!)).folder, isNull);
    });

    test('persists the edited fields', () async {
      final Folder folder = await createFolder('Work');
      final Counter counter = await createCounter('Verses', folder: folder);

      counter.name = 'Surahs';
      counter.counterLimit = 40;
      counter.step = 5;
      counter.note = 'evening';
      await repository.updateCounter(counter);

      final Counter reloaded = await repository.getCounterById(counter.id!);
      expect(reloaded.name, 'Surahs');
      expect(reloaded.counterLimit, 40);
      expect(reloaded.step, 5);
      expect(reloaded.note, 'evening');
    });
  });

  group('deletion', () {
    test('deleting a folder cascades to its counters', () async {
      // This cascade is what made the recover flow dangerous: deleting folders
      // before knowing the replacement payload had counters destroyed them all.
      final Folder folder = await createFolder('Work');
      await createCounter('First', folder: folder);
      await createCounter('Second', folder: folder);

      await repository.deleteFolderById(folder.id!);

      expect(await repository.getCountersByFolderId(folder.id!), isEmpty);
      expect(await repository.getAllCounters(), isEmpty);
    });

    test(
      'deleteAllFolders keeps the built-in folder and reports the deletion',
      () async {
        await createFolder('Work');
        await createFolder('Home');

        expect(await repository.deleteAllFolders(), isTrue);

        expect(await repository.getAllFolders(), isEmpty);
        expect(
          (await repository.getFolderById(builtInFolderId)).id,
          builtInFolderId,
        );
      },
    );

    test(
      'deleteAllFolders reports false when there is nothing to delete',
      () async {
        expect(await repository.deleteAllFolders(), isFalse);
      },
    );

    test(
      'a deleted counter becomes a pending deletion once sync is configured',
      () async {
        await enableSynchronizationToken();
        final Folder folder = await createFolder('Work');
        final Counter counter = await createCounter('Verses', folder: folder);

        await repository.deleteCounterById(counter.id!);

        expect(
          await repository.getAllDeletedCounterIdsToSynchronize(),
          contains(counter.id),
        );
      },
    );

    test(
      'a deleted folder becomes a pending deletion once sync is configured',
      () async {
        await enableSynchronizationToken();
        final Folder folder = await createFolder('Work');

        await repository.deleteFolderById(folder.id!);

        expect(
          await repository.getAllDeletedFolderIdsToSynchronize(),
          contains(folder.id),
        );
      },
    );

    test(
      'deleting a folder queues its cascaded counters for deletion too',
      () async {
        // The counters go away through the ON DELETE CASCADE, not through
        // deleteCounterById, so only the history trigger can report them.
        await enableSynchronizationToken();
        final Folder folder = await createFolder('Work');
        final Counter counter = await createCounter('Verses', folder: folder);

        await repository.deleteFolderById(folder.id!);

        expect(
          await repository.getAllDeletedCounterIdsToSynchronize(),
          contains(counter.id),
        );
      },
    );

    test(
      'deletions are not recorded while synchronization is disabled',
      () async {
        // The history triggers are guarded on a non-empty access token: with sync
        // off there is no server to inform, so no history is accumulated.
        final Folder folder = await createFolder('Work');
        final Counter counter = await createCounter('Verses', folder: folder);

        await repository.deleteCounterById(counter.id!);
        await repository.deleteFolderById(folder.id!);

        expect(
          await repository.getAllDeletedCounterIdsToSynchronize(),
          isEmpty,
        );
        expect(await repository.getAllDeletedFolderIdsToSynchronize(), isEmpty);
      },
    );

    test(
      'deleteAllCountersForFolderId only clears the target folder',
      () async {
        final Folder kept = await createFolder('Kept');
        final Folder cleared = await createFolder('Cleared');
        await createCounter('Survivor', folder: kept);
        await createCounter('Doomed', folder: cleared);

        expect(
          await repository.deleteAllCountersForFolderId(cleared.id!),
          isTrue,
        );

        expect(await repository.getCountersByFolderId(cleared.id!), isEmpty);
        expect(await repository.getCountersByFolderId(kept.id!), hasLength(1));
      },
    );
  });

  group('settings', () {
    test('round-trips through the database', () async {
      final settings = await repository.getSettings();
      settings.activateSounds = true;
      settings.keepScreenOn = true;
      settings.showTutorial = false;
      settings.lastOpenedTabIndex = 2;
      settings.synchronizationApiUrl = 'https://example.com/api';
      settings.synchronizationAccessToken = 'token-123';

      await repository.updateSettings(settings);

      final reloaded = await repository.getSettings();
      expect(reloaded.activateSounds, isTrue);
      expect(reloaded.keepScreenOn, isTrue);
      expect(reloaded.showTutorial, isFalse);
      expect(reloaded.lastOpenedTabIndex, 2);
      expect(reloaded.synchronizationApiUrl, 'https://example.com/api');
      expect(reloaded.synchronizationAccessToken, 'token-123');
    });

    test('updating the settings never creates a second row', () async {
      await repository.updateSettings(await repository.getSettings());
      await repository.updateSettings(await repository.getSettings());

      // getSettings returns a blank Settings when the row count is not exactly
      // one, so a duplicated row would surface as a lost configuration.
      final settings = await repository.getSettings();
      settings.activateVibrator = true;
      await repository.updateSettings(settings);
      expect((await repository.getSettings()).activateVibrator, isTrue);
    });

    test(
      'resetting the synchronization markers makes everything pending again',
      () async {
        final Folder folder = await createFolder('Work');
        final Counter counter = await createCounter('Verses', folder: folder);
        await repository.updateCountersSynchronizationTimestamp([counter.id!]);
        await repository.updateFoldersSynchronizationTimestamp([folder.id!]);
        expect(await repository.getAllCountersToSynchronize(), isEmpty);

        await repository.resetCountersSynchronizationTimeStamp();
        await repository.resetFoldersSynchronizationTimeStamp();

        expect(await repository.getAllCountersToSynchronize(), hasLength(1));
        expect(await repository.getAllFoldersToSynchronize(), hasLength(1));
      },
    );
  });

  group('batch import', () {
    test('inserts counters whose folder arrives as a nested object', () async {
      final Folder folder = await createFolder('Work');
      final Counter counter = await createCounter('Verses', folder: folder);
      final Map<String, Object?> exported = counter.toJson();
      await repository.deleteAllCounters();

      await repository.batchInsertCounters(<Map<String, Object?>>[exported]);

      final List<Counter> counters = await repository.getAllCounters();
      expect(counters, hasLength(1));
      expect(counters.single.name, 'Verses');
      expect(counters.single.folder?.id, folder.id);
    });

    test(
      'inserts folders after stripping the computed counterNumber',
      () async {
        final Folder folder = await createFolder('Work');
        final Map<String, Object?> exported = folder.toJson();
        await repository.deleteAllFolders();

        await repository.batchInsertFolders(<Map<String, Object?>>[exported]);

        final List<Folder> folders = await repository.getAllFolders();
        expect(folders, hasLength(1));
        expect(folders.single.name, 'Work');
      },
    );
  });

  group('sorting', () {
    test('orders counters alphabetically in both directions', () async {
      final Folder folder = await createFolder('Work');
      await createCounter('Beta', folder: folder);
      await createCounter('Alpha', folder: folder);

      final ascending = await repository.getCountersByFolderIdSorted(
        folder.id!,
        SortingOptions.alphabeticalAsc,
      );
      final descending = await repository.getCountersByFolderIdSorted(
        folder.id!,
        SortingOptions.alphabeticalDesc,
      );

      expect(ascending.map((Counter c) => c.name), <String>['Alpha', 'Beta']);
      expect(descending.map((Counter c) => c.name), <String>['Beta', 'Alpha']);
    });

    test('orders counters by value', () async {
      final Folder folder = await createFolder('Work');
      await createCounter('Low', folder: folder, count: 1);
      await createCounter('High', folder: folder, count: 9);

      final ascending = await repository.getCountersByFolderIdSorted(
        folder.id!,
        SortingOptions.valueAsc,
      );

      expect(ascending.map((Counter c) => c.name), <String>['Low', 'High']);
    });
  });
}
