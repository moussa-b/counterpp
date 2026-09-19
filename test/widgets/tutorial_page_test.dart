import 'package:counter/widgets/tutorial_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

void main() {
  Future<void> pumpPage(
    WidgetTester tester, {
    String? title,
    String subtitle = 'Count what you memorise',
    Color color = Colors.indigo,
  }) {
    return pumpApp(
      tester,
      TutorialPage(
        color: color,
        image: 'assets/images/tutorial/tutorial1_en.png',
        title: title,
        subtitle: subtitle,
      ),
    );
  }

  testWidgets('shows the subtitle and the illustration', (tester) async {
    await pumpPage(tester);

    expect(find.text('Count what you memorise'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('shows the title when there is one', (tester) async {
    await pumpPage(tester, title: 'Welcome');

    expect(find.text('Welcome'), findsOneWidget);
  });

  testWidgets('leaves the title out entirely when there is none', (
    tester,
  ) async {
    // The slot collapses rather than rendering an empty line, which would push
    // the subtitle off centre.
    await pumpPage(tester, title: 'Welcome');
    expect(find.byType(Center), findsNWidgets(2));

    await pumpPage(tester);

    expect(find.byType(Center), findsOneWidget);
  });

  testWidgets('paints the background colour it is given', (tester) async {
    await pumpPage(tester, color: Colors.teal);

    final Container container = tester.widget<Container>(
      find.ancestor(of: find.byType(Column), matching: find.byType(Container)),
    );
    expect(container.color, Colors.teal);
  });
}
