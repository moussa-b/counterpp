import 'package:counter/models/count.dart';
import 'package:counter/models/counter.dart';
import 'package:counter/models/folder.dart';
import 'package:counter/models/reorder_item.dart';
import 'package:counter/models/settings.dart';
import 'package:counter/models/sorting_options.dart';
import 'package:counter/models/statistics.dart';
import 'package:counter/utils/synchronization_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart' as sql;

import 'counter_repository.dart';

class DatabaseCounterRepository implements CounterRepository {
  sql.Database? _db;
  static const _selectCounterSql = """
      SELECT c.*,
      f.id as 'folder.id',
      f.name as 'folder.name',
      f.creationTimeStamp as 'folder.creationTimeStamp',
      f.lastModificationTimeStamp as 'folder.lastModificationTimeStamp',
      f.folderOrder as 'folder.folderOrder',
      (SELECT COUNT(*) FROM counters WHERE folderId = f.id) as 'folder.counterNumber'
      FROM counters c
      LEFT JOIN folders f
      ON c.folderId = f.id
      """;
  static const _selectFolderSql = """
          SELECT f.*, COUNT(*) AS counterNumber
          FROM folders f 
          INNER JOIN counters c ON f.id = c.folderId 
          WHERE f.id > 1
          GROUP BY f.id
          UNION ALL
          SELECT f.*, 0 AS counterNumber
          FROM folders f 
          LEFT JOIN counters c ON f.id = c.folderId 
          WHERE f.id > 1 AND c.id IS NULL
      """;

  get lastModificationTimeStamp {
    return DateTime.now().millisecondsSinceEpoch;
  }

  get lastSynchronizationTimeStamp {
    return DateTime.now().millisecondsSinceEpoch;
  }

  @override
  bool isInitialized() {
    return _db != null;
  }

  @override
  Future<bool> initialize() async {
    if (isInitialized()) {
      return true;
    } else {
      final String dbPath = await sql.getDatabasesPath();
      _db = await sql.openDatabase(
        path.join(dbPath, 'counter.db'),
        version: 2,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (db, version) async {
          await db.transaction((txn) async {
            await _executeSqlScript(txn, 'assets/sql_scripts/folder_table_create.sql');
            await _executeSqlScript(txn, 'assets/sql_scripts/folder_table_create_history.sql');
            await _executeSqlScript(txn, 'assets/sql_scripts/folder_table_create_trigger_delete.sql');
            await _executeSqlScript(txn, 'assets/sql_scripts/folder_table_create_trigger_insert.sql');
            await _executeSqlScript(txn, 'assets/sql_scripts/folder_table_create_trigger_update.sql');
            await _executeSqlScript(txn, 'assets/sql_scripts/counter_table_create.sql');
            await _executeSqlScript(txn, 'assets/sql_scripts/counter_table_create_history.sql');
            await _executeSqlScript(txn, 'assets/sql_scripts/counter_table_create_trigger_delete.sql');
            await _executeSqlScript(txn, 'assets/sql_scripts/counter_table_create_trigger_insert.sql');
            await _executeSqlScript(txn, 'assets/sql_scripts/counter_table_create_trigger_update.sql');
            await _executeSqlScript(txn, 'assets/sql_scripts/statistics_table_create.sql');
            await _executeSqlScript(txn, 'assets/sql_scripts/settings_table_create.sql');
            await _executeSqlScript(txn, 'assets/sql_scripts/folder_table_populate.sql');
            await _executeSqlScript(txn, 'assets/sql_scripts/counter_table_populate.sql');
            // await _executeSqlScript(txn, 'assets/sql_scripts/folder_table_sample.sql'); // TODO replace by folder_table_populate.sql
            // await _executeSqlScript(txn, 'assets/sql_scripts/counter_table_sample.sql'); // TODO replace by counter_table_populate.sql
            // await _executeSqlScript(txn, 'assets/sql_scripts/statistics_table_sample.sql'); // TODO remove
          });
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            // Migration from version 1 to 2: Add mailApiKey, mailApiDomain and mailSupport columns to settings table
            await db.execute('ALTER TABLE settings ADD COLUMN mailApiKey TEXT');
            await db.execute('ALTER TABLE settings ADD COLUMN mailApiDomain TEXT');
            await db.execute('ALTER TABLE settings ADD COLUMN mailSupport TEXT');
            if (kDebugMode) {
              debugPrint('Database upgraded from version $oldVersion to $newVersion');
            }
          }
        },
        onOpen: (db) async {
          if (kDebugMode) {
            debugPrint('Database path : ${path.join(dbPath, 'counter.db')}');
          }
          const sql = 'SELECT * FROM settings';
          final List<Map<String, Object?>> settingsMap = await db.rawQuery(sql);
          if (settingsMap.length == 1) {
            final Settings settings = Settings.fromJson(settingsMap[0]);
            if (settings.synchronizationApiUrl != null && settings.synchronizationAccessToken != null) {
              SynchronizationService().setApiUrl(apiUrl: settings.synchronizationApiUrl!, apiAccessToken: settings.synchronizationAccessToken!);
            }
          }
        },
      );
      return _db != null;
    }
  }

  Future<void> _executeSqlScript(sql.Transaction txn, String assetPath) async {
    final String sql = await rootBundle.loadString(assetPath);
    await txn.execute(sql);
  }

  @override
  Future<bool> resetCounterById(int counterId) async {
    if (_db != null) {
      final bool updated = await _db!.transaction((txn) async {
        final int count = await txn.rawUpdate(
            'UPDATE counters SET counterCount = 0, lastModificationTimeStamp = ? WHERE id = ?', [lastModificationTimeStamp, counterId]);
        addStatistics(Statistics.fromJson({'counterId': counterId, 'type': StatisticsType.RESET.name}));
        return count > 0;
      });
      if (updated) {
        Response? response = await SynchronizationService().synchronizeCountersCount([Count(counterId: counterId, count: 0)]);
        if (response != null && response.statusCode >= 200 && response.statusCode < 300) {
          return updateCountersSynchronizationTimestamp([counterId]);
        }
      }
      return updated;
    } else {
      return false;
    }
  }

  @override
  Future<bool> decrementCounterById(int counterId, {value = 1}) async {
    if (_db != null) {
      final bool updated = await _db!.transaction((txn) async {
        final int count = await txn.rawUpdate(
            'UPDATE counters SET counterCount = (IFNULL(counterCount, 0) - ?), lastModificationTimeStamp = ? WHERE id = ?',
            [value, lastModificationTimeStamp, counterId]);
        if (count > 0) {
          addStatistics(Statistics.fromJson({'counterId': counterId, 'type': StatisticsType.DECREMENT.name, 'value': value}));
        }
        return count > 0;
      });
      return updated;
    } else {
      return false;
    }
  }

  @override
  Future<bool> incrementCounterById(int counterId, {value = 1}) async {
    if (_db != null) {
      final bool updated = await _db!.transaction((txn) async {
        final int count = await txn.rawUpdate(
            'UPDATE counters SET counterCount = (IFNULL(counterCount, 0) + ?), lastModificationTimeStamp = ? WHERE id = ?',
            [value, lastModificationTimeStamp, counterId]);
        if (count > 0) {
          addStatistics(Statistics.fromJson({'counterId': counterId, 'type': StatisticsType.INCREMENT.name, 'value': value}));
        }
        return count > 0;
      });
      return updated;
    } else {
      return false;
    }
  }

  @override
  Future<Counter> createCounter(Counter counter) async {
    if (_db != null) {
      final int now = lastModificationTimeStamp;
      final id = await _db!.transaction((txn) async {
        final String query = """
        INSERT INTO counters (
        name,
        counterCount,
        creationTimeStamp,
        counterLimit,
        folderId,
        color,
        counterOrder,
        orderInFolder,
        step,
        note
        )
        VALUES (?, ?, ?, ?, ?, ?, 1 + (SELECT COUNT(*) FROM counters),
        ${counter.folder?.id != null && counter.folder!.id! > 0 ? ('1 + (SELECT COUNT(*) FROM counters WHERE folderId = ${counter.folder!.id!})') : null}, 
        ?, ?)
        """;
        int insertedId = await txn.rawInsert(query, [counter.name, counter.counterCount, now, counter.counterLimit, counter.folder?.id, counter.color, counter.step ?? 1, counter.note]);
        return insertedId;
      });
      if (id > 0) {
        final Counter createdCounter = await getCounterById(id);
        SynchronizationService().synchronizeCounters([createdCounter]).then((Response? response) {
          if (response != null && response.statusCode >= 200 && response.statusCode < 300) {
            updateCountersSynchronizationTimestamp([id]);
          }
        });
        return createdCounter;
      }
    }
    return Counter();
  }

  @override
  Future<bool> deleteCounterById(int counterId) async {
    int deleted = 0;
    if (_db != null) {
      deleted = await _db!.delete(
        'counters',
        where: 'id = ?',
        whereArgs: [counterId],
      );
      if (deleted == 1) {
        SynchronizationService().synchronizeDeletedCounters([counterId]).then((Response? response) {
          if (response != null && response.statusCode >= 200 && response.statusCode < 300) {
            updateDeletedCountersSynchronizationTimestamp([counterId]);
          }
        });
      }
    }
    return deleted == 1;
  }

  @override
  Future<List<Counter>> getAllCounters() async {
    if (_db != null) {
      final List<Map<String, Object?>> countersMap = await _db!.rawQuery('$_selectCounterSql WHERE c.id > 1');
      return countersMap
          .map((Map<String, Object?> folderMap) => Counter.fromJson(folderMap))
          .toList();
    } else {
      return [];
    }
  }

  @override
  Future<List<Folder>> getAllFoldersSorted(SortingOptions? sortingOptions) async {
    List<Folder> folders = await getAllFolders();
    if (sortingOptions != null) {
      folders.sort((Folder folder1, Folder folder2) {
        switch (sortingOptions) {
          case SortingOptions.custom:
            return (folder1.folderOrder ?? 0) - (folder2.folderOrder ?? 0);
          case SortingOptions.alphabeticalAsc:
            return folder1.name!.compareTo(folder2.name!);
          case SortingOptions.alphabeticalDesc:
            return folder2.name!.compareTo(folder1.name!);
          case SortingOptions.valueAsc:
            return (folder1.counterNumber ?? 0) - (folder2.counterNumber ??  0);
          case SortingOptions.valueDesc:
            return (folder2.counterNumber ?? 0) - (folder1.counterNumber ??  0);
          case SortingOptions.creationDateAsc:
            return (folder1.creationTimeStamp ?? 0) - (folder2.creationTimeStamp ??  0);
          case SortingOptions.creationDateDesc:
            return (folder2.creationTimeStamp ?? 0) - (folder1.creationTimeStamp ??  0);
        }
      });
    }
    return folders;
  }

  @override
  Future<bool> reorderFolders(List<ReorderItem> reorderItems) async {
    if (_db != null && reorderItems.isNotEmpty) {
      bool updated = await _db!.transaction((txn) async {
        final String whenClause = reorderItems.map((ReorderItem reorderItem) => 'WHEN id=${reorderItem.id} THEN ${reorderItem.order}').join(' ');
        final String whereClause = reorderItems.map((ReorderItem reorderItem) => '${reorderItem.id}').join(', ');
        final String sql = """
            UPDATE folders SET folderOrder=CASE
            $whenClause
            ELSE folderOrder END
            WHERE id IN ($whereClause)
            """;
        final int count = await txn.rawUpdate(sql);
        return count > 0;
      });
      return updated;
    }
    return false;
  }

  @override
  Future<bool> reorderCounters(List<ReorderItem> reorderItems) async {
    if (_db != null && reorderItems.isNotEmpty) {
      bool updated = await _db!.transaction((txn) async {
        final String whenClause = reorderItems.map((ReorderItem reorderItem) => 'WHEN id=${reorderItem.id} THEN ${reorderItem.order}').join(' ');
        final String whereClause = reorderItems.map((ReorderItem reorderItem) => '${reorderItem.id}').join(', ');
        final String sql = """
            UPDATE counters SET orderInFolder=CASE
            $whenClause
            ELSE orderInFolder END
            WHERE id IN ($whereClause)
            """;
        final int count = await txn.rawUpdate(sql);
        return count > 0;
      });
      return updated;
    }
    return false;
  }

  @override
  Future<List<Folder>> getAllFolders() async {
    if (_db != null) {
      final List<Map<String, Object?>> foldersMap = await _db!.rawQuery(_selectFolderSql);
      return foldersMap
          .map((Map<String, Object?> folderMap) => Folder.fromJson(folderMap))
          .toList();
    } else {
      return [];
    }
  }

  @override
  Future<Counter> getCounterById(int counterId) async {
    if (_db != null) {
      final sql = """
      SELECT c.*,
      f.id as 'folder.id',
      f.name as 'folder.name',
      f.creationTimeStamp as 'folder.creationTimeStamp',
      f.lastModificationTimeStamp as 'folder.lastModificationTimeStamp',
      f.folderOrder as 'folder.folderOrder'
      FROM counters c
      LEFT JOIN folders f
      ON c.folderId = f.id
      WHERE c.id = $counterId
      """;
      final List<Map<String, Object?>> countersMap = await _db!.rawQuery(sql);
      if (countersMap.length == 1) {
        return Counter.fromJson(countersMap[0]);
      }
    }
    return Counter();
  }

  @override
  Future<List<Counter>> getCountersByFolderId(int folderId) async {
    if (_db != null) {
      final sql = '$_selectCounterSql WHERE f.id = $folderId';
      final List<Map<String, Object?>> countersMap = await _db!.rawQuery(sql);
      return countersMap
          .map((Map<String, Object?> counterMap) => Counter.fromJson(counterMap))
          .toList();
    } else {
      return [];
    }
  }

  @override
  Future<Counter?> getLastModifiedCounter(int folderId) async {
    if (_db != null) {
      final sql = '$_selectCounterSql WHERE f.id = $folderId ORDER BY c.lastModificationTimeStamp DESC LIMIT 1';
      final List<Map<String, Object?>> countersMap = await _db!.rawQuery(sql);
      if (countersMap.length == 1) {
        return Counter.fromJson(countersMap[0]);
      }
    }
    return null;
  }

  @override
  Future<List<Counter>> getCountersByFolderIdSorted(int folderId, SortingOptions? sortingOptions) async {
    final List<Counter> counters = await getCountersByFolderId(folderId);
    if (sortingOptions != null) {
      counters.sort((Counter counter1, Counter counter2) {
        switch (sortingOptions) {
          case SortingOptions.custom:
            return (counter1.orderInFolder ?? 0) - (counter2.orderInFolder ?? 0);
          case SortingOptions.alphabeticalAsc:
            return counter1.name!.compareTo(counter2.name!);
          case SortingOptions.alphabeticalDesc:
            return counter2.name!.compareTo(counter1.name!);
          case SortingOptions.valueAsc:
            return (counter1.counterCount ?? 0) - (counter2.counterCount ??  0);
          case SortingOptions.valueDesc:
            return (counter2.counterCount ?? 0) - (counter1.counterCount ??  0);
          case SortingOptions.creationDateAsc:
            return (counter1.creationTimeStamp ?? 0) - (counter2.creationTimeStamp ??  0);
          case SortingOptions.creationDateDesc:
            return (counter2.creationTimeStamp ?? 0) - (counter1.creationTimeStamp ??  0);
        }
      });
    }
    return counters;
  }

  @override
  Future<Counter> updateCounter(Counter counter) async {
    if (_db != null) {
      bool updated = await _db!.transaction((txn) async {
        final int count = await txn.rawUpdate(
            """
            UPDATE counters SET 
            name = ?,
            counterCount = ?,
            lastModificationTimeStamp = ?,
            counterLimit = ?,
            folderId = ?,
            color = ?,
            counterOrder = ?,
            orderInFolder = ?,
            step = ?,
            note = ?
            WHERE id = ?
            """,
            [
              counter.name,
              counter.counterCount,
              lastModificationTimeStamp,
              counter.counterLimit,
              counter.folder!.id,
              counter.color,
              counter.counterOrder,
              counter.orderInFolder,
              counter.step,
              counter.note,
              counter.id
            ]);
        return count > 0;
      });
      if (updated) {
        final Counter updatedCounter = await getCounterById(counter.id!);
        SynchronizationService().synchronizeCounters([updatedCounter]).then((Response? response) {
          if (response != null && response.statusCode >= 200 && response.statusCode < 300) {
            updateCountersSynchronizationTimestamp([counter.id!]);
          }
        });
        return updatedCounter;
      }
    }
    return Counter();
  }

  @override
  Future<Folder> createFolder(String folderName) async {
    if (_db != null) {
      final id = await _db!.transaction((txn) async {
        final now = lastModificationTimeStamp;
        const String query = """
        INSERT INTO folders(name, creationTimeStamp, lastModificationTimeStamp, folderOrder)
        VALUES(?, ?, 0, (SELECT COUNT(*) FROM folders))
        """;
        int insertedId = await txn.rawInsert(query, [folderName, now]);
        return insertedId;
      });
      if (id > 0) {
        final Folder createdFolder = await getFolderById(id);
        SynchronizationService().synchronizeFolders([createdFolder]).then((Response? response) {
          if (response != null && response.statusCode >= 200 && response.statusCode < 300) {
            updateFoldersSynchronizationTimestamp([id]);
          }
        });
        return createdFolder;
      }
    }
    return Folder();
  }

  @override
  Future<Folder> renameFolder(int folderId, String folderName) async {
    if (_db != null) {
      bool updated = await _db!.transaction((txn) async {
        final int count = await txn.rawUpdate(
            'UPDATE folders SET name = ?, lastModificationTimeStamp = ? WHERE id = ?', [folderName, lastModificationTimeStamp, folderId]);
        return count > 0;
      });
      if (updated) {
        final Folder updatedFolder = await getFolderById(folderId);
        SynchronizationService().synchronizeFolders([updatedFolder]).then((Response? response) {
          if (response != null && response.statusCode >= 200 && response.statusCode < 300) {
            updateFoldersSynchronizationTimestamp([folderId]);
          }
        });
        return updatedFolder;
      }
    }
    return Folder();
  }

  @override
  Future<Folder> getFolderById(int folderId) async {
    if (_db != null) {
      final List<Map<String, Object?>> countersMap = await _db!.query(
        'folders',
        where: 'id = ?',
        whereArgs: [folderId],
      );
      if (countersMap.length == 1) {
        return Folder.fromJson(countersMap[0]);
      }
    }

    return Folder();
  }

  @override
  Future<bool> deleteFolderById(int folderId) async {
    int deleted = 0;
    if (_db != null) {
      deleted = await _db!.delete(
        'folders',
        where: 'id = ?',
        whereArgs: [folderId],
      );
      if (deleted == 1) {
        SynchronizationService().synchronizeDeletedFolders([folderId]).then((Response? response) {
          if (response != null && response.statusCode >= 200 && response.statusCode < 300) {
            updateDeletedFoldersSynchronizationTimestamp([folderId]);
          }
        });
      }
    }
    return deleted == 1;
  }

  @override
  Future<bool> deleteAllFolders() async {
    if (_db != null) {
      final List<int> ids = await _db!.transaction((txn) async {
        final List<Map<String, dynamic>> result = await txn.query(
          'folders',
          columns: ['id'],
          where: 'id > ?',
          whereArgs: [1],
        );
        final List<int> ids = result.map((row) => row['id'] as int).toList();
        if (ids.isEmpty) {
          return [];
        }
        final int count = await txn.rawDelete(
          'DELETE FROM folders WHERE id IN (${List.filled(ids.length, '?').join(',')})',
          ids,
        );
        return count > 0 ? ids : [];
      });
      // if (ids.isNotEmpty) {
      //   SynchronizationService().synchronizeDeletedFolders(ids).then((Response? response) {
      //     if (response != null && response.statusCode >= 200 && response.statusCode < 300) {
      //       updateDeletedFoldersSynchronizationTimestamp(ids);
      //     }
      //   });
      // }
      return ids.isNotEmpty;
    } else {
      return false;
    }
  }

  @override
  Future<bool> deleteAllFoldersHistory() async {
    if (_db != null) {
      await _db!.transaction((txn) async {
        await txn.delete('folders_history');
        await txn.delete('sqlite_sequence',
            where: 'name = ?', whereArgs: ['folders_history']);
      });
      return true;
    } else {
      return false;
    }
  }

  @override
  Future<bool> resetAllCountersForFolderId(int folderId) async {
    if (_db != null) {
      final bool updated = await _db!.transaction((txn) async {
        final int count = await txn.rawUpdate(
            'UPDATE counters SET counterCount = 0, lastModificationTimeStamp = ? WHERE folderId = ?', [lastModificationTimeStamp, folderId]);
        addStatisticsForFolder(folderId, StatisticsType.RESET);
        return count > 0;
      });
      if (updated) {
        synchronizeCountersCount(folderId);
      }
      return updated;
    } else {
      return false;
    }
  }

  @override
  Future<bool> deleteAllCountersForFolderId(int folderId) async {
    if (_db != null) {
      final List<int> ids = await _db!.transaction((txn) async {
        final List<Map<String, dynamic>> result = await txn.query(
          'counters',
          columns: ['id'],
          where: 'folderId = ?',
          whereArgs: [folderId],
        );
        final List<int> ids = result.map((row) => row['id'] as int).toList();
        if (ids.isEmpty) {
          return [];
        }
        final int count = await txn.rawDelete(
          'DELETE FROM counters WHERE id IN (${List.filled(ids.length, '?').join(',')})',
          ids,
        );
        return count > 0 ? ids : [];
      });
      if (ids.isNotEmpty) {
        SynchronizationService().synchronizeDeletedCounters(ids).then((Response? response) {
          if (response != null && response.statusCode >= 200 && response.statusCode < 300) {
            updateDeletedCountersSynchronizationTimestamp(ids);
          }
        });
      }
      return ids.isNotEmpty;
    } else {
      return false;
    }
  }

  @override
  Future<bool> deleteAllCounters() async {
    if (_db != null) {
      final List<int> ids = await _db!.transaction((txn) async {
        final List<Map<String, dynamic>> result = await txn.query(
          'counters',
          columns: ['id'],
          where: 'folderId IS NULL OR folderId <> ?',
          whereArgs: [1],
        );
        final List<int> ids = result.map((row) => row['id'] as int).toList();
        if (ids.isEmpty) {
          return [];
        }
        final int count = await txn.rawDelete(
          'DELETE FROM counters WHERE id IN (${List.filled(ids.length, '?').join(',')})',
          ids,
        );
        return count > 0 ? ids : [];
      });
      // if (ids.isNotEmpty) {
      //   SynchronizationService().synchronizeDeletedCounters(ids).then((Response? response) {
      //     if (response != null && response.statusCode >= 200 && response.statusCode < 300) {
      //       updateDeletedCountersSynchronizationTimestamp(ids);
      //     }
      //   });
      // }
      return ids.isNotEmpty;
    } else {
      return false;
    }
  }

  @override
  Future<bool> deleteAllCountersHistory() async {
    if (_db != null) {
      await _db!.transaction((txn) async {
        await txn.delete('counters_history');
        await txn.delete('sqlite_sequence', where: 'name = ?', whereArgs: ['counters_history']);
      });
      return true;
    } else {
      return false;
    }
  }

  @override
  Future<Settings> getSettings() async {
    if (_db != null) {
      const sql = 'SELECT * FROM settings';
      final List<Map<String, Object?>> settingsMap = await _db!.rawQuery(sql);
      if (settingsMap.length == 1) {
        return Settings.fromJson(settingsMap[0]);
      }
    }
    return Settings();
  }

  @override
  Future<Settings> updateSettings(Settings settings) async {
    if (_db != null) {
      bool updated = await _db!.transaction((txn) async {
        final int count = await txn.rawUpdate(
          """REPLACE INTO settings (
             id,
             counterCompactView,
             counterSorting,
             folderSorting,
             activateSounds,
             activateVibrator,
             keepScreenOn,
             showTutorial,
             synchronizationAccessToken,
             synchronizationApiUrl,
             mailApiKey,
             mailApiDomain,
             mailSupport,
             lastModificationTimeStamp,
             lastOpenedTabIndex
           )
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
          [
            1,
            settings.counterCompactView == true ? 1 : 0,
            settings.counterSorting?.index,
            settings.folderSorting?.index,
            settings.activateSounds == true ? 1 : 0,
            settings.activateVibrator == true ? 1 : 0,
            settings.keepScreenOn == true ? 1 : 0,
            settings.showTutorial == true ? 1 : 0,
            settings.synchronizationAccessToken,
            settings.synchronizationApiUrl,
            settings.mailApiKey,
            settings.mailApiDomain,
            settings.mailSupport,
            lastModificationTimeStamp,
            settings.lastOpenedTabIndex,
          ],
        );
        return count > 0;
      });
      if (updated) {
        return getSettings();
      }
    }
    return Settings.copy(settings);
  }

  @override
  Future<bool> updateLastOpenedTabIndex(int tabIndex) async {
    if (_db != null) {
      bool updated = await _db!.transaction((txn) async {
        final int count = await txn.rawUpdate(
          'UPDATE settings SET lastOpenedTabIndex = ?',
          [tabIndex],
        );
        return count > 0;
      });
      return updated;
    }
    return false;
  }

  @override
  Future<Statistics> addStatistics(Statistics statistics) async {
    if (_db != null && statistics.counterId! > 1) {
      statistics.id = await _db!.transaction((txn) async {
        const String sql = 'INSERT INTO statistics (counterId, folderId, type, value, dateTimeStamp) VALUES (?, (SELECT folderId FROM counters WHERE id = ? LIMIT 1), ?, ?, ?)';
        final int statisticsId = await txn.rawInsert(sql, [statistics.counterId, statistics.counterId, statistics.type.toString().split('.').last, statistics.value, statistics.dateTimeStamp ?? lastModificationTimeStamp]);
        return statisticsId;
      });
    }
    return statistics;
  }

  @override
  Future<void> addStatisticsForFolder(int folderId, StatisticsType statisticsType) async {
    if (_db != null) {
      final List<Map<String, dynamic>> maps = await _db!.query(
        'counters',
        columns: ['id'],
        where: 'folderId = ?',
        whereArgs: [folderId],
      );
      final List<int> ids = List<int>.from(maps.map((map) => map['id']));
      if (ids.isNotEmpty) {
        for (var counterId in ids) {
          addStatistics(Statistics.fromJson({'counterId': counterId, 'type': StatisticsType.RESET.name}));
        }
      }
    }
  }

  @override
  Future<List<Statistics>> getCounterStatistics(int counterId, DateTime start, DateTime end) async {
    if (_db != null) {
      final List<Map<String, dynamic>> maps = await _db!.query(
        'statistics',
        where: 'counterId = ? AND (dateTimeStamp BETWEEN ? AND ?)',
        whereArgs: [counterId, start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
      );
      List<Statistics> statistics = maps
          .map((Map<String, dynamic> json) => Statistics.fromJson(json))
          .toList();
      statistics.sort((a, b) => a.dateTimeStamp!.compareTo(b.dateTimeStamp!));
      return statistics;
    }
    return List.empty();
  }

  @override
  Future<List<Statistics>> getAllStatistics() async {
    if (_db != null) {
      final List<Map<String, dynamic>> maps = await _db!.query('statistics');
      List<Statistics> statistics = maps
          .map((Map<String, dynamic> json) => Statistics.fromJson(json))
          .toList();
      statistics.sort((a, b) => a.dateTimeStamp!.compareTo(b.dateTimeStamp!));
      return statistics;
    }
    return List.empty();
  }

  @override
  Future<bool> deleteAllStatistics() async {
    if (_db != null) {
      final bool updated = await _db!.transaction((txn) async {
        final int count = await txn.delete('statistics');
        return count > 0;
      });
      return updated;
    } else {
      return false;
    }
  }

  @override
  Future<int> batchInsertCounters(List<Map<String, Object?>> jsonList) async {
    if (_db != null) {
      sql.Batch batch = _db!.batch();
      for (var i = 0; i < jsonList.length; i++)
      {
        Map<String, Object?> json = jsonList[i];
        if (json['folderId'] == null && json['folder'] != null && json['folder'] is Map && (json['folder'] as Map)['id'] != null) {
          json['folderId'] = (json['folder'] as Map)['id'];
        }
        if (json['folder'] != null) {
          json.remove('folder');
        }
        batch.insert('counters', json);
      }
      List<dynamic> inserted = await batch.commit(continueOnError: true);
      return inserted.length;
    } else {
      return 0;
    }
  }

  @override
  Future<int> batchInsertFolders(List<Map<String, Object?>> jsonList) async {
    if (_db != null) {
      sql.Batch batch = _db!.batch();
      for (var i = 0; i < jsonList.length; i++)
      {
        Map<String, Object?> json = jsonList[i];
        if (json.keys.contains('counterNumber')) {
          json.remove('counterNumber');
        }
        batch.insert('folders', json);
      }
      List<dynamic> inserted = await batch.commit(continueOnError: true);
      return inserted.length;
    } else {
      return 0;
    }
  }

  @override
  Future<int> batchInsertStatistics(List<Map<String, Object?>> jsonList)async {
    if (_db != null) {
      sql.Batch batch = _db!.batch();
      for (var i = 0; i < jsonList.length; i++)
      {
        batch.insert('statistics', jsonList[i]);
      }
      List<dynamic> inserted = await batch.commit(continueOnError: true);
      return inserted.length;
    } else {
      return 0;
    }
  }

  @override
  Future<List<Counter>> getAllCountersToSynchronize() async {
    if (_db != null) {
      final List<Map<String, Object?>> countersMap = await _db!.rawQuery('$_selectCounterSql WHERE c.id > 1 AND c.synchronizationTimeStamp IS NULL OR c.synchronizationTimeStamp < c.lastModificationTimeStamp');
      return countersMap
          .map((Map<String, Object?> folderMap) => Counter.fromJson(folderMap))
          .toList();
    } else {
      return [];
    }
  }

  @override
  Future<List<Folder>> getAllFoldersToSynchronize() async {
    if (_db != null) {
      final List<Map<String, Object?>> foldersMap = await _db!.rawQuery('SELECT f.* FROM folders f WHERE f.id > 1 AND (f.synchronizationTimeStamp IS NULL OR f.synchronizationTimeStamp < f.lastModificationTimeStamp)');
      return foldersMap
          .map((Map<String, Object?> folderMap) => Folder.fromJson(folderMap))
          .toList();
    } else {
      return [];
    }
  }

  @override
  Future<bool> updateCountersSynchronizationTimestamp(List<int> counterIds) async {
    if (_db != null) {
      return await _db!.transaction((txn) async {
        final batch = txn.batch();
        for (final id in counterIds) {
          batch.rawUpdate(
            'UPDATE counters SET synchronizationTimeStamp = ? WHERE id = ?',
            [lastSynchronizationTimeStamp, id],
          );
        }
        final results = await batch.commit(noResult: false);
        return results.every((result) => (result as int?) != null && result! > 0);
      });
    } else {
      return false;
    }
  }

  @override
  Future<bool> updateCountersSynchronizationTimestampByFolderId(int folderId) async {
    if (_db != null) {
      final bool updated = await _db!.transaction((txn) async {
        final int count = await txn.rawUpdate(
            'UPDATE counters SET synchronizationTimeStamp = ? WHERE folderId = ?', [lastSynchronizationTimeStamp, folderId]);
        return count > 0;
      });
      return updated;
    } else {
      return false;
    }
  }

  @override
  Future<bool> updateDeletedCountersSynchronizationTimestamp(List<int> counterIds) async {
    if (_db != null) {
      return await _db!.transaction((txn) async {
        final batch = txn.batch();
        for (final id in counterIds) {
          batch.rawUpdate(
            'UPDATE counters_history SET synchronizationTimeStamp = ? WHERE originalId = ?',
            [lastSynchronizationTimeStamp, id],
          );
        }
        final results = await batch.commit(noResult: false);
        return results.every((result) => (result as int?) != null && result! > 0);
      });
    } else {
      return false;
    }
  }

  @override
  Future<bool> updateFoldersSynchronizationTimestamp(List<int> folderIds) async {
    if (_db != null) {
      return await _db!.transaction((txn) async {
        final batch = txn.batch();
        for (final id in folderIds) {
          batch.rawUpdate(
            'UPDATE folders SET synchronizationTimeStamp = ? WHERE id = ?',
            [lastSynchronizationTimeStamp, id],
          );
        }
        final results = await batch.commit(noResult: false);
        return results.every((result) => (result as int?) != null && result! > 0);
      });
    } else {
      return false;
    }
  }

  @override
  Future<bool> updateDeletedFoldersSynchronizationTimestamp(List<int> folderIds) async {
    if (_db != null) {
      return await _db!.transaction((txn) async {
        final batch = txn.batch();
        for (final id in folderIds) {
          batch.rawUpdate(
            'UPDATE folders_history SET synchronizationTimeStamp = ? WHERE originalId = ?',
            [lastSynchronizationTimeStamp, id],
          );
        }
        final results = await batch.commit(noResult: false);
        return results.every((result) => (result as int?) != null && result! > 0);
      });
    } else {
      return false;
    }
  }

  @override
  Future<List<int>> getAllDeletedCounterIdsToSynchronize() async {
    if (_db != null) {
      final List<Map<String, dynamic>> maps = await _db!.query(
        'counters_history',
        columns: ['originalId'],
        where: 'operationType = ? AND synchronizationTimeStamp IS NULL',
        whereArgs: ['DELETE'],
      );
      return List<int>.from(maps.map((map) => map['originalId']));
    } else {
      return [];
    }
  }

  @override
  Future<List<int>> getAllDeletedFolderIdsToSynchronize() async {
    if (_db != null) {
      final List<Map<String, dynamic>> maps = await _db!.query(
        'folders_history',
        columns: ['originalId'],
        where: 'operationType = ? AND synchronizationTimeStamp IS NULL',
        whereArgs: ['DELETE'],
      );
      return List<int>.from(maps.map((map) => map['originalId']));
    } else {
      return [];
    }
  }

  @override
  Future<List<Count>> getCountsByFolderId(int folderId) async {
    if (_db != null) {
      final sql = 'SELECT c.id as counterId, c.counterCount as count FROM counters c WHERE c.folderId = $folderId';
      final List<Map<String, Object?>> countersMap = await _db!.rawQuery(sql);
      return countersMap
          .map((Map<String, Object?> counterMap) => Count.fromJson(counterMap))
          .toList();
    } else {
      return [];
    }
  }

  @override
  Future<bool> synchronizeCountersCount(int folderId) async {
    final List<Count> counts = await getCountsByFolderId(folderId);
    if (counts.isNotEmpty) {
      Response? response = await SynchronizationService().synchronizeCountersCount(counts);
      if (response != null && response.statusCode >= 200 && response.statusCode < 300) {
        return updateCountersSynchronizationTimestampByFolderId(folderId);
      }
    }
    return false;
  }

  @override
  Future<bool> resetCountersSynchronizationTimeStamp() async {
    if (_db != null) {
      final bool updated = await _db!.transaction((txn) async {
        final int count = await txn.rawUpdate('UPDATE counters SET synchronizationTimeStamp = NULL');
        return count > 0;
      });
      return updated;
    } else {
      return false;
    }
  }

  @override
  Future<bool> resetFoldersSynchronizationTimeStamp() async {
    if (_db != null) {
      final bool updated = await _db!.transaction((txn) async {
        final int count = await txn.rawUpdate('UPDATE folders SET synchronizationTimeStamp = NULL');
        return count > 0;
      });
      return updated;
    } else {
      return false;
    }
  }
}
