import 'package:counter/models/calendar_period.dart';
import 'package:counter/models/statistics.dart';
import 'package:counter/widgets/counter_statistics_chart.dart';
import 'package:fl_chart/fl_chart.dart';
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

  Future<void> pumpChart(
    WidgetTester tester,
    List<Statistics> statistics, {
    CalendarPeriod period = CalendarPeriod.day,
  }) {
    return pumpApp(
      tester,
      SizedBox(
        height: 300,
        child: CounterStatisticsChart(
          statistics: statistics,
          calendarPeriod: period,
          selectedDate: day,
        ),
      ),
      repository: repository,
    );
  }

  BarChartData chartData(WidgetTester tester) {
    return tester.widget<BarChart>(find.byType(BarChart)).data;
  }

  /// The bars that actually carry a value.
  ///
  /// The chart always lays out the whole period, so a day is twelve two-hour
  /// slots whether anything happened in them or not. That is what keeps the
  /// axis readable; only the filled bars say where the activity was.
  List<BarChartGroupData> filledBars(WidgetTester tester) {
    return chartData(tester).barGroups
        .where(
          (BarChartGroupData group) =>
              group.barRods.any((BarChartRodData rod) => rod.toY > 0),
        )
        .toList();
  }

  testWidgets('says so when there is nothing to chart', (tester) async {
    await pumpChart(tester, <Statistics>[]);

    expect(find.text(l10n(tester).noStatistics), findsOneWidget);
    expect(find.byType(BarChart), findsNothing);
  });

  testWidgets('renders a bar chart once there is something to show', (
    tester,
  ) async {
    await pumpChart(tester, <Statistics>[stat(StatisticsType.INCREMENT)]);

    expect(find.byType(BarChart), findsOneWidget);
    expect(filledBars(tester), isNotEmpty);
  });

  testWidgets('groups events that fall in the same slot into one bar', (
    tester,
  ) async {
    await pumpChart(tester, <Statistics>[
      stat(StatisticsType.INCREMENT),
      stat(StatisticsType.INCREMENT),
      stat(StatisticsType.INCREMENT),
    ]);

    expect(filledBars(tester).length, 1);
    expect(filledBars(tester).single.barRods.first.toY, 3);
  });

  testWidgets('gives events in different slots their own bar', (tester) async {
    await pumpChart(tester, <Statistics>[
      stat(StatisticsType.INCREMENT, hour: 8),
      stat(StatisticsType.INCREMENT, hour: 16),
    ]);

    expect(filledBars(tester).length, 2);
  });

  testWidgets('shows the bottom axis so a bar can be read', (tester) async {
    await pumpChart(tester, <Statistics>[stat(StatisticsType.INCREMENT)]);

    expect(
      chartData(tester).titlesData.bottomTitles.sideTitles.showTitles,
      isTrue,
    );
    expect(
      chartData(tester).titlesData.topTitles.sideTitles.showTitles,
      isFalse,
    );
  });

  testWidgets('fl_chart 1.2 renders without the Matrix4 crash', (tester) async {
    // fl_chart was pinned to 1.0.0 for months because 1.1+ called
    // Matrix4.translateByDouble, which the old Flutter's vector_math lacked.
    // Pumping a real chart is what proves the pin can stay lifted.
    await pumpChart(tester, <Statistics>[
      stat(StatisticsType.INCREMENT, hour: 8),
      stat(StatisticsType.DECREMENT, hour: 10),
      stat(StatisticsType.RESET, hour: 12),
    ], period: CalendarPeriod.week);

    expect(tester.takeException(), isNull);
    expect(find.byType(BarChart), findsOneWidget);
  });
}
