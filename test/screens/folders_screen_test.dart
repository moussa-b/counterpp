import 'package:counter/screens/folders_screen.dart';
import 'package:counter/widgets/editable_folder_list.dart';
import 'package:counter/widgets/folder_dialog.dart';
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

  Future<void> pumpScreen(WidgetTester tester, {bool editMode = false}) {
    return pumpApp(
      tester,
      FoldersScreen(editMode: editMode),
      repository: repository,
    );
  }

  group('with no folder yet', () {
    testWidgets('says so and offers to create one', (tester) async {
      await pumpScreen(tester);

      expect(find.text(l10n(tester).noFolder), findsOneWidget);
      expect(find.text(l10n(tester).createNewFolder), findsOneWidget);
    });

    testWidgets('the button opens the folder dialog', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.text(l10n(tester).createNewFolder));
      await tester.pumpAndSettle();

      expect(find.byType(FolderDialog), findsOneWidget);
    });

    testWidgets('creating one from there puts it on the screen', (
      tester,
    ) async {
      await pumpScreen(tester);
      await tester.tap(find.text(l10n(tester).createNewFolder));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Work');
      await tester.tap(find.text(l10n(tester).validate));
      await tester.pumpAndSettle();

      expect(find.text('Work'), findsOneWidget);
      expect(find.text(l10n(tester).noFolder), findsNothing);
    });
  });

  group('with folders', () {
    testWidgets('lists them', (tester) async {
      repository.seedFolder('Work');
      repository.seedFolder('Home');

      await pumpScreen(tester);

      expect(find.byType(FolderList), findsOneWidget);
      expect(find.byType(FolderListItem), findsNWidgets(2));
    });

    testWidgets('edit mode swaps in the reorderable list', (tester) async {
      repository.seedFolder('Work');

      await pumpScreen(tester, editMode: true);

      expect(find.byType(EditableFolderList), findsOneWidget);
      expect(find.byType(FolderList), findsNothing);
    });

    testWidgets('the ordinary list is the one shown outside edit mode', (
      tester,
    ) async {
      repository.seedFolder('Work');

      await pumpScreen(tester);

      expect(find.byType(FolderList), findsOneWidget);
      expect(find.byType(EditableFolderList), findsNothing);
    });
  });
}
