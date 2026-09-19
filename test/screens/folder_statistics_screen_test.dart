import 'package:counter/models/folder.dart';
import 'package:counter/providers/counters_provider.dart';
import 'package:counter/screens/folder_statistics_screen.dart';
import 'package:counter/widgets/folder_statistics_chart.dart';
import 'package:counter/widgets/folder_statistics_data_table.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  Future<void> pumpScreen(WidgetTester tester) async {
    await pumpApp(
      tester,
      FolderStatisticsScreen(folder: folder),
      repository: repository,
      wrapInScaffold: false,
    );
    await tester
        .container()
        .read(countersProvider.notifier)
        .setFolderId(folder.id!);
    await tester.pumpAndSettle();
  }

  testWidgets('titles itself with the folder it is charting', (tester) async {
    repository.seedCounter(name: 'Verses', folder: folder, count: 5);

    await pumpScreen(tester);

    expect(find.text(l10n(tester).folderStatistics('Work')), findsOneWidget);
  });

  testWidgets('an empty folder says there is nothing to chart', (tester) async {
    await pumpScreen(tester);

    expect(find.text(l10n(tester).noCounter), findsOneWidget);
    expect(find.byType(FolderStatisticsChart), findsNothing);
  });

  testWidgets('shows the pie and the table side by side', (tester) async {
    repository.seedCounter(name: 'Verses', folder: folder, count: 30);
    repository.seedCounter(name: 'Pages', folder: folder, count: 10);

    await pumpScreen(tester);

    expect(find.byType(FolderStatisticsChart), findsOneWidget);
    expect(find.byType(FolderStatisticsDataTable), findsOneWidget);
  });

  testWidgets('the table lists every counter, charted or not', (tester) async {
    // A counter still at zero has no slice but is still part of the folder, so
    // it belongs in the table.
    repository.seedCounter(name: 'Verses', folder: folder, count: 30);
    repository.seedCounter(name: 'Unused', folder: folder);

    await pumpScreen(tester);

    expect(find.text('Unused'), findsOneWidget);
  });

  testWidgets('it does not crash while the counters are still loading', (
    tester,
  ) async {
    // The loading branch here was missing its `else` too.
    repository.seedCounter(name: 'Verses', folder: folder, count: 5);

    await pumpApp(
      tester,
      FolderStatisticsScreen(folder: folder),
      repository: repository,
      wrapInScaffold: false,
    );

    expect(tester.takeException(), isNull);
  });
}
