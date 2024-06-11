import 'dart:async';

import 'package:counterpp/models/counter.dart';
import 'package:counterpp/models/folder.dart';
import 'package:counterpp/models/reorder_item.dart';
import 'package:counterpp/models/settings.dart';
import 'package:counterpp/models/sorting_options.dart';
import 'package:counterpp/models/statistics.dart';

abstract interface class CounterRepository {
  bool isInitialized();
  Future<bool> initialize();
  Future<bool> resetCounterById(int counterId);
  Future<bool> incrementCounterById(int counterId, {value = 1});
  Future<bool> decrementCounterById(int counterId, {value = 1});
  Future<Counter> createCounter(Counter counter);
  Future<Counter> updateCounter(Counter counter);
  Future<bool> deleteCounterById(int counterId);
  Future<Counter> getCounterById(int counterId);
  Future<Counter?> getLastModifiedCounter(int folderId);
  Future<List<Counter>> getCountersByFolderId(int folderId);
  Future<List<Counter>> getCountersByFolderIdSorted(int folderId, SortingOptions? counterSorting);
  Future<List<Counter>> getAllCounters();
  Future<List<Folder>> getAllFolders();
  Future<List<Folder>> getAllFoldersSorted(SortingOptions? sortingOptions);
  Future<Folder> createFolder(String folderName);
  Future<Folder> insertFolder(Folder folder); // full insert of all column including id
  Future<Folder> renameFolder(int folderId, String folderName);
  Future<Folder> getFolderById(int folderId);
  Future<bool> deleteFolderById(int folderId);
  Future<bool> deleteAllFolders();
  Future<bool> resetAllCountersForFolderId(int folderId);
  Future<bool> deleteAllCountersForFolderId(int folderId);
  Future<bool> deleteAllCounters();
  Future<Settings> getSettings();
  Future<Settings> updateSettings(Settings settings);
  Future<bool> reorderFolders(List<ReorderItem> reorderItems);
  Future<bool> reorderCounters(List<ReorderItem> reorderItems);
  Future<Statistics> addStatistics(Statistics statistics);
  Future<void> addStatisticsForFolder(int folderId, StatisticsType statisticsType);
  Future<List<Statistics>> getCounterStatistics(int counterId, DateTime start, DateTime end);
  Future<List<Statistics>> getAllStatistics();
  Future<bool> deleteAllStatistics();
  Future<int> batchInsertFolders(List<Map<String, Object?>> jsonList);
  Future<int> batchInsertCounters(List<Map<String, Object?>> jsonList);
  Future<int> batchInsertStatistics(List<Map<String, Object?>> jsonList);
}
