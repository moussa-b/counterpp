import 'package:counter/models/settings.dart';
import 'package:counter/models/sorting_options.dart';
import 'package:counter/widgets/counters_popup_menu.dart';
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

  /// Opens the menu, having stored [sorting] as the sorting in effect.
  Future<void> openMenu(WidgetTester tester, {SortingOptions? sorting}) async {
    repository.settings = Settings(
      counterSorting: sorting,
      counterCompactView: false,
    );

    await pumpApp(
      tester,
      const Scaffold(appBar: null, body: CountersPopupMenu()),
      repository: repository,
      wrapInScaffold: false,
    );
    await tester.tap(faIcon(FontAwesomeIcons.sliders));
    await tester.pumpAndSettle();
  }

  /// The sorting the menu wrote back through the settings provider.
  SortingOptions? storedSorting() => repository.settings.counterSorting;

  testWidgets('the button uses FaIcon, not Icon', (tester) async {
    // font_awesome_flutter 11 no longer renders through a plain Icon.
    await pumpApp(tester, const CountersPopupMenu(), repository: repository);

    expect(faIcon(FontAwesomeIcons.sliders), findsOneWidget);
  });

  testWidgets('lists the compact view toggle and every sort option', (
    tester,
  ) async {
    await openMenu(tester);

    expect(find.text(l10n(tester).compactView), findsOneWidget);
    expect(find.text(l10n(tester).sortBy), findsOneWidget);
    expect(find.text(l10n(tester).custom), findsOneWidget);
    expect(find.text(l10n(tester).alphabeticalOrder), findsOneWidget);
    expect(find.text(l10n(tester).counterCountOrder), findsOneWidget);
    expect(find.text(l10n(tester).creationDate), findsOneWidget);
  });

  group('no sorting in effect', () {
    testWidgets('shows no direction arrow at all', (tester) async {
      await openMenu(tester);

      expect(faIcon(FontAwesomeIcons.arrowUpZA), findsNothing);
      expect(faIcon(FontAwesomeIcons.arrowDownZA), findsNothing);
      expect(faIcon(FontAwesomeIcons.arrowUp91), findsNothing);
      expect(faIcon(FontAwesomeIcons.arrowDown19), findsNothing);
      expect(faIcon(FontAwesomeIcons.arrowUp), findsNothing);
      expect(faIcon(FontAwesomeIcons.arrowDown), findsNothing);
    });
  });

  group('picking a sort', () {
    testWidgets('alphabetical starts ascending', (tester) async {
      await openMenu(tester);
      await tester.tap(find.text(l10n(tester).alphabeticalOrder));
      await tester.pumpAndSettle();

      expect(storedSorting(), SortingOptions.alphabeticalAsc);
      expect(repository.calls, contains('updateSettings()'));
    });

    testWidgets('picking it again flips to descending', (tester) async {
      await openMenu(tester, sorting: SortingOptions.alphabeticalAsc);
      await tester.tap(
        find.text(l10n(tester).alphabeticalOrderWithSuffix('(A-Z)')),
      );
      await tester.pumpAndSettle();

      expect(storedSorting(), SortingOptions.alphabeticalDesc);
    });

    testWidgets('a third pick clears the sorting', (tester) async {
      await openMenu(tester, sorting: SortingOptions.alphabeticalDesc);
      await tester.tap(
        find.text(l10n(tester).alphabeticalOrderWithSuffix('(Z-A)')),
      );
      await tester.pumpAndSettle();

      expect(storedSorting(), isNull);
    });

    testWidgets('counter value cycles the same way', (tester) async {
      await openMenu(tester);
      await tester.tap(find.text(l10n(tester).counterCountOrder));
      await tester.pumpAndSettle();

      expect(storedSorting(), SortingOptions.valueAsc);
    });

    testWidgets('creation date cycles the same way', (tester) async {
      await openMenu(tester);
      await tester.tap(find.text(l10n(tester).creationDate));
      await tester.pumpAndSettle();

      expect(storedSorting(), SortingOptions.creationDateAsc);
    });

    testWidgets('custom toggles on and off rather than cycling', (
      tester,
    ) async {
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
      expect(
        find.text(l10n(tester).alphabeticalOrderWithSuffix('(A-Z)')),
        findsOneWidget,
      );
    });

    testWidgets('descending alphabetical shows the Z-A arrow', (tester) async {
      await openMenu(tester, sorting: SortingOptions.alphabeticalDesc);

      expect(faIcon(FontAwesomeIcons.arrowDownZA), findsOneWidget);
    });

    testWidgets('ascending value shows the 1-9 arrow', (tester) async {
      await openMenu(tester, sorting: SortingOptions.valueAsc);

      expect(faIcon(FontAwesomeIcons.arrowUp91), findsOneWidget);
      expect(
        find.text(l10n(tester).counterCountWithSuffix('(1-9)')),
        findsOneWidget,
      );
    });

    testWidgets('descending value shows the 9-1 arrow', (tester) async {
      await openMenu(tester, sorting: SortingOptions.valueDesc);

      expect(faIcon(FontAwesomeIcons.arrowDown19), findsOneWidget);
    });

    testWidgets('creation date shows a plain up or down arrow', (tester) async {
      await openMenu(tester, sorting: SortingOptions.creationDateAsc);
      expect(faIcon(FontAwesomeIcons.arrowUp), findsOneWidget);
    });
  });

  group('compact view', () {
    testWidgets('toggling it writes the new value', (tester) async {
      await openMenu(tester);
      await tester.tap(find.text(l10n(tester).compactView));
      await tester.pumpAndSettle();

      expect(repository.settings.counterCompactView, isTrue);
      expect(repository.calls, contains('updateSettings()'));
    });
  });
}
