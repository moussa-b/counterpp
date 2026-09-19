import 'package:counter/models/counter.dart';
import 'package:counter/models/folder.dart';
import 'package:counter/screens/counter_screen.dart';
import 'package:counter/widgets/counter_progress.dart';
import 'package:counter/widgets/counter_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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

  Counter seed({String name = 'Verses', int count = 0}) {
    return repository.seedCounter(name: name, folder: folder, count: count);
  }

  Future<void> pumpScreen(WidgetTester tester, Counter counter) {
    return pumpApp(
      tester,
      CounterScreen(counter: counter),
      repository: repository,
      wrapInScaffold: false,
    );
  }

  testWidgets('titles itself with the counter name', (tester) async {
    await pumpScreen(tester, seed(name: 'Verses'));

    expect(find.text('Verses'), findsOneWidget);
  });

  testWidgets('shows the counter full screen', (tester) async {
    await pumpScreen(tester, seed(count: 7));

    expect(find.byType(CounterWidget), findsOneWidget);
    expect(find.byType(CounterProgress), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
  });

  testWidgets('counting up from here writes through', (tester) async {
    final Counter counter = seed(count: 0);

    await pumpScreen(tester, counter);
    await tester.tap(find.byType(CounterProgress));
    await tester.pumpAndSettle();

    expect(find.text('1'), findsOneWidget);
    expect(repository.calls, contains('incrementCounterById(${counter.id})'));
  });

  group('the reset button', () {
    testWidgets('zeroes the counter', (tester) async {
      final Counter counter = seed(count: 9);

      await pumpScreen(tester, counter);
      await tester.tap(find.byIcon(Icons.settings_backup_restore));
      await tester.pumpAndSettle();

      expect(repository.calls, contains('resetCounterById(${counter.id})'));
      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('is there even on a counter already at zero', (tester) async {
      await pumpScreen(tester, seed(count: 0));

      expect(find.byIcon(Icons.settings_backup_restore), findsOneWidget);
    });
  });
}
