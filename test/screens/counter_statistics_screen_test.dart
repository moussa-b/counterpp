import 'package:counter/models/counter.dart';
import 'package:counter/models/folder.dart';
import 'package:counter/models/statistics.dart';
import 'package:counter/screens/counter_statistics_screen.dart';
import 'package:counter/widgets/counter_statistics_chart.dart';
import 'package:counter/widgets/counter_statistics_data_table.dart';
import 'package:counter/widgets/period_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import '../helpers/fake_counter_repository.dart';
import '../helpers/test_app.dart';

void main() {
  late FakeCounterRepository repository;
  late Folder folder;
  late Counter counter;

  final DateTime today = DateTime.now();

  setUp(() {
    repository = FakeCounterRepository();
    folder = repository.seedFolder('Work');
    counter = repository.seedCounter(name: 'Verses', folder: folder);
  });

  void seedStat({DateTime? on}) {
    final DateTime when = on ?? today;
    repository.statistics.add(
      Statistics(
        counterId: counter.id,
        type: StatisticsType.INCREMENT,
        value: 1,
        dateTimeStamp: DateTime(
          when.year,
          when.month,
          when.day,
          9,
        ).millisecondsSinceEpoch,
      ),
    );
  }

  Future<void> pumpScreen(WidgetTester tester) {
    return pumpApp(
      tester,
      CounterStatisticsScreen(counter: counter),
      repository: repository,
      wrapInScaffold: false,
    );
  }

  testWidgets('titles itself with the counter it is charting', (tester) async {
    await pumpScreen(tester);

    expect(find.text(l10n(tester).counterStatistics('Verses')), findsOneWidget);
  });

  testWidgets('says so when the counter has no history', (tester) async {
    await pumpScreen(tester);

    expect(find.text(l10n(tester).noStatistics), findsOneWidget);
    expect(find.byType(CounterStatisticsChart), findsNothing);
  });

  testWidgets('shows the chart and the table once there is history', (
    tester,
  ) async {
    seedStat();

    await pumpScreen(tester);

    expect(find.byType(CounterStatisticsChart), findsOneWidget);
    expect(find.byType(CounterStatisticsDataTable), findsOneWidget);
  });

  testWidgets('opens on the day, showing its date', (tester) async {
    seedStat();

    await pumpScreen(tester);

    expect(find.byType(PeriodSelector), findsOneWidget);
    expect(
      find.text(DateFormat('dd MMMM yyyy', 'en').format(today)),
      findsOneWidget,
    );
  });

  group('moving through time', () {
    testWidgets('the left chevron steps back a day', (tester) async {
      seedStat();

      await pumpScreen(tester);
      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();

      final DateTime yesterday = today.subtract(const Duration(days: 1));
      expect(
        find.text(DateFormat('dd MMMM yyyy', 'en').format(yesterday)),
        findsOneWidget,
      );
    });

    testWidgets('and the right chevron steps forward again', (tester) async {
      seedStat();

      await pumpScreen(tester);
      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();

      expect(
        find.text(DateFormat('dd MMMM yyyy', 'en').format(today)),
        findsOneWidget,
      );
    });

    testWidgets('a day with no history says so', (tester) async {
      seedStat();

      await pumpScreen(tester);
      expect(find.byType(CounterStatisticsChart), findsOneWidget);

      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();

      expect(find.text(l10n(tester).noStatistics), findsOneWidget);
    });
  });

  testWidgets('switching period widens the range shown', (tester) async {
    seedStat();

    await pumpScreen(tester);
    await tester.tap(find.text(l10n(tester).week));
    await tester.pumpAndSettle();

    // A week reads as a span, not a single date.
    expect(find.textContaining(' - '), findsOneWidget);
  });
}
