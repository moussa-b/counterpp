import 'dart:async';

import 'package:counter/models/bottom_sheet_result.dart';
import 'package:counter/widgets/bottom_sheet_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

void main() {
  /// Opens a sheet holding [item] and reports what it popped with, which is how
  /// the counter and folder rows learn that a reset or a delete happened.
  Future<BottomSheetAction?> openSheet(
    WidgetTester tester,
    BottomSheetItem item,
  ) async {
    BottomSheetAction? popped;
    late BuildContext sheetHost;

    await pumpApp(
      tester,
      Builder(
        builder: (BuildContext context) {
          sheetHost = context;
          return const SizedBox.shrink();
        },
      ),
    );

    unawaited(
      showModalBottomSheet<BottomSheetAction?>(
        context: sheetHost,
        builder: (_) => item,
      ).then((BottomSheetAction? value) => popped = value),
    );
    await tester.pumpAndSettle();
    return popped;
  }

  testWidgets('shows its icon and label', (tester) async {
    await openSheet(
      tester,
      BottomSheetItem(
        icon: const Icon(Icons.delete),
        label: 'Delete',
        onTap: () {},
      ),
    );

    expect(find.text('Delete'), findsOneWidget);
    expect(find.byIcon(Icons.delete), findsOneWidget);
  });

  testWidgets('a plain tap runs the callback and closes the sheet', (
    tester,
  ) async {
    int taps = 0;

    await openSheet(
      tester,
      BottomSheetItem(
        icon: const Icon(Icons.copy),
        label: 'Duplicate',
        onTap: () => taps++,
      ),
    );
    await tester.tap(find.text('Duplicate'));
    await tester.pumpAndSettle();

    expect(taps, 1);
    expect(find.text('Duplicate'), findsNothing);
  });

  testWidgets('closeOnTap false leaves the sheet open', (tester) async {
    await openSheet(
      tester,
      BottomSheetItem(
        icon: const Icon(Icons.copy),
        label: 'Duplicate',
        onTap: () {},
        closeOnTap: false,
      ),
    );
    await tester.tap(find.text('Duplicate'));
    await tester.pumpAndSettle();

    expect(find.text('Duplicate'), findsOneWidget);
  });

  group('confirmation dialog', () {
    BottomSheetItem destructiveItem(void Function() onTap) {
      return BottomSheetItem(
        icon: const Icon(Icons.delete),
        label: 'Delete',
        onTap: onTap,
        showConfirmationDialog: true,
        dialogTitle: const Text('Delete counter'),
        dialogContent: const Text('This cannot be undone'),
        result: BottomSheetAction.delete,
      );
    }

    testWidgets('asks before running a destructive action', (tester) async {
      int taps = 0;

      await openSheet(tester, destructiveItem(() => taps++));
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Delete counter'), findsOneWidget);
      expect(find.text('This cannot be undone'), findsOneWidget);
      expect(taps, 0, reason: 'nothing should happen until it is confirmed');
    });

    testWidgets('cancelling leaves the action unrun', (tester) async {
      int taps = 0;

      await openSheet(tester, destructiveItem(() => taps++));
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n(tester).cancel));
      await tester.pumpAndSettle();

      expect(taps, 0);
      expect(find.text('Delete counter'), findsNothing);
    });

    testWidgets('confirming runs the action', (tester) async {
      int taps = 0;

      await openSheet(tester, destructiveItem(() => taps++));
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n(tester).validate));
      await tester.pumpAndSettle();

      expect(taps, 1);
      expect(find.text('Delete counter'), findsNothing);
    });
  });
}
