import 'package:counter/models/settings.dart';
import 'package:counter/models/sorting_options.dart';
import 'package:counter/widgets/folders_popup_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../helpers/fake_counter_repository.dart';
import '../helpers/test_app.dart';

void main() {
  late FakeCounterRepository repository;

  setUp(() {
    repository = FakeCounterRepository();
  });

  Finder faIcon(FaIconData icon) {
    return find.byWidgetPredicate(
      (Widget widget) => widget is FaIcon && widget.icon == icon.data,
    );
  }

  Future<void> openMenu(WidgetTester tester, {SortingOptions? sorting}) async {
    repository.settings = Settings(folderSorting: sorting);

    await pumpApp(
      tester,
      const Scaffold(body: FoldersPopupMenu()),
      repository: repository,
      wrapInScaffold: false,
    );
    await tester.tap(faIcon(FontAwesomeIcons.sliders));
    await tester.pumpAndSettle();
  }

  SortingOptions? storedSorting() => repository.settings.folderSorting;

  testWidgets('lists the sort options, and no compact view toggle', (
    tester,
  ) async {
    // Compact view is a counter-grid setting; folders have no such view.
    await openMenu(tester);

    expect(find.text(l10n(tester).sortBy), findsOneWidget);
    expect(find.text(l10n(tester).custom), findsOneWidget);
    expect(find.text(l10n(tester).alphabeticalOrder), findsOneWidget);
    expect(find.text(l10n(tester).counterCountOrder), findsOneWidget);
    expect(find.text(l10n(tester).creationDate), findsOneWidget);
    expect(find.text(l10n(tester).compactView), findsNothing);
  });

  group('picking a sort writes folderSorting, never counterSorting', () {
    testWidgets('alphabetical starts ascending', (tester) async {
      await openMenu(tester);
      await tester.tap(find.text(l10n(tester).alphabeticalOrder));
      await tester.pumpAndSettle();

      expect(storedSorting(), SortingOptions.alphabeticalAsc);
      expect(repository.settings.counterSorting, isNull);
    });

    testWidgets('picking it again flips to descending', (tester) async {
      await openMenu(tester, sorting: SortingOptions.alphabeticalAsc);
      await tester.tap(
        find.text(l10n(tester).alphabeticalOrderWithSuffix('(A-Z)')),
      );
      await tester.pumpAndSettle();

      expect(storedSorting(), SortingOptions.alphabeticalDesc);
    });

    testWidgets('a third pick clears it', (tester) async {
      await openMenu(tester, sorting: SortingOptions.alphabeticalDesc);
      await tester.tap(
        find.text(l10n(tester).alphabeticalOrderWithSuffix('(Z-A)')),
      );
      await tester.pumpAndSettle();

      expect(storedSorting(), isNull);
    });

    testWidgets('counter count starts ascending', (tester) async {
      await openMenu(tester);
      await tester.tap(find.text(l10n(tester).counterCountOrder));
      await tester.pumpAndSettle();

      expect(storedSorting(), SortingOptions.valueAsc);
    });

    testWidgets('creation date starts ascending', (tester) async {
      await openMenu(tester);
      await tester.tap(find.text(l10n(tester).creationDate));
      await tester.pumpAndSettle();

      expect(storedSorting(), SortingOptions.creationDateAsc);
    });

    testWidgets('custom toggles off when it is already on', (tester) async {
      await openMenu(tester, sorting: SortingOptions.custom);
      await tester.tap(find.text(l10n(tester).custom));
      await tester.pumpAndSettle();

      expect(storedSorting(), isNull);
    });
  });

  group('the arrow shows which way the sort runs', () {
    testWidgets('ascending alphabetical shows the A-Z arrow', (tester) async {
      await openMenu(tester, sorting: SortingOptions.alphabeticalAsc);

      expect(faIcon(FontAwesomeIcons.arrowUpZA), findsOneWidget);
    });

    testWidgets('descending count shows the 9-1 arrow', (tester) async {
      await openMenu(tester, sorting: SortingOptions.valueDesc);

      expect(faIcon(FontAwesomeIcons.arrowDown19), findsOneWidget);
    });

    testWidgets('descending creation date shows a plain down arrow', (
      tester,
    ) async {
      await openMenu(tester, sorting: SortingOptions.creationDateDesc);

      expect(faIcon(FontAwesomeIcons.arrowDown), findsOneWidget);
    });

    testWidgets('no sorting means no arrow', (tester) async {
      await openMenu(tester);

      expect(faIcon(FontAwesomeIcons.arrowUpZA), findsNothing);
      expect(faIcon(FontAwesomeIcons.arrowDown19), findsNothing);
      expect(faIcon(FontAwesomeIcons.arrowDown), findsNothing);
    });
  });
}
