import 'package:counterpp/models/counter.dart';
import 'package:counterpp/models/folder.dart';
import 'package:counterpp/models/reorder_item.dart';
import 'package:counterpp/models/settings.dart';
import 'package:counterpp/models/sorting_options.dart';
import 'package:flutter/services.dart' show rootBundle;
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

  get lastModificationTimeStamp {
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
        version: 1,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (db, version) async {
          String sql = await rootBundle
              .loadString('assets/sql_scripts/folder_table_create.sql');
          await db.execute(sql);
          sql = await rootBundle
              .loadString('assets/sql_scripts/counter_table_create.sql');
          await db.execute(sql);
          sql = await rootBundle
              .loadString('assets/sql_scripts/statistics_table_create.sql');
          await db.execute(sql);
          sql = await rootBundle
              .loadString('assets/sql_scripts/settings_table_create.sql');
          await db.execute(sql);
          sql = await rootBundle.loadString(
              'assets/sql_scripts/folder_table_sample.sql'); // TODO replace by folder_table_populate.sql
          await db.execute(sql);
          sql = await rootBundle.loadString(
              'assets/sql_scripts/counter_table_sample.sql'); // TODO replace by counter_table_populate.sql
          await db.execute(sql);
          sql = await rootBundle.loadString(
              'assets/sql_scripts/statistics_table_sample.sql'); // TODO remove
          await db.execute(sql);
        },
      );
      return _db != null;
    }
  }

  @override
  Future<bool> resetCounterById(int counterId) async {
    if (_db != null) {
      final bool updateDated = await _db!.transaction((txn) async {
        final int count = await txn.rawUpdate(
            'UPDATE counters SET counterCount = 0, lastModificationTimeStamp = ? WHERE id = ?', [lastModificationTimeStamp, counterId]);
        return count > 0;
      });
      return updateDated;
    } else {
      return false;
    }
  }

  @override
  Future<bool> decrementCounterById(int counterId, {value = 1}) async {
    if (_db != null) {
      final bool updateDated = await _db!.transaction((txn) async {
        final int count = await txn.rawUpdate(
            'UPDATE counters SET counterCount = (IFNULL(counterCount, 0) - ?), lastModificationTimeStamp = ? WHERE id = ?',
            [value, lastModificationTimeStamp, counterId]);
        return count > 0;
      });
      return updateDated;
    } else {
      return false;
    }
  }

  @override
  Future<bool> incrementCounterById(int counterId, {value = 1}) async {
    if (_db != null) {
      final bool updateDated = await _db!.transaction((txn) async {
        final int count = await txn.rawUpdate(
            'UPDATE counters SET counterCount = (IFNULL(counterCount, 0) + ?), lastModificationTimeStamp = ? WHERE id = ?',
            [value, lastModificationTimeStamp, counterId]);
        return count > 0;
      });
      return updateDated;
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
        lastModificationTimeStamp,
        counterLimit,
        folderId,
        color,
        counterOrder,
        orderInFolder,
        step,
        note
        )
        VALUES (
        "${counter.name}",
        ${counter.counterCount},
        $now,
        $now,
        ${counter.counterLimit},
        ${counter.folder?.id},
        '${counter.color}',
        1 + (SELECT COUNT(*) FROM counters),
        ${counter.folder?.id != null && counter.folder!.id! > 0 ? ('1 + (SELECT COUNT(*) FROM counters WHERE folderId = ${counter.folder!.id!})') : null}, 
        ${counter.step ?? 1},
        "${counter.note}"
        );
        """;
        print(query);
        int insertedId = await txn.rawInsert(query);
        return insertedId;
      });
      if (id > 0) {
        return getCounterById(id);
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
    }

    return deleted == 1;
  }

  @override
  Future<List<Counter>> getAllCounters() async {
    if (_db != null) {
      final List<Map<String, Object?>> countersMap = await _db!.rawQuery(_selectCounterSql);
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
            return (folder2.creationTimeStamp ?? 0) - (folder1.creationTimeStamp ??  0);;
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
      const String sql = """
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
      final List<Map<String, Object?>> foldersMap = await _db!.rawQuery(sql);
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
            return (counter2.creationTimeStamp ?? 0) - (counter1.creationTimeStamp ??  0);;
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
        return getCounterById(counter.id!);
      }
    }
    return Counter();
  }

  @override
  Future<Folder> createFolder(String folderName) async {
    if (_db != null) {
      final id = await _db!.transaction((txn) async {
        final String query = """
        INSERT INTO folders(name, creationTimeStamp, lastModificationTimeStamp, "folderOrder")
        VALUES("$folderName", $lastModificationTimeStamp, $lastModificationTimeStamp, (SELECT COUNT(*) FROM folders))
        """;
        print(query);
        int insertedId = await txn.rawInsert(query);
        return insertedId;
      });
      if (id > 0) {
        return getFolderById(id);
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
        return getFolderById(folderId);
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
    }

    return deleted == 1;
  }

  @override
  Future<bool> resetAllCountersForFolderId(int folderId) async {
    if (_db != null) {
      final bool updateDated = await _db!.transaction((txn) async {
        final int count = await txn.rawUpdate(
            'UPDATE counters SET counterCount = 0, lastModificationTimeStamp = ? WHERE folderId = ?', [lastModificationTimeStamp, folderId]);
        return count > 0;
      });
      return updateDated;
    } else {
      return false;
    }
  }

  @override
  Future<bool> deleteAllCountersForFolderId(int folderId) async {
    if (_db != null) {
      final bool updateDated = await _db!.transaction((txn) async {
        final int count = await txn.rawUpdate(
            'DELETE FROM counters WHERE folderId = ?', [folderId]);
        return count > 0;
      });
      return updateDated;
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
            """REPLACE INTO settings (id, counterCompactView, counterSorting, folderSorting, lastModificationTimeStamp)
            VALUES(
            1,
            ${settings.counterCompactView == true ? 1 : 0},
            ${settings.counterSorting?.index},
            ${settings.folderSorting?.index}, 
            $lastModificationTimeStamp)""");
        return count > 0;
      });
      if (updated) {
        return getSettings();
      }
    }
    return Settings.copy(settings);
  }
}
