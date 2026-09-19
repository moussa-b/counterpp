import 'package:counter/models/folder.dart';
import 'package:counter/screens/counters_screen.dart';
import 'package:counter/widgets/folder_bottom_sheet.dart';
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

  testWidgets('shows the folder name and how many counters it holds', (
    tester,
  ) async {
    final Folder folder = repository.seedFolder('Work', counterNumber: 3);

    await pumpApp(
      tester,
      FolderListItem(folder: folder),
      repository: repository,
    );

    expect(find.text('Work'), findsOneWidget);
    expect(find.text(l10n(tester).counterNumber(3)), findsOneWidget);
    expect(find.byIcon(Icons.folder), findsOneWidget);
  });

  testWidgets('an empty folder says so rather than showing nothing', (
    tester,
  ) async {
    final Folder folder = repository.seedFolder('Empty');

    await pumpApp(
      tester,
      FolderListItem(folder: folder),
      repository: repository,
    );

    expect(find.text(l10n(tester).counterNumber(0)), findsOneWidget);
  });

  testWidgets('tapping it opens that folder', (tester) async {
    final Folder folder = repository.seedFolder('Work');
    repository.seedCounter(name: 'Verses', folder: folder);

    await pumpApp(
      tester,
      FolderListItem(folder: folder),
      repository: repository,
    );
    await tester.tap(find.text('Work'));
    await tester.pumpAndSettle();

    expect(find.byType(CountersScreen), findsOneWidget);
  });

  testWidgets('the overflow button opens the folder bottom sheet', (
    tester,
  ) async {
    final Folder folder = repository.seedFolder('Work');

    await pumpApp(
      tester,
      FolderListItem(folder: folder),
      repository: repository,
    );
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    expect(find.byType(FolderBottomSheet), findsOneWidget);
  });

  group('inactive mode', () {
    // The reorderable folder list renders its rows inactive so a drag is never
    // mistaken for a tap.
    testWidgets('hides the overflow button', (tester) async {
      final Folder folder = repository.seedFolder('Work');

      await pumpApp(
        tester,
        FolderListItem(folder: folder, active: false),
        repository: repository,
      );

      expect(find.byIcon(Icons.more_vert), findsNothing);
    });

    testWidgets('does not open the folder when tapped', (tester) async {
      final Folder folder = repository.seedFolder('Work');

      await pumpApp(
        tester,
        FolderListItem(folder: folder, active: false),
        repository: repository,
      );
      await tester.tap(find.text('Work'));
      await tester.pumpAndSettle();

      expect(find.byType(CountersScreen), findsNothing);
    });
  });
}
