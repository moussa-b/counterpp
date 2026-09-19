import 'package:counter/models/folder.dart';
import 'package:counter/widgets/folder_list.dart';
import 'package:counter/widgets/folder_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_counter_repository.dart';
import '../helpers/test_app.dart';

void main() {
  late FakeCounterRepository repository;

  setUp(() {
    repository = FakeCounterRepository();
  });

  List<Folder> seedFolders(int count) {
    return <Folder>[
      for (int index = 0; index < count; index++)
        repository.seedFolder('Folder $index'),
    ];
  }

  testWidgets('renders one row per folder, in the order given', (tester) async {
    final List<Folder> folders = seedFolders(3);

    await pumpApp(tester, FolderList(folders: folders), repository: repository);

    expect(find.byType(FolderListItem), findsNWidgets(3));
    final List<String> shown = tester
        .widgetList<FolderListItem>(find.byType(FolderListItem))
        .map((FolderListItem item) => item.folder.name!)
        .toList();
    expect(shown, <String>['Folder 0', 'Folder 1', 'Folder 2']);
  });

  testWidgets('an empty list renders nothing rather than failing', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const FolderList(folders: <Folder>[]),
      repository: repository,
    );

    expect(find.byType(FolderListItem), findsNothing);
  });

  testWidgets('each row carries a key built from the folder id', (
    tester,
  ) async {
    final List<Folder> folders = seedFolders(2);

    await pumpApp(tester, FolderList(folders: folders), repository: repository);

    final FolderListItem first = tester.widget<FolderListItem>(
      find.byType(FolderListItem).first,
    );
    expect(
      (first.key! as ValueKey<String>).value,
      startsWith('${folders.first.id}-'),
    );
  });

  testWidgets('the rows are active, so they open their folder', (tester) async {
    await pumpApp(
      tester,
      FolderList(folders: seedFolders(1)),
      repository: repository,
    );

    expect(
      tester.widget<FolderListItem>(find.byType(FolderListItem)).active,
      isTrue,
    );
  });
}
