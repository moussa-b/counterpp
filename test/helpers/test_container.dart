import 'package:counter/providers/counter_repository_provider.dart';
import 'package:counter/repository/database_counter_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_database.dart';

/// A [ProviderContainer] wired to a throwaway SQLite database.
///
/// In production the notifiers reach the repository through
/// [counterRepositoryProvider], which unwraps the FutureProvider that gates
/// app startup. Overriding that one provider hands them a repository that is
/// already open, so a test never has to wait on initialization.
///
/// [ProviderContainer.test] disposes the container when the test ends, and
/// [openTestRepository] deletes the database directory, so nothing survives
/// between cases.
Future<({ProviderContainer container, DatabaseCounterRepository repository})>
openTestContainer() async {
  final DatabaseCounterRepository repository = await openTestRepository();
  final ProviderContainer container = ProviderContainer.test(
    // No type annotation on the list: riverpod 3 keeps `Override` internal.
    overrides: [counterRepositoryProvider.overrideWithValue(repository)],
  );
  // Several notifier methods kick off work they never await — addCounter calls
  // foldersProvider.refresh(), for one. Left alone, that continuation lands
  // after the container is disposed and throws from a torn-down Ref. Tear-downs
  // run last-registered-first, so this drains the queue before the dispose that
  // ProviderContainer.test registered a moment ago.
  addTearDown(pumpEventQueue);
  return (container: container, repository: repository);
}
