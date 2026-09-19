import 'package:counter/models/counter.dart';
import 'package:counter/models/folder.dart';
import 'package:counter/models/settings.dart';
import 'package:counter/screens/counter_screen.dart';
import 'package:counter/widgets/counter_bottom_sheet.dart';
import 'package:counter/widgets/counter_list_item.dart';
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
    // Tapping a row pushes CounterScreen, which waits on the wakelock plugin.
    installFakeWakelock();
  });

  Counter seed({
    String name = 'Verses',
    int count = 0,
    int? limit,
    int step = 1,
  }) {
    return repository.seedCounter(
      name: name,
      folder: folder,
      count: count,
      limit: limit,
      step: step,
    );
  }

  /// font_awesome_flutter 11 stopped making FaIconData an IconData, so an icon
  /// is matched through its `.data` and the widget has to be a FaIcon rather
  /// than an Icon. A plain `find.byIcon` would miss every one of these.
  Finder faIcon(FaIconData icon) {
    return find.byWidgetPredicate(
      (Widget widget) => widget is FaIcon && widget.icon == icon.data,
    );
  }

  IconButton buttonFor(WidgetTester tester, FaIconData icon) {
    return tester.widget<IconButton>(
      find.ancestor(of: faIcon(icon), matching: find.byType(IconButton)),
    );
  }

  testWidgets('shows the counter name and its current value', (tester) async {
    final Counter counter = seed(name: 'Verses', count: 7);

    await pumpApp(
      tester,
      CounterListItem(counter: counter),
      repository: repository,
    );

    expect(find.text('Verses'), findsOneWidget);
    expect(find.text('7'), findsWidgets);
  });

  testWidgets('a counter without a limit shows the infinity icon', (
    tester,
  ) async {
    await pumpApp(
      tester,
      CounterListItem(counter: seed()),
      repository: repository,
    );

    expect(faIcon(FontAwesomeIcons.infinity), findsOneWidget);
  });

  testWidgets('a counter with a limit shows its value instead of infinity', (
    tester,
  ) async {
    await pumpApp(
      tester,
      CounterListItem(counter: seed(count: 3, limit: 10)),
      repository: repository,
    );

    expect(faIcon(FontAwesomeIcons.infinity), findsNothing);
    expect(find.text('3'), findsWidgets);
  });

  group('incrementing', () {
    testWidgets('the plus button raises the value and writes it through', (
      tester,
    ) async {
      final Counter counter = seed(count: 0);

      await pumpApp(
        tester,
        CounterListItem(counter: counter),
        repository: repository,
      );
      await tester.tap(faIcon(FontAwesomeIcons.plus));
      await tester.pumpAndSettle();

      expect(find.text('1'), findsWidgets);
      expect(repository.calls, contains('incrementCounterById(${counter.id})'));
      expect(repository.counters[counter.id]!.counterCount, 1);
    });

    testWidgets('a step of more than one moves by that step', (tester) async {
      await pumpApp(
        tester,
        CounterListItem(counter: seed(count: 0, step: 5)),
        repository: repository,
      );
      await tester.tap(faIcon(FontAwesomeIcons.plus));
      await tester.pumpAndSettle();

      expect(find.text('5'), findsWidgets);
    });
  });

  group('decrementing', () {
    testWidgets('the minus button lowers the value and writes it through', (
      tester,
    ) async {
      final Counter counter = seed(count: 4);

      await pumpApp(
        tester,
        CounterListItem(counter: counter),
        repository: repository,
      );
      await tester.tap(faIcon(FontAwesomeIcons.minus));
      await tester.pumpAndSettle();

      expect(find.text('3'), findsWidgets);
      expect(repository.calls, contains('decrementCounterById(${counter.id})'));
      expect(repository.counters[counter.id]!.counterCount, 3);
    });

    testWidgets('the minus button is disabled at zero, so it cannot go below', (
      tester,
    ) async {
      await pumpApp(
        tester,
        CounterListItem(counter: seed(count: 0)),
        repository: repository,
      );

      expect(buttonFor(tester, FontAwesomeIcons.minus).onPressed, isNull);
    });
  });

  group('inactive mode', () {
    // The editable (reorderable) lists render their items with active: false so
    // a drag is never mistaken for a tap on a button.
    testWidgets('disables both buttons', (tester) async {
      await pumpApp(
        tester,
        CounterListItem(counter: seed(count: 4), active: false),
        repository: repository,
      );

      expect(buttonFor(tester, FontAwesomeIcons.plus).onPressed, isNull);
      expect(buttonFor(tester, FontAwesomeIcons.minus).onPressed, isNull);
    });

    testWidgets('does not open the counter when tapped', (tester) async {
      await pumpApp(
        tester,
        CounterListItem(counter: seed(), active: false),
        repository: repository,
      );
      await tester.tap(find.text('Verses'));
      await tester.pumpAndSettle();

      expect(find.byType(CounterScreen), findsNothing);
    });
  });

  testWidgets('tapping the row opens the counter screen', (tester) async {
    await pumpApp(
      tester,
      CounterListItem(counter: seed()),
      repository: repository,
    );
    await tester.tap(find.text('Verses'));
    await tester.pumpAndSettle();

    expect(find.byType(CounterScreen), findsOneWidget);
  });

  testWidgets('the overflow button opens the counter bottom sheet', (
    tester,
  ) async {
    await pumpApp(
      tester,
      CounterListItem(counter: seed()),
      repository: repository,
    );
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    expect(find.byType(CounterBottomSheet), findsOneWidget);
  });

  testWidgets('no audio plugin is needed while sounds are off', (tester) async {
    // AudioPlayer is only constructed when activateSounds is on, which is what
    // keeps these tests free of the audioplayers plugin. This pins that down.
    final Settings settings = repository.settings;
    expect(settings.activateSounds, isNull);

    await pumpApp(
      tester,
      CounterListItem(counter: seed(count: 0), settings: settings),
      repository: repository,
    );
    await tester.tap(faIcon(FontAwesomeIcons.plus));
    await tester.pumpAndSettle();

    expect(find.text('1'), findsWidgets);
  });
}
