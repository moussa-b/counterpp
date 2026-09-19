import 'package:counter/models/folder.dart';
import 'package:counter/models/sorting_options.dart';
import 'package:counter/providers/folders_provider.dart';
import 'package:counter/widgets/editable_folder_list.dart';
import 'package:counter/widgets/folder_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_counter_repository.dart';
import '../helpers/test_app.dart';

void main() {
  late FakeCounterRepository repository;
  late List<Folder> folders;

  setUp(() {
    repository = FakeCounterRepository();
    folders = <Folder>[
      for (final String name in <String>['A', 'B', 'C', 'D'])
        repository.seedFolder(name),
    ];
  });

  Future<void> pumpEditableList(WidgetTester tester) async {
    await pumpApp(
      tester,
      EditableFolderList(folders: folders),
      repository: repository,
    );
    // The notifier reorders its own state, so it has to be holding the folders
    // the list is showing.
    await tester.container().read(foldersProvider.future);
    await tester.pumpAndSettle();
  }

  Future<void> reorder(WidgetTester tester, int from, int to) async {
    final ReorderableListView list = tester.widget<ReorderableListView>(
      find.byType(ReorderableListView),
    );
    list.onReorderItem!(from, to);
    await tester.pumpAndSettle();
  }

  List<String> persistedOrder() {
    final List<Folder> sorted = repository.folders.values.toList()
      ..sort(
        (Folder a, Folder b) => (a.folderOrder ?? 0) - (b.folderOrder ?? 0),
      );
    return sorted.map((Folder folder) => folder.name!).toList();
  }

  testWidgets('renders one row per folder, all inactive', (tester) async {
    await pumpEditableList(tester);

    expect(find.byType(FolderListItem), findsNWidgets(4));
    expect(
      tester
          .widgetList<FolderListItem>(find.byType(FolderListItem))
          .every((FolderListItem item) => !item.active),
      isTrue,
      reason: 'an active row would open the folder on the start of a drag',
    );
  });

  testWidgets('uses onReorderItem, not the deprecated onReorder', (
    tester,
  ) async {
    await pumpEditableList(tester);

    final ReorderableListView list = tester.widget<ReorderableListView>(
      find.byType(ReorderableListView),
    );
    expect(list.onReorderItem, isNotNull);
    expect(list.onReorder, isNull);
  });

  testWidgets('moving a folder down persists the new order', (tester) async {
    await pumpEditableList(tester);

    await reorder(tester, 0, 2);

    expect(repository.calls, contains('reorderFolders(4)'));
    expect(persistedOrder(), <String>['B', 'C', 'A', 'D']);
  });

  testWidgets('moving a folder up persists the new order', (tester) async {
    await pumpEditableList(tester);

    await reorder(tester, 3, 1);

    expect(persistedOrder(), <String>['A', 'D', 'B', 'C']);
  });

  testWidgets('a reorder switches the folder sorting to custom', (
    tester,
  ) async {
    await pumpEditableList(tester);

    await reorder(tester, 0, 1);

    expect(repository.settings.folderSorting, SortingOptions.custom);
  });
}
