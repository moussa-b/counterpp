import 'dart:io';

import 'package:counter/repository/database_counter_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Boots a real SQLite engine on the host VM.
///
/// The repository tests run against the production schema, triggers and
/// foreign keys rather than a stub, so a query that is wrong in SQLite is wrong
/// in the test too. Call once per test file, before any repository is opened.
void initializeTestDatabaseFactory() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}

/// Creates a repository backed by its own throwaway database directory, so no
/// state survives between test cases.
Future<DatabaseCounterRepository> openTestRepository() async {
  final Directory directory = await Directory.systemTemp.createTemp(
    'counterpp_test_',
  );
  final DatabaseCounterRepository repository = DatabaseCounterRepository(
    databaseDirectory: directory.path,
  );
  addTearDown(() async {
    await repository.close();
    if (directory.existsSync()) {
      await directory.delete(recursive: true);
    }
  });
  await repository.initialize();
  return repository;
}
