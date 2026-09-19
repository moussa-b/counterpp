import 'package:counter/models/folder.dart';
import 'package:counter/models/settings.dart';
import 'package:counter/providers/counters_provider.dart';
import 'package:counter/screens/counter_form_screen.dart';
import 'package:counter/screens/counters_screen.dart';
import 'package:counter/widgets/counter_grid.dart';
import 'package:counter/widgets/counter_list.dart';
import 'package:counter/widgets/counters_popup_menu.dart';
import 'package:counter/widgets/editable_counter_grid.dart';
import 'package:counter/widgets/editable_counter_list.dart';
import 'package:counter/widgets/last_modified_counter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../helpers/fake_counter_repository.dart';
import '../helpers/fake_wakelock.dart';
import '../helpers/test_app.dart';

void main() {
  late FakeCounterRepository repository;
  late Folder folder;

  setUp(() {
    repository = FakeCounterRepository();
    folder = repository.seedFolder('Work');
    installFakeWakelock();
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await pumpApp(
      tester,
      CountersScreen(folder: folder),
      repository: repository,
      wrapInScaffold: false,
    );
    await tester
        .container()
        .read(countersProvider.notifier)
        .setFolderId(folder.id!);
    await tester.pumpAndSettle();
  }

  testWidgets('titles itself with the folder name', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Work'), findsOneWidget);
  });

  group('with no counter yet', () {
    testWidgets('says so and offers to create one', (tester) async {
      await pumpScreen(tester);

      expect(find.text(l10n(tester).noCounter), findsOneWidget);
      expect(find.text(l10n(tester).createNewCounter), findsOneWidget);
    });

    testWidgets('the button opens the counter form', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.text(l10n(tester).createNewCounter));
      await tester.pumpAndSettle();

      expect(find.byType(CounterFormScreen), findsOneWidget);
    });
  });

  group('with counters', () {
    testWidgets('lists them under the last-modified banner', (tester) async {
      repository.seedCounter(name: 'Verses', folder: folder);

      await pumpScreen(tester);

      expect(find.byType(CounterList), findsOneWidget);
      expect(find.byType(LastModifiedCounter), findsOneWidget);
      expect(find.text('Verses'), findsOneWidget);
    });

    testWidgets('the compact setting swaps the list for the grid', (
      tester,
    ) async {
      repository.settings = Settings(counterCompactView: true);
      repository.seedCounter(name: 'Verses', folder: folder);

      await pumpScreen(tester);

      expect(find.byType(CounterGrid), findsOneWidget);
      expect(find.byType(CounterList), findsNothing);
    });
  });

  group('edit mode', () {
    testWidgets('the reorder button swaps in the editable list', (
      tester,
    ) async {
      repository.seedCounter(name: 'Verses', folder: folder);

      await pumpScreen(tester);
      await tester.tap(find.byIcon(Icons.swap_vert));
      await tester.pumpAndSettle();

      expect(find.byType(EditableCounterList), findsOneWidget);
      expect(find.byType(CounterList), findsNothing);
    });

    testWidgets('and the editable grid in compact view', (tester) async {
      repository.settings = Settings(counterCompactView: true);
      repository.seedCounter(name: 'Verses', folder: folder);

      await pumpScreen(tester);
      await tester.tap(find.byIcon(Icons.swap_vert));
      await tester.pumpAndSettle();

      expect(find.byType(EditableCounterGrid), findsOneWidget);
    });

    testWidgets('it hides the sort menu while reordering', (tester) async {
      repository.seedCounter(name: 'Verses', folder: folder);

      await pumpScreen(tester);
      expect(find.byType(CountersPopupMenu), findsOneWidget);

      await tester.tap(find.byIcon(Icons.swap_vert));
      await tester.pumpAndSettle();

      expect(find.byType(CountersPopupMenu), findsNothing);
    });

    testWidgets('the done button leaves edit mode', (tester) async {
      repository.seedCounter(name: 'Verses', folder: folder);

      await pumpScreen(tester);
      await tester.tap(find.byIcon(Icons.swap_vert));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byWidgetPredicate(
          (Widget widget) =>
              widget is FaIcon &&
              widget.icon == FontAwesomeIcons.checkDouble.data,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CounterList), findsOneWidget);
      expect(find.byType(EditableCounterList), findsNothing);
    });
  });

  testWidgets('the add button opens the counter form', (tester) async {
    repository.seedCounter(name: 'Verses', folder: folder);

    await pumpScreen(tester);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.byType(CounterFormScreen), findsOneWidget);
  });

  testWidgets('it does not crash while the settings are still loading', (
    tester,
  ) async {
    // The regression this pins: the loading branch had no `else`, so the
    // screen fell through and dereferenced settings.value while it was null.
    repository.seedCounter(name: 'Verses', folder: folder);

    await pumpApp(
      tester,
      CountersScreen(folder: folder),
      repository: repository,
      wrapInScaffold: false,
    );

    expect(tester.takeException(), isNull);
  });
}
