import 'package:counter/models/bottom_sheet_result.dart';
import 'package:counter/models/counter.dart';
import 'package:counter/models/folder.dart';
import 'package:counter/screens/counter_form_screen.dart';
import 'package:counter/screens/counter_screen.dart';
import 'package:counter/screens/counter_statistics_screen.dart';
import 'package:counter/widgets/counter_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../helpers/fake_counter_repository.dart';
import '../helpers/fake_wakelock.dart';
import '../helpers/test_app.dart';

void main() {
  late FakeCounterRepository repository;
  late Counter counter;

  setUp(() {
    repository = FakeCounterRepository();
    final Folder folder = repository.seedFolder('Work');
    counter = repository.seedCounter(name: 'Verses', folder: folder, count: 12);
    // The full-screen entry pushes CounterScreen, which waits on the wakelock.
    installFakeWakelock();
  });

  Future<BottomSheetResultHolder<BottomSheetAction?>> open(
    WidgetTester tester,
  ) {
    return openBottomSheet<BottomSheetAction?>(
      tester,
      CounterBottomSheet(counter: counter),
      repository: repository,
    );
  }

  /// Confirms the warning dialog a destructive entry puts up.
  Future<void> confirm(WidgetTester tester) async {
    await tester.tap(find.text(l10n(tester).validate));
    await tester.pumpAndSettle();
  }

  testWidgets('heads the sheet with the counter name and its value', (
    tester,
  ) async {
    await open(tester);

    expect(find.text('Verses'), findsOneWidget);
    expect(find.text('${l10n(tester).value} : 12'), findsOneWidget);
  });

  testWidgets('offers every action', (tester) async {
    await open(tester);

    expect(find.text(l10n(tester).fullScreen), findsOneWidget);
    expect(find.text(l10n(tester).editCounter), findsOneWidget);
    expect(find.text(l10n(tester).duplicate), findsOneWidget);
    expect(find.text(l10n(tester).reset), findsOneWidget);
    expect(find.text(l10n(tester).delete), findsOneWidget);
    expect(find.text(l10n(tester).statistics), findsOneWidget);
  });

  testWidgets('the close button dismisses it without doing anything', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.text(l10n(tester).close));
    await tester.pumpAndSettle();

    expect(find.byType(CounterBottomSheet), findsNothing);
    expect(repository.calls, isEmpty);
  });

  group('navigation entries', () {
    testWidgets('full screen opens the counter', (tester) async {
      await open(tester);
      await tester.tap(find.text(l10n(tester).fullScreen));
      await tester.pumpAndSettle();

      expect(find.byType(CounterScreen), findsOneWidget);
    });

    testWidgets('edit opens the form on this counter', (tester) async {
      await open(tester);
      await tester.tap(find.text(l10n(tester).editCounter));
      await tester.pumpAndSettle();

      expect(find.byType(CounterFormScreen), findsOneWidget);
    });

    testWidgets('statistics opens the chart', (tester) async {
      await open(tester);
      await tester.tap(find.text(l10n(tester).statistics));
      await tester.pumpAndSettle();

      expect(find.byType(CounterStatisticsScreen), findsOneWidget);
    });
  });

  testWidgets('duplicate copies the counter with a suffix', (tester) async {
    await open(tester);
    await tester.tap(find.text(l10n(tester).duplicate));
    await tester.pumpAndSettle();

    expect(
      repository.counters.values.map((Counter counter) => counter.name),
      contains('Verses - ${l10n(tester).copy}'),
    );
  });

  group('reset', () {
    testWidgets('warns before zeroing the counter', (tester) async {
      await open(tester);
      await tester.tap(find.text(l10n(tester).reset));
      await tester.pumpAndSettle();

      expect(find.text(l10n(tester).warning), findsOneWidget);
      expect(find.text(l10n(tester).warningMsgResetCounter), findsOneWidget);
      expect(repository.counters[counter.id]!.counterCount, 12);
    });

    testWidgets('cancelling leaves the value alone', (tester) async {
      await open(tester);
      await tester.tap(find.text(l10n(tester).reset));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n(tester).cancel));
      await tester.pumpAndSettle();

      expect(repository.counters[counter.id]!.counterCount, 12);
    });

    testWidgets('confirming zeroes it and tells the row to redraw', (
      tester,
    ) async {
      final BottomSheetResultHolder<BottomSheetAction?> sheet = await open(
        tester,
      );
      await tester.tap(find.text(l10n(tester).reset));
      await tester.pumpAndSettle();
      await confirm(tester);

      expect(repository.calls, contains('resetCounterById(${counter.id})'));
      expect(repository.counters[counter.id]!.counterCount, 0);
      expect(
        sheet.value,
        BottomSheetAction.reset,
        reason: 'the row resets its own displayed count on this result',
      );
    });
  });

  group('delete', () {
    testWidgets('warns before deleting', (tester) async {
      await open(tester);
      await tester.tap(find.text(l10n(tester).delete));
      await tester.pumpAndSettle();

      expect(find.text(l10n(tester).warning), findsOneWidget);
      expect(find.text(l10n(tester).warningMsgDeleteCounter), findsOneWidget);
      expect(repository.counters, contains(counter.id));
    });

    testWidgets('cancelling keeps the counter', (tester) async {
      await open(tester);
      await tester.tap(find.text(l10n(tester).delete));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n(tester).cancel));
      await tester.pumpAndSettle();

      expect(repository.counters, contains(counter.id));
    });

    testWidgets('confirming deletes it', (tester) async {
      await open(tester);
      await tester.tap(find.text(l10n(tester).delete));
      await tester.pumpAndSettle();
      await confirm(tester);

      expect(repository.calls, contains('deleteCounterById(${counter.id})'));
      expect(repository.counters, isNot(contains(counter.id)));
    });
  });

  testWidgets('the full-screen entry uses FaIcon, not Icon', (tester) async {
    // font_awesome_flutter 11 renders nothing useful through a plain Icon, so
    // this catches a regression to the pre-migration form.
    await open(tester);

    expect(
      find.byWidgetPredicate(
        (Widget widget) =>
            widget is FaIcon && widget.icon == FontAwesomeIcons.maximize.data,
      ),
      findsOneWidget,
    );
  });
}
