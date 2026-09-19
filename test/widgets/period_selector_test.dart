import 'package:counter/models/calendar_period.dart';
import 'package:counter/widgets/period_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

void main() {
  late List<CalendarPeriod> changes;

  setUp(() => changes = <CalendarPeriod>[]);

  Future<void> pumpSelector(WidgetTester tester) {
    return pumpApp(
      tester,
      PeriodSelector(
        onPeriodChange: (CalendarPeriod period) => changes.add(period),
      ),
    );
  }

  testWidgets('offers all four periods', (tester) async {
    await pumpSelector(tester);

    expect(find.text(l10n(tester).day), findsOneWidget);
    expect(find.text(l10n(tester).week), findsOneWidget);
    expect(find.text(l10n(tester).month), findsOneWidget);
    expect(find.text(l10n(tester).year), findsOneWidget);
  });

  testWidgets('starts on the day, and says so without being asked', (
    tester,
  ) async {
    await pumpSelector(tester);

    final SegmentedButton<CalendarPeriod> button = tester
        .widget<SegmentedButton<CalendarPeriod>>(
          find.byType(SegmentedButton<CalendarPeriod>),
        );
    expect(button.selected, <CalendarPeriod>{CalendarPeriod.day});
    expect(changes, isEmpty, reason: 'the initial value is not a change');
  });

  testWidgets('picking a period reports it once', (tester) async {
    await pumpSelector(tester);
    await tester.tap(find.text(l10n(tester).month));
    await tester.pumpAndSettle();

    expect(changes, <CalendarPeriod>[CalendarPeriod.month]);
  });

  testWidgets('the selection follows what was picked', (tester) async {
    await pumpSelector(tester);
    await tester.tap(find.text(l10n(tester).year));
    await tester.pumpAndSettle();

    final SegmentedButton<CalendarPeriod> button = tester
        .widget<SegmentedButton<CalendarPeriod>>(
          find.byType(SegmentedButton<CalendarPeriod>),
        );
    expect(button.selected, <CalendarPeriod>{CalendarPeriod.year});
  });

  testWidgets('moving through several periods reports each one', (
    tester,
  ) async {
    await pumpSelector(tester);
    for (final String label in <String>[
      l10n(tester).week,
      l10n(tester).month,
      l10n(tester).day,
    ]) {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
    }

    expect(changes, <CalendarPeriod>[
      CalendarPeriod.week,
      CalendarPeriod.month,
      CalendarPeriod.day,
    ]);
  });

  testWidgets('works without a listener', (tester) async {
    await pumpApp(tester, const PeriodSelector());
    await tester.tap(find.text(l10n(tester).week));
    await tester.pumpAndSettle();

    final SegmentedButton<CalendarPeriod> button = tester
        .widget<SegmentedButton<CalendarPeriod>>(
          find.byType(SegmentedButton<CalendarPeriod>),
        );
    expect(button.selected, <CalendarPeriod>{CalendarPeriod.week});
  });
}
