import 'package:counter/models/counter.dart';
import 'package:counter/models/folder.dart';
import 'package:counter/widgets/folder_statistics_data_table.dart';
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

  Future<void> pumpTable(WidgetTester tester, List<Counter> counters) {
    return pumpApp(
      tester,
      SingleChildScrollView(
        child: FolderStatisticsDataTable(counters: counters),
      ),
      repository: repository,
    );
  }

  testWidgets('heads the columns with the name and the value', (tester) async {
    await pumpTable(tester, <Counter>[]);

    expect(find.text(l10n(tester).counterName), findsOneWidget);
    expect(find.text(l10n(tester).value), findsOneWidget);
  });

  testWidgets('shows one row per counter with its value', (tester) async {
    final List<Counter> counters = <Counter>[
      repository.seedCounter(name: 'Verses', folder: folder, count: 12),
      repository.seedCounter(name: 'Pages', folder: folder, count: 3),
    ];

    await pumpTable(tester, counters);

    expect(find.byType(DataRow), findsNothing); // DataRow is not a widget
    expect(find.text('Verses'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('Pages'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('keeps the order it was given', (tester) async {
    final List<Counter> counters = <Counter>[
      repository.seedCounter(name: 'Zebra', folder: folder, count: 1),
      repository.seedCounter(name: 'Alpha', folder: folder, count: 2),
    ];

    await pumpTable(tester, counters);

    final DataTable table = tester.widget<DataTable>(find.byType(DataTable));
    expect(table.rows.length, 2);
    expect((table.rows.first.cells.first.child as Text).data, 'Zebra');
  });

  testWidgets('an empty folder renders the header and nothing else', (
    tester,
  ) async {
    await pumpTable(tester, <Counter>[]);

    final DataTable table = tester.widget<DataTable>(find.byType(DataTable));
    expect(table.rows, isEmpty);
  });

  testWidgets('a counter at zero still gets a row', (tester) async {
    await pumpTable(tester, <Counter>[
      repository.seedCounter(name: 'Unused', folder: folder),
    ]);

    expect(find.text('Unused'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
  });
}
