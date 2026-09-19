import 'package:counter/widgets/loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

void main() {
  testWidgets('shows a centred spinner', (tester) async {
    // The spinner animates forever, so this widget can never be settled.
    // Every screen that shows it has to leave it behind before a test settles.
    await pumpApp(tester, const LoadingIndicator(), settle: false);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      find.ancestor(
        of: find.byType(CircularProgressIndicator),
        matching: find.byType(Center),
      ),
      findsWidgets,
    );
  });
}
