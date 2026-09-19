import 'package:counter/models/calendar_period.dart';
import 'package:counter/models/statistics.dart';
import 'package:counter/widgets/counter_statistics_data_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_counter_repository.dart';
import '../helpers/test_app.dart';

void main() {
  late FakeCounterRepository repository;

  final DateTime day = DateTime(2026, 3, 14);

  setUp(() {
    repository = FakeCounterRepository();
  });

  Statistics stat(StatisticsType type, {int hour = 9}) {
    return Statistics(
      counterId: 1,
      type: type,
      value: 1,
      dateTimeStamp: DateTime(
        day.year,
        day.month,
        day.day,
        hour,
      ).millisecondsSinceEpoch,
    );
  }

  Future<void> pumpTable(
    WidgetTester tester,
    List<Statistics> statistics, {
    CalendarPeriod period = CalendarPeriod.day,
  }) {
    return pumpApp(
      tester,
      SingleChildScrollView(
        child: CounterStatisticsDataTable(
          statistics: statistics,
          calendarPeriod: period,
          selectedDate: day,
        ),
      ),
      repository: repository,
    );
  }

  testWidgets('says so when there is nothing to show', (tester) async {
    await pumpTable(tester, <Statistics>[]);

    expect(find.text(l10n(tester).noStatistics), findsOneWidget);
    expect(find.byType(DataTable), findsNothing);
  });

  testWidgets('heads the columns with date, type and value', (tester) async {
    await pumpTable(tester, <Statistics>[stat(StatisticsType.INCREMENT)]);

    expect(find.text(l10n(tester).date), findsOneWidget);
    expect(find.text(l10n(tester).type), findsOneWidget);
    expect(find.text(l10n(tester).value), findsOneWidget);
  });

  testWidgets('counts how many times each kind of change happened', (
    tester,
  ) async {
    // Three increments in the same slot collapse into one row reading 3,
    // rather than three rows reading 1.
    await pumpTable(tester, <Statistics>[
      stat(StatisticsType.INCREMENT),
      stat(StatisticsType.INCREMENT),
      stat(StatisticsType.INCREMENT),
    ]);

    final DataTable table = tester.widget<DataTable>(find.byType(DataTable));
    expect(table.rows.length, 1);
    expect(find.text(l10n(tester).increment), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('gives each kind of change its own row', (tester) async {
    await pumpTable(tester, <Statistics>[
      stat(StatisticsType.INCREMENT),
      stat(StatisticsType.DECREMENT),
      stat(StatisticsType.RESET),
    ]);

    final DataTable table = tester.widget<DataTable>(find.byType(DataTable));
    expect(table.rows.length, 3);
    expect(find.text(l10n(tester).increment), findsOneWidget);
    expect(find.text(l10n(tester).decrement), findsOneWidget);
    expect(find.text(l10n(tester).resetName), findsOneWidget);
  });

  testWidgets('splits the day into slots rather than one row per event', (
    tester,
  ) async {
    await pumpTable(tester, <Statistics>[
      stat(StatisticsType.INCREMENT, hour: 8),
      stat(StatisticsType.INCREMENT, hour: 14),
    ]);

    final DataTable table = tester.widget<DataTable>(find.byType(DataTable));
    expect(table.rows.length, 2);
  });

  testWidgets('a longer period groups the same events more coarsely', (
    tester,
  ) async {
    // Two events hours apart are separate rows over a day and one row over a
    // month, which is what makes the longer views readable.
    await pumpTable(tester, <Statistics>[
      stat(StatisticsType.INCREMENT, hour: 8),
      stat(StatisticsType.INCREMENT, hour: 14),
    ], period: CalendarPeriod.month);

    final DataTable table = tester.widget<DataTable>(find.byType(DataTable));
    expect(table.rows.length, 1);
    expect(find.text('2'), findsOneWidget);
  });
}
