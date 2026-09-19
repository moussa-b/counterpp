import 'package:counter/models/counter.dart';
import 'package:counter/models/folder.dart';
import 'package:counter/screens/folder_statistics_screen.dart';
import 'package:counter/widgets/folder_bottom_sheet.dart';
import 'package:counter/widgets/folder_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_counter_repository.dart';
import '../helpers/test_app.dart';

void main() {
  late FakeCounterRepository repository;

  setUp(() {
    repository = FakeCounterRepository();
  });

  Folder seedFolderWithCounters(int count) {
    final Folder folder = repository.seedFolder('Work');
    for (int index = 0; index < count; index++) {
      repository.seedCounter(name: 'Counter $index', folder: folder);
    }
    return folder;
  }

  Future<void> open(WidgetTester tester, Folder folder) {
    return openBottomSheet<void>(
      tester,
      FolderBottomSheet(folder: folder),
      repository: repository,
    );
  }

  Future<void> confirm(WidgetTester tester) async {
    await tester.tap(find.text(l10n(tester).validate));
    await tester.pumpAndSettle();
  }

  testWidgets('heads the sheet with the name and the counter count', (
    tester,
  ) async {
    await open(tester, seedFolderWithCounters(2));

    expect(find.text('Work'), findsOneWidget);
    expect(find.text(l10n(tester).counterNumber(2)), findsOneWidget);
  });

  group('an empty folder', () {
    // Resetting, clearing or charting counters that do not exist makes no
    // sense, so those entries are not offered at all.
    testWidgets('offers only rename, duplicate and delete', (tester) async {
      await open(tester, repository.seedFolder('Empty'));

      expect(find.text(l10n(tester).rename), findsOneWidget);
      expect(find.text(l10n(tester).duplicate), findsOneWidget);
      expect(find.text(l10n(tester).delete), findsOneWidget);
      expect(find.text(l10n(tester).resetAllCounters), findsNothing);
      expect(find.text(l10n(tester).deleteAllCounters), findsNothing);
      expect(find.text(l10n(tester).statistics), findsNothing);
    });

    testWidgets('can still be deleted', (tester) async {
      final Folder folder = repository.seedFolder('Empty');

      await open(tester, folder);
      await tester.tap(find.text(l10n(tester).delete));
      await tester.pumpAndSettle();
      await confirm(tester);

      expect(repository.calls, contains('deleteFolderById(${folder.id})'));
    });
  });

  group('a folder holding counters', () {
    testWidgets('offers every entry', (tester) async {
      await open(tester, seedFolderWithCounters(2));

      expect(find.text(l10n(tester).rename), findsOneWidget);
      expect(find.text(l10n(tester).duplicate), findsOneWidget);
      expect(find.text(l10n(tester).resetAllCounters), findsOneWidget);
      expect(find.text(l10n(tester).delete), findsOneWidget);
      expect(find.text(l10n(tester).deleteAllCounters), findsOneWidget);
      expect(find.text(l10n(tester).statistics), findsOneWidget);
    });

    testWidgets('statistics opens the folder chart', (tester) async {
      await open(tester, seedFolderWithCounters(2));
      await tester.tap(find.text(l10n(tester).statistics));
      await tester.pumpAndSettle();

      expect(find.byType(FolderStatisticsScreen), findsOneWidget);
    });
  });

  testWidgets('rename opens the folder dialog on the current name', (
    tester,
  ) async {
    await open(tester, seedFolderWithCounters(1));
    await tester.tap(find.text(l10n(tester).rename));
    await tester.pumpAndSettle();

    expect(find.byType(FolderDialog), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Work'), findsOneWidget);
  });

  testWidgets('duplicate copies the folder with a suffix', (tester) async {
    await open(tester, seedFolderWithCounters(1));
    await tester.tap(find.text(l10n(tester).duplicate));
    await tester.pumpAndSettle();

    expect(
      repository.folders.values.map((Folder folder) => folder.name),
      contains('Work - ${l10n(tester).copy}'),
    );
  });

  group('reset all counters', () {
    testWidgets('warns first and changes nothing yet', (tester) async {
      final Folder folder = seedFolderWithCounters(2);
      for (final Counter counter in repository.counters.values) {
        counter.counterCount = 5;
      }

      await open(tester, folder);
      await tester.tap(find.text(l10n(tester).resetAllCounters));
      await tester.pumpAndSettle();

      expect(find.text(l10n(tester).warning), findsOneWidget);
      expect(
        find.text(l10n(tester).warningMsgResetFolderCounters),
        findsOneWidget,
      );
      expect(
        repository.counters.values.every(
          (Counter counter) => counter.counterCount == 5,
        ),
        isTrue,
      );
    });

    testWidgets('confirming zeroes every counter but keeps them', (
      tester,
    ) async {
      final Folder folder = seedFolderWithCounters(2);
      for (final Counter counter in repository.counters.values) {
        counter.counterCount = 5;
      }

      await open(tester, folder);
      await tester.tap(find.text(l10n(tester).resetAllCounters));
      await tester.pumpAndSettle();
      await confirm(tester);

      expect(
        repository.calls,
        contains('resetAllCountersForFolderId(${folder.id})'),
      );
      expect(repository.counters.length, 2);
      expect(
        repository.counters.values.every(
          (Counter counter) => counter.counterCount == 0,
        ),
        isTrue,
      );
    });
  });

  group('delete all counters', () {
    testWidgets('confirming empties the folder but keeps the folder', (
      tester,
    ) async {
      final Folder folder = seedFolderWithCounters(2);

      await open(tester, folder);
      await tester.tap(find.text(l10n(tester).deleteAllCounters));
      await tester.pumpAndSettle();
      await confirm(tester);

      expect(
        repository.calls,
        contains('deleteAllCountersForFolderId(${folder.id})'),
      );
      expect(repository.counters, isEmpty);
      expect(repository.folders, contains(folder.id));
    });

    testWidgets('cancelling keeps the counters', (tester) async {
      final Folder folder = seedFolderWithCounters(2);

      await open(tester, folder);
      await tester.tap(find.text(l10n(tester).deleteAllCounters));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n(tester).cancel));
      await tester.pumpAndSettle();

      expect(repository.counters.length, 2);
    });
  });

  group('delete the folder', () {
    testWidgets('warns that the counters go with it', (tester) async {
      await open(tester, seedFolderWithCounters(2));
      await tester.tap(find.text(l10n(tester).delete));
      await tester.pumpAndSettle();

      expect(find.text(l10n(tester).warningMsgDeleteFolder), findsOneWidget);
    });

    testWidgets('confirming takes the folder and its counters', (tester) async {
      final Folder folder = seedFolderWithCounters(2);

      await open(tester, folder);
      await tester.tap(find.text(l10n(tester).delete));
      await tester.pumpAndSettle();
      await confirm(tester);

      expect(repository.calls, contains('deleteFolderById(${folder.id})'));
      expect(repository.folders, isEmpty);
      expect(repository.counters, isEmpty);
    });
  });
}
