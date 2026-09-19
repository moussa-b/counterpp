import 'package:counter/widgets/folders_app_bar.dart';
import 'package:counter/widgets/folders_popup_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../helpers/fake_counter_repository.dart';
import '../helpers/test_app.dart';

void main() {
  late FakeCounterRepository repository;
  late List<bool> editModeChanges;

  setUp(() {
    repository = FakeCounterRepository();
    editModeChanges = <bool>[];
  });

  Finder faIcon(FaIconData icon) {
    return find.byWidgetPredicate(
      (Widget widget) => widget is FaIcon && widget.icon == icon.data,
    );
  }

  Future<void> pumpAppBar(WidgetTester tester) {
    return pumpApp(
      tester,
      Scaffold(
        appBar: FoldersAppBar(
          onEditModeChange: (bool editMode) => editModeChanges.add(editMode),
        ),
      ),
      repository: repository,
      wrapInScaffold: false,
    );
  }

  testWidgets('shows the folder list title and the sort menu', (tester) async {
    await pumpAppBar(tester);

    expect(find.text(l10n(tester).folderList), findsOneWidget);
    expect(find.byType(FoldersPopupMenu), findsOneWidget);
  });

  testWidgets('starts out of edit mode, offering the reorder button', (
    tester,
  ) async {
    await pumpAppBar(tester);

    expect(find.byIcon(Icons.swap_vert), findsOneWidget);
    expect(faIcon(FontAwesomeIcons.checkDouble), findsNothing);
    expect(editModeChanges, isEmpty);
  });

  testWidgets('the reorder button turns edit mode on and reports it', (
    tester,
  ) async {
    await pumpAppBar(tester);
    await tester.tap(find.byIcon(Icons.swap_vert));
    await tester.pumpAndSettle();

    expect(editModeChanges, <bool>[true]);
    expect(faIcon(FontAwesomeIcons.checkDouble), findsOneWidget);
    expect(find.byIcon(Icons.swap_vert), findsNothing);
  });

  testWidgets('the sort menu is hidden while reordering', (tester) async {
    // Sorting and a manual order are mutually exclusive, so the menu goes away
    // rather than offering to undo the drag that is in progress.
    await pumpAppBar(tester);
    await tester.tap(find.byIcon(Icons.swap_vert));
    await tester.pumpAndSettle();

    expect(find.byType(FoldersPopupMenu), findsNothing);
  });

  testWidgets('the done button turns edit mode back off', (tester) async {
    await pumpAppBar(tester);
    await tester.tap(find.byIcon(Icons.swap_vert));
    await tester.pumpAndSettle();
    await tester.tap(faIcon(FontAwesomeIcons.checkDouble));
    await tester.pumpAndSettle();

    expect(editModeChanges, <bool>[true, false]);
    expect(find.byIcon(Icons.swap_vert), findsOneWidget);
    expect(find.byType(FoldersPopupMenu), findsOneWidget);
  });
}
