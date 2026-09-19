import 'package:counter/widgets/non_dismissible_popup_menu_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

void main() {
  /// Opens a popup menu holding one ordinary item and one non-dismissible one,
  /// which is how the sort menus use it: the header and the checked rows stay
  /// put so several can be toggled in a row.
  Future<List<String>> openMenu(WidgetTester tester) async {
    final List<String> taps = <String>[];

    await pumpApp(
      tester,
      Builder(
        builder: (BuildContext context) {
          return PopupMenuButton<String>(
            itemBuilder: (_) => <PopupMenuEntry<String>>[
              NonDismissiblePopupMenuItem<String>(
                value: 'stays',
                onTap: () => taps.add('stays'),
                child: const Text('Stays open'),
              ),
              PopupMenuItem<String>(
                value: 'closes',
                onTap: () => taps.add('closes'),
                child: const Text('Closes'),
              ),
            ],
          );
        },
      ),
    );
    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    return taps;
  }

  testWidgets('a plain item closes the menu when tapped', (tester) async {
    final List<String> taps = await openMenu(tester);

    await tester.tap(find.text('Closes'));
    await tester.pumpAndSettle();

    expect(taps, <String>['closes']);
    expect(find.text('Closes'), findsNothing);
  });

  testWidgets('a non-dismissible item runs its callback', (tester) async {
    final List<String> taps = await openMenu(tester);

    await tester.tap(find.text('Stays open'));
    await tester.pumpAndSettle();

    expect(taps, <String>['stays']);
  });

  testWidgets('and leaves the menu open', (tester) async {
    await openMenu(tester);

    await tester.tap(find.text('Stays open'));
    await tester.pumpAndSettle();

    expect(find.text('Stays open'), findsOneWidget);
  });

  testWidgets('so it can be tapped several times in a row', (tester) async {
    final List<String> taps = await openMenu(tester);

    for (int i = 0; i < 3; i++) {
      await tester.tap(find.text('Stays open'));
      await tester.pumpAndSettle();
    }

    expect(taps, <String>['stays', 'stays', 'stays']);
  });
}
