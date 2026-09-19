import 'dart:async';

import 'package:counter/models/folder.dart';
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

  /// Opens the dialog the way the folders screen does and reports what it
  /// popped with, since the caller uses that folder to update its list.
  Future<Folder?> openDialog(WidgetTester tester, {Folder? folder}) async {
    Folder? popped;
    late BuildContext host;

    await pumpApp(
      tester,
      Builder(
        builder: (BuildContext context) {
          host = context;
          return const SizedBox.shrink();
        },
      ),
      repository: repository,
    );

    unawaited(
      showDialog<Folder?>(
        context: host,
        builder: (_) => FolderDialog(folder: folder),
      ).then((Folder? value) => popped = value),
    );
    await tester.pumpAndSettle();
    return popped;
  }

  group('creating', () {
    testWidgets('asks for a name on an empty field', (tester) async {
      await openDialog(tester);

      expect(find.text(l10n(tester).createNewFolder), findsOneWidget);
      expect(
        find.text(l10n(tester).createNewFolderPlaceholder),
        findsOneWidget,
      );
      expect(find.widgetWithText(TextField, 'Work'), findsNothing);
    });

    testWidgets('validating creates the folder', (tester) async {
      await openDialog(tester);
      await tester.enterText(find.byType(TextField), 'Work');
      await tester.tap(find.text(l10n(tester).validate));
      await tester.pumpAndSettle();

      expect(repository.calls, contains('createFolder(Work)'));
      expect(
        repository.folders.values.map((Folder folder) => folder.name),
        contains('Work'),
      );
    });

    testWidgets('submitting from the keyboard creates it too', (tester) async {
      await openDialog(tester);
      await tester.enterText(find.byType(TextField), 'Work');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(repository.calls, contains('createFolder(Work)'));
    });

    testWidgets('surrounding whitespace is trimmed off the name', (
      tester,
    ) async {
      await openDialog(tester);
      await tester.enterText(find.byType(TextField), '  Work  ');
      await tester.tap(find.text(l10n(tester).validate));
      await tester.pumpAndSettle();

      expect(repository.calls, contains('createFolder(Work)'));
    });

    testWidgets('a blank name creates nothing and just closes', (tester) async {
      await openDialog(tester);
      await tester.enterText(find.byType(TextField), '   ');
      await tester.tap(find.text(l10n(tester).validate));
      await tester.pumpAndSettle();

      expect(repository.calls, isEmpty);
      expect(find.byType(FolderDialog), findsNothing);
    });

    testWidgets('cancelling creates nothing', (tester) async {
      await openDialog(tester);
      await tester.enterText(find.byType(TextField), 'Work');
      await tester.tap(find.text(l10n(tester).cancel));
      await tester.pumpAndSettle();

      expect(repository.calls, isEmpty);
      expect(find.byType(FolderDialog), findsNothing);
    });
  });

  group('renaming', () {
    testWidgets('opens on the current name, ready to edit', (tester) async {
      final Folder folder = repository.seedFolder('Work');

      await openDialog(tester, folder: folder);

      expect(find.text(l10n(tester).renameFolder), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Work'), findsOneWidget);
    });

    testWidgets('validating renames rather than creating a second folder', (
      tester,
    ) async {
      final Folder folder = repository.seedFolder('Work');

      await openDialog(tester, folder: folder);
      await tester.enterText(find.byType(TextField), 'Study');
      await tester.tap(find.text(l10n(tester).validate));
      await tester.pumpAndSettle();

      expect(repository.calls, contains('renameFolder(${folder.id}, Study)'));
      expect(repository.folders.length, 1);
      expect(repository.folders[folder.id]!.name, 'Study');
    });
  });
}
