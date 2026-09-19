import 'package:counter/models/count.dart';
import 'package:counter/models/counter.dart';
import 'package:counter/models/folder.dart';
import 'package:counter/models/reorder_item.dart';
import 'package:counter/models/settings.dart';
import 'package:counter/models/sorting_options.dart';
import 'package:counter/models/statistics.dart';
import 'package:counter/repository/counter_repository.dart';

/// An in-memory [CounterRepository] for widget tests.
///
/// Widget tests cannot go through SQLite. A `testWidgets` body runs under
/// `FakeAsync`, and a real database write started there takes the connection
/// lock and never releases it, because its continuation only runs on the real
/// event loop. The test then deadlocks the moment anything else reads.
///
/// So the widget layer talks to this instead: every method returns
/// synchronously completed futures, which resolve fine under `FakeAsync`. That
/// the SQL itself is correct is settled by the repository tests, which run
/// against a real engine.
///
/// Every mutating call is appended to [calls], so a test can assert that a
/// button actually reached the repository rather than only repainting.
class FakeCounterRepository implements CounterRepository {
  final Map<int, Counter> counters = <int, Counter>{};
  final Map<int, Folder> folders = <int, Folder>{};
  final List<Statistics> statistics = <Statistics>[];
  Settings settings = Settings(counterCompactView: false);

  /// Method names in call order, e.g. `incrementCounterById(3)`.
  final List<String> calls = <String>[];

  int _nextCounterId = 1;
  int _nextFolderId = 1;

  void _record(String call) => calls.add(call);

  /// Seeds a folder without going through [createFolder], so a test's own
  /// setup does not show up in [calls].
  Folder seedFolder(String name, {int? counterNumber}) {
    final Folder folder = Folder(
      id: _nextFolderId++,
      name: name,
      folderOrder: folders.length,
      counterNumber: counterNumber ?? 0,
      creationTimeStamp: DateTime.now().millisecondsSinceEpoch,
      lastModificationTimeStamp: DateTime.now().millisecondsSinceEpoch,
    );
    folders[folder.id!] = folder;
    return folder;
  }

  /// Seeds a counter without going through [createCounter].
  Counter seedCounter({
    required String name,
    Folder? folder,
    int count = 0,
    int? limit,
    int step = 1,
    String color = '#ff0000',
    String? note,
  }) {
    final Counter counter = Counter(
      id: _nextCounterId++,
      name: name,
      counterCount: count,
      counterLimit: limit,
      folder: folder,
      step: step,
      color: color,
      note: note,
      orderInFolder: counters.length,
      counterOrder: counters.length,
      creationTimeStamp: DateTime.now().millisecondsSinceEpoch,
    );
    counters[counter.id!] = counter;
    if (folder != null) {
      folder.counterNumber = (folder.counterNumber ?? 0) + 1;
    }
    return counter;
  }

  List<Counter> _countersIn(int folderId) {
    return counters.values
        .where((Counter counter) => counter.folder?.id == folderId)
        .toList();
  }

  // --- lifecycle ------------------------------------------------------------

  @override
  bool isInitialized() => true;

  @override
  Future<bool> initialize() async => true;

  // --- counters -------------------------------------------------------------

  @override
  Future<Counter> createCounter(Counter counter) async {
    _record('createCounter(${counter.name})');
    return seedCounter(
      name: counter.name!,
      folder: counter.folder,
      count: counter.counterCount ?? 0,
      limit: counter.counterLimit,
      step: counter.step ?? 1,
      color: counter.color ?? '#ff0000',
      note: counter.note,
    );
  }

  @override
  Future<Counter> updateCounter(Counter counter) async {
    _record('updateCounter(${counter.id})');
    counter.lastModificationTimeStamp = DateTime.now().millisecondsSinceEpoch;
    counters[counter.id!] = counter;
    return counter;
  }

  @override
  Future<bool> deleteCounterById(int counterId) async {
    _record('deleteCounterById($counterId)');
    return counters.remove(counterId) != null;
  }

  @override
  Future<Counter> getCounterById(int counterId) async {
    return counters[counterId] ?? Counter();
  }

  @override
  Future<Counter?> getLastModifiedCounter(int folderId) async {
    final List<Counter> inFolder = _countersIn(folderId)
      ..sort(
        (Counter a, Counter b) => (b.lastModificationTimeStamp ?? 0).compareTo(
          a.lastModificationTimeStamp ?? 0,
        ),
      );
    return inFolder.isEmpty ? null : inFolder.first;
  }

  @override
  Future<List<Counter>> getCountersByFolderId(int folderId) async {
    return _countersIn(folderId);
  }

  @override
  Future<List<Counter>> getCountersByFolderIdSorted(
    int folderId,
    SortingOptions? counterSorting,
  ) async {
    final List<Counter> inFolder = _countersIn(folderId);
    switch (counterSorting) {
      case null:
      case SortingOptions.custom:
        inFolder.sort(
          (Counter a, Counter b) =>
              (a.orderInFolder ?? 0) - (b.orderInFolder ?? 0),
        );
      case SortingOptions.alphabeticalAsc:
        inFolder.sort((Counter a, Counter b) => a.name!.compareTo(b.name!));
      case SortingOptions.alphabeticalDesc:
        inFolder.sort((Counter a, Counter b) => b.name!.compareTo(a.name!));
      case SortingOptions.valueAsc:
        inFolder.sort(
          (Counter a, Counter b) =>
              (a.counterCount ?? 0) - (b.counterCount ?? 0),
        );
      case SortingOptions.valueDesc:
        inFolder.sort(
          (Counter a, Counter b) =>
              (b.counterCount ?? 0) - (a.counterCount ?? 0),
        );
      case SortingOptions.creationDateAsc:
        inFolder.sort(
          (Counter a, Counter b) =>
              (a.creationTimeStamp ?? 0) - (b.creationTimeStamp ?? 0),
        );
      case SortingOptions.creationDateDesc:
        inFolder.sort(
          (Counter a, Counter b) =>
              (b.creationTimeStamp ?? 0) - (a.creationTimeStamp ?? 0),
        );
    }
    return inFolder;
  }

  @override
  Future<List<Counter>> getAllCounters() async => counters.values.toList();

  @override
  Future<bool> incrementCounterById(int counterId, {dynamic value = 1}) async {
    _record('incrementCounterById($counterId)');
    final Counter? counter = counters[counterId];
    if (counter == null) {
      return false;
    }
    counter.counterCount = (counter.counterCount ?? 0) + (value as int);
    counter.lastModificationTimeStamp = DateTime.now().millisecondsSinceEpoch;
    return true;
  }

  @override
  Future<bool> decrementCounterById(int counterId, {dynamic value = 1}) async {
    _record('decrementCounterById($counterId)');
    final Counter? counter = counters[counterId];
    if (counter == null) {
      return false;
    }
    counter.counterCount = (counter.counterCount ?? 0) - (value as int);
    counter.lastModificationTimeStamp = DateTime.now().millisecondsSinceEpoch;
    return true;
  }

  @override
  Future<bool> resetCounterById(int counterId) async {
    _record('resetCounterById($counterId)');
    final Counter? counter = counters[counterId];
    if (counter == null) {
      return false;
    }
    counter.counterCount = 0;
    return true;
  }

  @override
  Future<bool> reorderCounters(List<ReorderItem> reorderItems) async {
    _record('reorderCounters(${reorderItems.length})');
    for (final ReorderItem item in reorderItems) {
      counters[item.id]?.orderInFolder = item.order;
    }
    return true;
  }

  @override
  Future<bool> resetAllCountersForFolderId(int folderId) async {
    _record('resetAllCountersForFolderId($folderId)');
    for (final Counter counter in _countersIn(folderId)) {
      counter.counterCount = 0;
    }
    return true;
  }

  @override
  Future<bool> deleteAllCountersForFolderId(int folderId) async {
    _record('deleteAllCountersForFolderId($folderId)');
    for (final Counter counter in _countersIn(folderId)) {
      counters.remove(counter.id);
    }
    folders[folderId]?.counterNumber = 0;
    return true;
  }

  @override
  Future<bool> deleteAllCounters() async {
    _record('deleteAllCounters()');
    counters.clear();
    return true;
  }

  // --- folders --------------------------------------------------------------

  @override
  Future<Folder> createFolder(String folderName) async {
    _record('createFolder($folderName)');
    return seedFolder(folderName);
  }

  @override
  Future<Folder> renameFolder(int folderId, String folderName) async {
    _record('renameFolder($folderId, $folderName)');
    final Folder folder = folders[folderId]!;
    folder.name = folderName;
    folder.lastModificationTimeStamp = DateTime.now().millisecondsSinceEpoch;
    return folder;
  }

  @override
  Future<Folder> getFolderById(int folderId) async {
    return folders[folderId] ?? Folder();
  }

  @override
  Future<bool> deleteFolderById(int folderId) async {
    _record('deleteFolderById($folderId)');
    for (final Counter counter in _countersIn(folderId)) {
      counters.remove(counter.id);
    }
    return folders.remove(folderId) != null;
  }

  @override
  Future<List<Folder>> getAllFolders() async => folders.values.toList();

  @override
  Future<List<Folder>> getAllFoldersSorted(
    SortingOptions? sortingOptions,
  ) async {
    final List<Folder> all = folders.values.toList();
    switch (sortingOptions) {
      case null:
      case SortingOptions.custom:
        all.sort(
          (Folder a, Folder b) => (a.folderOrder ?? 0) - (b.folderOrder ?? 0),
        );
      case SortingOptions.alphabeticalAsc:
        all.sort((Folder a, Folder b) => a.name!.compareTo(b.name!));
      case SortingOptions.alphabeticalDesc:
        all.sort((Folder a, Folder b) => b.name!.compareTo(a.name!));
      case SortingOptions.valueAsc:
        all.sort(
          (Folder a, Folder b) =>
              (a.counterNumber ?? 0) - (b.counterNumber ?? 0),
        );
      case SortingOptions.valueDesc:
        all.sort(
          (Folder a, Folder b) =>
              (b.counterNumber ?? 0) - (a.counterNumber ?? 0),
        );
      case SortingOptions.creationDateAsc:
        all.sort(
          (Folder a, Folder b) =>
              (a.creationTimeStamp ?? 0) - (b.creationTimeStamp ?? 0),
        );
      case SortingOptions.creationDateDesc:
        all.sort(
          (Folder a, Folder b) =>
              (b.creationTimeStamp ?? 0) - (a.creationTimeStamp ?? 0),
        );
    }
    return all;
  }

  @override
  Future<bool> reorderFolders(List<ReorderItem> reorderItems) async {
    _record('reorderFolders(${reorderItems.length})');
    for (final ReorderItem item in reorderItems) {
      folders[item.id]?.folderOrder = item.order;
    }
    return true;
  }

  @override
  Future<bool> deleteAllFolders() async {
    _record('deleteAllFolders()');
    folders.clear();
    return true;
  }

  // --- settings -------------------------------------------------------------

  @override
  Future<Settings> getSettings() async => settings;

  @override
  Future<Settings> updateSettings(Settings newSettings) async {
    _record('updateSettings()');
    settings = newSettings;
    return settings;
  }

  @override
  Future<bool> updateLastOpenedTabIndex(int tabIndex) async {
    _record('updateLastOpenedTabIndex($tabIndex)');
    settings.lastOpenedTabIndex = tabIndex;
    return true;
  }

  // --- statistics -----------------------------------------------------------

  @override
  Future<Statistics> addStatistics(Statistics newStatistics) async {
    _record('addStatistics()');
    statistics.add(newStatistics);
    return newStatistics;
  }

  @override
  Future<void> addStatisticsForFolder(
    int folderId,
    StatisticsType statisticsType,
  ) async {
    _record('addStatisticsForFolder($folderId, ${statisticsType.name})');
  }

  @override
  Future<List<Statistics>> getCounterStatistics(
    int counterId,
    DateTime start,
    DateTime end,
  ) async {
    return statistics
        .where((Statistics item) => item.counterId == counterId)
        .toList();
  }

  @override
  Future<List<Statistics>> getAllStatistics() async => statistics;

  @override
  Future<bool> deleteAllStatistics() async {
    _record('deleteAllStatistics()');
    statistics.clear();
    return true;
  }

  @override
  Future<List<Count>> getCountsByFolderId(int folderId) async {
    return _countersIn(folderId)
        .map(
          (Counter counter) =>
              Count(counterId: counter.id!, count: counter.counterCount ?? 0),
        )
        .toList();
  }

  // --- synchronization ------------------------------------------------------
  //
  // No widget drives synchronization directly; the sync screen goes through
  // SynchronizationService, which has its own tests. These exist so the class
  // satisfies the interface.

  @override
  Future<List<Counter>> getAllCountersToSynchronize() async => <Counter>[];

  @override
  Future<List<int>> getAllDeletedCounterIdsToSynchronize() async => <int>[];

  @override
  Future<List<Folder>> getAllFoldersToSynchronize() async => <Folder>[];

  @override
  Future<List<int>> getAllDeletedFolderIdsToSynchronize() async => <int>[];

  @override
  Future<bool> updateCountersSynchronizationTimestamp(
    List<int> counterIds,
  ) async => true;

  @override
  Future<bool> updateCountersSynchronizationTimestampByFolderId(
    int folderId,
  ) async => true;

  @override
  Future<bool> updateDeletedCountersSynchronizationTimestamp(
    List<int> counterIds,
  ) async => true;

  @override
  Future<bool> updateFoldersSynchronizationTimestamp(
    List<int> folderIds,
  ) async => true;

  @override
  Future<bool> updateDeletedFoldersSynchronizationTimestamp(
    List<int> folderIds,
  ) async => true;

  @override
  Future<bool> synchronizeCountersCount(int folderId) async => true;

  @override
  Future<bool> resetCountersSynchronizationTimeStamp() async => true;

  @override
  Future<bool> resetFoldersSynchronizationTimeStamp() async => true;

  @override
  Future<bool> deleteAllCountersHistory() async => true;

  @override
  Future<bool> deleteAllFoldersHistory() async => true;

  @override
  Future<int> batchInsertCounters(List<Map<String, Object?>> jsonList) async {
    return jsonList.length;
  }

  @override
  Future<int> batchInsertFolders(List<Map<String, Object?>> jsonList) async {
    return jsonList.length;
  }

  @override
  Future<int> batchInsertStatistics(List<Map<String, Object?>> jsonList) async {
    return jsonList.length;
  }
}
