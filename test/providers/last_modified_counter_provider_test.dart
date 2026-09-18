import 'package:counter/models/counter.dart';
import 'package:counter/models/folder.dart';
import 'package:counter/providers/last_modified_counter_provider.dart';
import 'package:counter/repository/database_counter_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_container.dart';
import '../helpers/test_database.dart';

void main() {
  initializeTestDatabaseFactory();

  late ProviderContainer container;
  late DatabaseCounterRepository repository;
  late LastModifiedCounterNotifier notifier;

  setUp(() async {
    final result = await openTestContainer();
    container = result.container;
    repository = result.repository;
    notifier = container.read(lastModifiedCounterProvider.notifier);
  });

  Future<Counter?> current() async {
    await pumpEventQueue();
    return container.read(lastModifiedCounterProvider).value;
  }

  Future<Counter> createCounter(String name, Folder folder) {
    return repository.createCounter(
      Counter(name: name, counterCount: 0, folder: folder, step: 1),
    );
  }

  test('starts empty', () async {
    expect(await current(), isNull);
  });

  test('setFolderId surfaces the most recently touched counter', () async {
    final Folder folder = await repository.createFolder('Work');
    final Counter alpha = await createCounter('Alpha', folder);
    final Counter beta = await createCounter('Beta', folder);
    await repository.incrementCounterById(beta.id!);
    // Timestamps have millisecond resolution, so without this the two
    // increments can tie and the ORDER BY picks either one.
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await repository.incrementCounterById(alpha.id!);

    await notifier.setFolderId(folder.id!);

    expect((await current())!.id, alpha.id);
  });

  test(
    'a counter that was never modified has no modification timestamp',
    () async {
      // createCounter writes creationTimeStamp but leaves
      // lastModificationTimeStamp null, so until a counter is actually touched
      // the "last modified" query has nothing to order by and returns whichever
      // row SQLite hands back first.
      final Folder folder = await repository.createFolder('Work');
      final Counter alpha = await createCounter('Alpha', folder);

      expect(alpha.lastModificationTimeStamp, isNull);

      await notifier.setFolderId(folder.id!);

      expect((await current())!.id, alpha.id);
    },
  );

  test('an increment moves the banner to that counter', () async {
    final Folder folder = await repository.createFolder('Work');
    final Counter alpha = await createCounter('Alpha', folder);
    await createCounter('Beta', folder);
    await notifier.setFolderId(folder.id!);

    // Timestamps have millisecond resolution, so without this the increment
    // can land in the same millisecond as Beta's creation.
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await repository.incrementCounterById(alpha.id!);
    notifier.refresh();

    expect((await current())!.id, alpha.id);
  });

  test('folder id 0 clears it instead of showing another folder', () async {
    final Folder folder = await repository.createFolder('Work');
    await createCounter('Alpha', folder);
    await notifier.setFolderId(folder.id!);
    expect(await current(), isNotNull);

    await notifier.setFolderId(0);

    expect(await current(), isNull);
  });

  test('an empty folder has nothing to show', () async {
    final Folder folder = await repository.createFolder('Empty');

    await notifier.setFolderId(folder.id!);

    expect(await current(), isNull);
  });

  test('refresh is a no-op while no folder is selected', () async {
    final Folder folder = await repository.createFolder('Work');
    await createCounter('Alpha', folder);

    notifier.refresh();

    expect(await current(), isNull);
  });
}
