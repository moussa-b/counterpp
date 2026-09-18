import 'package:counter/models/settings.dart';
import 'package:counter/models/sorting_options.dart';
import 'package:counter/providers/settings_provider.dart';
import 'package:counter/repository/database_counter_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_container.dart';
import '../helpers/test_database.dart';

void main() {
  initializeTestDatabaseFactory();

  late ProviderContainer container;
  late DatabaseCounterRepository repository;
  late SettingsNotifier notifier;

  setUp(() async {
    final result = await openTestContainer();
    container = result.container;
    repository = result.repository;
    notifier = container.read(settingsProvider.notifier);
    await container.read(settingsProvider.future);
  });

  Future<Settings> current() async {
    await pumpEventQueue();
    return container.read(settingsProvider).value!;
  }

  test('build exposes the settings row the database seeds', () async {
    expect((await current()).lastOpenedTabIndex, 0);
  });

  test('updateSettings writes through to the database', () async {
    final Settings settings = await current();
    settings.counterSorting = SortingOptions.alphabeticalAsc;
    settings.folderSorting = SortingOptions.valueDesc;
    settings.keepScreenOn = true;

    await notifier.updateSettings(settings);

    final Settings stored = await repository.getSettings();
    expect(stored.counterSorting, SortingOptions.alphabeticalAsc);
    expect(stored.folderSorting, SortingOptions.valueDesc);
    expect(stored.keepScreenOn, isTrue);
  });

  test('updateSettings pushes the new value into the provider state', () async {
    final Settings settings = await current();
    settings.counterCompactView = true;

    await notifier.updateSettings(settings);

    expect((await current()).counterCompactView, isTrue);
  });

  test('updating twice never creates a second settings row', () async {
    final Settings settings = await current();
    settings.activateSounds = true;
    await notifier.updateSettings(settings);
    settings.activateSounds = false;
    await notifier.updateSettings(settings);

    expect((await repository.getSettings()).activateSounds, isFalse);
  });

  test('the synchronization credentials round-trip', () async {
    final Settings settings = await current();
    settings.synchronizationAccessToken = 'test-token';
    settings.synchronizationApiUrl = 'https://example.invalid/api';

    await notifier.updateSettings(settings);

    final Settings stored = await repository.getSettings();
    expect(stored.synchronizationAccessToken, 'test-token');
    expect(stored.synchronizationApiUrl, 'https://example.invalid/api');
  });
}
