import 'package:counter/models/counter.dart';
import 'package:counter/models/folder.dart';
import 'package:counter/widgets/counter_bottom_sheet.dart';
import 'package:counter/widgets/counter_grid_item.dart';
import 'package:flutter/material.dart';
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

  Counter seed({int count = 0, int? limit, int step = 1}) {
    return repository.seedCounter(
      name: 'Verses',
      folder: folder,
      count: count,
      limit: limit,
      step: step,
    );
  }

  Finder overflowButton() {
    return find.byWidgetPredicate(
      (Widget widget) =>
          widget is FaIcon &&
          widget.icon == FontAwesomeIcons.ellipsisVertical.data,
    );
  }

  testWidgets('shows the counter name and its value', (tester) async {
    await pumpApp(
      tester,
      CounterGridItem(counter: seed(count: 9)),
      repository: repository,
    );

    expect(find.text('Verses'), findsOneWidget);
    expect(find.text('9'), findsOneWidget);
  });

  testWidgets('a counter with a limit shows it next to the value', (
    tester,
  ) async {
    await pumpApp(
      tester,
      CounterGridItem(counter: seed(count: 3, limit: 10)),
      repository: repository,
    );

    expect(find.text('3'), findsOneWidget);
    expect(find.text('/10'), findsOneWidget);
  });

  testWidgets('a counter without a limit shows no denominator', (tester) async {
    await pumpApp(
      tester,
      CounterGridItem(counter: seed(count: 3)),
      repository: repository,
    );

    expect(find.textContaining('/'), findsNothing);
  });

  group('tapping the tile', () {
    // Unlike the list row, the whole grid tile is the increment button: there
    // is no room for a plus and a minus.
    testWidgets('increments and writes it through', (tester) async {
      final Counter counter = seed(count: 0);

      await pumpApp(
        tester,
        CounterGridItem(counter: counter),
        repository: repository,
      );
      await tester.tap(find.text('Verses'));
      await tester.pumpAndSettle();

      expect(find.text('1'), findsOneWidget);
      expect(repository.calls, contains('incrementCounterById(${counter.id})'));
    });

    testWidgets('moves by the counter step', (tester) async {
      await pumpApp(
        tester,
        CounterGridItem(counter: seed(count: 0, step: 5)),
        repository: repository,
      );
      await tester.tap(find.text('Verses'));
      await tester.pumpAndSettle();

      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('does nothing while inactive', (tester) async {
      final Counter counter = seed(count: 0);

      await pumpApp(
        tester,
        CounterGridItem(counter: counter, active: false),
        repository: repository,
      );
      await tester.tap(find.text('Verses'));
      await tester.pumpAndSettle();

      expect(find.text('0'), findsOneWidget);
      expect(repository.calls, isEmpty);
    });
  });

  group('the overflow button', () {
    testWidgets('opens the counter bottom sheet', (tester) async {
      await pumpApp(
        tester,
        CounterGridItem(counter: seed()),
        repository: repository,
      );
      await tester.tap(overflowButton());
      await tester.pumpAndSettle();

      expect(find.byType(CounterBottomSheet), findsOneWidget);
    });

    testWidgets('stays shut while inactive', (tester) async {
      await pumpApp(
        tester,
        CounterGridItem(counter: seed(), active: false),
        repository: repository,
      );
      await tester.tap(overflowButton());
      await tester.pumpAndSettle();

      expect(find.byType(CounterBottomSheet), findsNothing);
    });

    testWidgets('uses FaIcon, not Icon', (tester) async {
      await pumpApp(
        tester,
        CounterGridItem(counter: seed()),
        repository: repository,
      );

      expect(overflowButton(), findsOneWidget);
    });
  });

  testWidgets('a reset from the sheet zeroes the displayed value', (
    tester,
  ) async {
    final Counter counter = seed(count: 7);

    await pumpApp(
      tester,
      CounterGridItem(counter: counter),
      repository: repository,
    );
    await tester.tap(overflowButton());
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n(tester).reset));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n(tester).validate));
    await tester.pumpAndSettle();

    expect(find.text('0'), findsOneWidget);
  });
}
