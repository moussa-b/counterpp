import 'package:counter/models/counter.dart';
import 'package:counter/models/folder.dart';
import 'package:counter/widgets/folder_statistics_chart.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_counter_repository.dart';
import '../helpers/test_app.dart';

void main() {
  late FakeCounterRepository repository;
  late Folder folder;

  setUp(() {
    repository = FakeCounterRepository();
    folder = repository.seedFolder('Work');
  });

  Counter seed(String name, int count, {String color = '#ff0000'}) {
    return repository.seedCounter(
      name: name,
      folder: folder,
      count: count,
      color: color,
    );
  }

  Future<void> pumpChart(WidgetTester tester, List<Counter> counters) {
    return pumpApp(
      tester,
      SizedBox(height: 400, child: FolderStatisticsChart(counters: counters)),
      repository: repository,
    );
  }

  List<PieChartSectionData> sections(WidgetTester tester) {
    return tester.widget<PieChart>(find.byType(PieChart)).data.sections;
  }

  testWidgets('gives each counter that has a value its own slice', (
    tester,
  ) async {
    await pumpChart(tester, <Counter>[
      seed('Verses', 30, color: '#ff0000'),
      seed('Pages', 10, color: '#00ff00'),
    ]);

    expect(sections(tester).length, 2);
    expect(
      sections(tester).map((PieChartSectionData s) => s.title),
      containsAll(<String>['Verses', 'Pages']),
    );
  });

  testWidgets('sizes each slice by its share of the total', (tester) async {
    await pumpChart(tester, <Counter>[seed('Verses', 30), seed('Pages', 10)]);

    final Map<String?, double> byName = <String?, double>{
      for (final PieChartSectionData s in sections(tester)) s.title: s.value,
    };
    expect(byName['Verses'], 75);
    expect(byName['Pages'], 25);
  });

  testWidgets('leaves out counters still at zero', (tester) async {
    // A zero slice would be invisible but would still claim a legend entry.
    await pumpChart(tester, <Counter>[seed('Verses', 10), seed('Unused', 0)]);

    expect(sections(tester).length, 1);
    expect(sections(tester).single.title, 'Verses');
  });

  testWidgets('the legend names only the counters that are charted', (
    tester,
  ) async {
    await pumpChart(tester, <Counter>[seed('Verses', 10), seed('Unused', 0)]);

    expect(find.text('Verses'), findsWidgets);
    expect(find.text('Unused'), findsNothing);
  });

  testWidgets('a single counter takes the whole circle', (tester) async {
    await pumpChart(tester, <Counter>[seed('Verses', 7)]);

    expect(sections(tester).single.value, 100);
  });

  testWidgets('fl_chart 1.2 renders the pie without the Matrix4 crash', (
    tester,
  ) async {
    await pumpChart(tester, <Counter>[
      seed('A', 5, color: '#ff0000'),
      seed('B', 5, color: '#00ff00'),
      seed('C', 5, color: '#0000ff'),
    ]);

    expect(tester.takeException(), isNull);
    expect(find.byType(PieChart), findsOneWidget);
  });
}
