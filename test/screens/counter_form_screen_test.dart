import 'package:counter/models/counter.dart';
import 'package:counter/models/folder.dart';
import 'package:counter/providers/counters_provider.dart';
import 'package:counter/screens/counter_form_screen.dart';
import 'package:flutter/material.dart';
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

  Future<void> pumpForm(
    WidgetTester tester, {
    int? counterId,
    Folder? currentFolder,
  }) async {
    await pumpApp(
      tester,
      CounterFormScreen(
        counterId: counterId,
        currentFolder: currentFolder ?? folder,
      ),
      repository: repository,
      wrapInScaffold: false,
      // The form is taller than a phone and its colour picker is a scrollable
      // of its own, which swallows a drag aimed at the form. A tall surface
      // puts every field and both buttons on screen at once, so these tests
      // exercise the form rather than the scrolling. That the form scrolls on
      // a real phone is a separate concern, and it does.
      surfaceSize: const Size(390, 1600),
    );
    await tester
        .container()
        .read(countersProvider.notifier)
        .setFolderId(folder.id!);
    await tester.pumpAndSettle();
  }

  /// The form field carrying [label].
  Finder fieldWithLabel(String label) {
    return find.ancestor(
      of: find.text(label),
      matching: find.byType(TextFormField),
    );
  }

  Future<void> tapButton(WidgetTester tester, String label) async {
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  Future<void> save(WidgetTester tester) =>
      tapButton(tester, l10n(tester).validate);

  group('creating a counter', () {
    testWidgets('titles itself for creation', (tester) async {
      await pumpForm(tester);

      expect(find.text(l10n(tester).createNewCounter), findsOneWidget);
    });

    testWidgets('a valid name creates the counter', (tester) async {
      await pumpForm(tester);
      await tester.enterText(
        fieldWithLabel(l10n(tester).counterName),
        'Verses',
      );
      await save(tester);

      expect(repository.calls, contains('createCounter(Verses)'));
      expect(
        repository.counters.values.map((Counter counter) => counter.name),
        contains('Verses'),
      );
    });

    testWidgets('it lands in the folder it was opened from', (tester) async {
      await pumpForm(tester);
      await tester.enterText(
        fieldWithLabel(l10n(tester).counterName),
        'Verses',
      );
      await save(tester);

      final Counter created = repository.counters.values.firstWhere(
        (Counter counter) => counter.name == 'Verses',
      );
      expect(created.folder?.id, folder.id);
    });

    testWidgets('an empty name is refused', (tester) async {
      await pumpForm(tester);
      await save(tester);

      expect(find.text(l10n(tester).pleaseEnterValidValue), findsWidgets);
      expect(repository.calls, isEmpty);
    });

    testWidgets('a one-letter name is refused', (tester) async {
      // Two characters is the floor, so a stray keystroke cannot create a
      // counter nobody can identify later.
      await pumpForm(tester);
      await tester.enterText(fieldWithLabel(l10n(tester).counterName), 'a');
      await save(tester);

      expect(find.text(l10n(tester).pleaseEnterValidValue), findsWidgets);
      expect(repository.calls, isEmpty);
    });

    testWidgets('a limit that is not a positive number is refused', (
      tester,
    ) async {
      await pumpForm(tester);
      await tester.enterText(
        fieldWithLabel(l10n(tester).counterName),
        'Verses',
      );
      await tester.enterText(fieldWithLabel(l10n(tester).limit), '0');
      await save(tester);

      expect(find.text(l10n(tester).pleaseEnterValidValue), findsWidgets);
      expect(repository.calls, isEmpty);
    });

    testWidgets('the form closes once the counter is saved', (tester) async {
      await pumpForm(tester);
      await tester.enterText(
        fieldWithLabel(l10n(tester).counterName),
        'Verses',
      );
      await save(tester);

      expect(find.byType(CounterFormScreen), findsNothing);
    });
  });

  group('editing a counter', () {
    testWidgets('titles itself for editing and opens on its values', (
      tester,
    ) async {
      final Counter counter = repository.seedCounter(
        name: 'Verses',
        folder: folder,
        count: 12,
      );

      await pumpForm(tester, counterId: counter.id);

      expect(find.text(l10n(tester).editCounter), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Verses'), findsOneWidget);
    });

    testWidgets('saving updates rather than creating a second counter', (
      tester,
    ) async {
      final Counter counter = repository.seedCounter(
        name: 'Verses',
        folder: folder,
      );

      await pumpForm(tester, counterId: counter.id);
      await tester.enterText(
        fieldWithLabel(l10n(tester).counterName),
        'Renamed',
      );
      await save(tester);

      expect(repository.calls, contains('updateCounter(${counter.id})'));
      expect(repository.counters.length, 1);
      expect(repository.counters[counter.id]!.name, 'Renamed');
    });
  });

  testWidgets('reset clears what was typed', (tester) async {
    await pumpForm(tester);
    await tester.enterText(fieldWithLabel(l10n(tester).counterName), 'Verses');
    await tapButton(tester, l10n(tester).reset);

    expect(find.widgetWithText(TextFormField, 'Verses'), findsNothing);
  });
}
