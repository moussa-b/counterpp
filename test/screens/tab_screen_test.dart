import 'package:counter/screens/folders_screen.dart';
import 'package:counter/screens/settings_screen.dart';
import 'package:counter/screens/tab_screen.dart';
import 'package:counter/widgets/counter_widget.dart';
import 'package:counter/widgets/folder_dialog.dart';
import 'package:counter/widgets/folders_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../helpers/fake_counter_repository.dart';
import '../helpers/fake_wakelock.dart';
import '../helpers/test_app.dart';

void main() {
  late FakeCounterRepository repository;

  setUp(() {
    repository = FakeCounterRepository();
    // The home tab counts on counter 1 existing.
    repository.seedCounter(name: 'Built-in');
    installFakeWakelock();
  });

  Future<void> pumpTabs(WidgetTester tester, {int tab = homeTabIndex}) {
    return pumpApp(
      tester,
      TabsScreen(selectedTabIndex: tab),
      repository: repository,
      wrapInScaffold: false,
    );
  }

  Future<void> tapTab(WidgetTester tester, String label) async {
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  testWidgets('offers the three tabs', (tester) async {
    await pumpTabs(tester);

    expect(find.text(l10n(tester).home), findsOneWidget);
    expect(find.text(l10n(tester).folders), findsOneWidget);
    expect(find.text(l10n(tester).settings), findsWidgets);
  });

  group('the home tab', () {
    testWidgets('shows the built-in counter', (tester) async {
      await pumpTabs(tester);

      expect(find.byType(CounterWidget), findsOneWidget);
      expect(find.text('Counter++'), findsOneWidget);
    });

    testWidgets('its app bar resets that counter', (tester) async {
      repository.counters[1]!.counterCount = 5;

      await pumpTabs(tester);
      await tester.tap(find.byIcon(Icons.settings_backup_restore_rounded));
      await tester.pumpAndSettle();

      expect(repository.calls, contains('resetCounterById(1)'));
    });

    testWidgets('has no floating action button', (tester) async {
      await pumpTabs(tester);

      expect(find.byType(FloatingActionButton), findsNothing);
    });
  });

  group('the folders tab', () {
    testWidgets('shows the folders screen and its app bar', (tester) async {
      await pumpTabs(tester, tab: folderTabIndex);

      expect(find.byType(FoldersScreen), findsOneWidget);
      expect(find.byType(FoldersAppBar), findsOneWidget);
    });

    testWidgets('offers a button to add a folder', (tester) async {
      await pumpTabs(tester, tab: folderTabIndex);

      expect(find.byType(FloatingActionButton), findsOneWidget);
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.byType(FolderDialog), findsOneWidget);
    });

    testWidgets('the add button uses FaIcon, not Icon', (tester) async {
      await pumpTabs(tester, tab: folderTabIndex);

      expect(
        find.byWidgetPredicate(
          (Widget widget) =>
              widget is FaIcon && widget.icon == FontAwesomeIcons.plus.data,
        ),
        findsOneWidget,
      );
    });
  });

  testWidgets('the settings tab shows the settings screen', (tester) async {
    await pumpTabs(tester, tab: settingsTabIndex);

    expect(find.byType(SettingsScreen), findsOneWidget);
  });

  group('switching tabs', () {
    testWidgets('moves to the tab that was tapped', (tester) async {
      await pumpTabs(tester);
      expect(find.byType(CounterWidget), findsOneWidget);

      await tapTab(tester, l10n(tester).folders);

      expect(find.byType(FoldersScreen), findsOneWidget);
      expect(find.byType(CounterWidget), findsNothing);
    });

    testWidgets('remembers the tab for the next launch', (tester) async {
      await pumpTabs(tester);

      await tapTab(tester, l10n(tester).folders);

      expect(repository.calls, contains('updateLastOpenedTabIndex(1)'));
      expect(repository.settings.lastOpenedTabIndex, 1);
    });

    testWidgets('it opens on the tab it was given', (tester) async {
      await pumpTabs(tester, tab: folderTabIndex);

      final BottomNavigationBar bar = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );
      expect(bar.currentIndex, folderTabIndex);
    });
  });
}
