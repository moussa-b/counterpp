import 'package:counter/widgets/counter_progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

void main() {
  ProgressIndicatorPainter painterOf(WidgetTester tester) {
    return tester.widget<CustomPaint>(find.byType(CustomPaint).last).painter!
        as ProgressIndicatorPainter;
  }

  Future<void> pumpProgress(
    WidgetTester tester, {
    double progress = 0.0,
    bool isInfinite = false,
    Widget? content,
    VoidCallback? onTap,
  }) {
    return pumpApp(
      tester,
      CounterProgress(
        circleWidth: 4,
        color: '#ff0000',
        progress: progress,
        size: 60,
        isInfinite: isInfinite,
        content: content,
        onTap: onTap ?? () {},
      ),
    );
  }

  testWidgets('shows whatever content it is given in the middle', (
    tester,
  ) async {
    await pumpProgress(tester, content: const Text('42'));

    expect(find.text('42'), findsOneWidget);
  });

  testWidgets('tapping the ring reports it', (tester) async {
    int taps = 0;

    await pumpProgress(tester, onTap: () => taps++);
    await tester.tap(find.byType(CustomPaint).last);
    await tester.pumpAndSettle();

    expect(taps, 1);
  });

  group('a bounded counter', () {
    testWidgets('an empty counter sweeps nothing', (tester) async {
      await pumpProgress(tester);

      expect(painterOf(tester).sweepAngle, 0.0);
    });

    testWidgets('a half-full counter sweeps half the circle', (tester) async {
      await pumpProgress(tester, progress: 0.5);

      expect(painterOf(tester).sweepAngle, closeTo(3.14159, 0.001));
    });

    testWidgets('it starts the arc at twelve o\'clock', (tester) async {
      await pumpProgress(tester, progress: 0.25);

      expect(painterOf(tester).startAngle, closeTo(-1.5708, 0.001));
      expect(painterOf(tester).useGradient, isFalse);
    });
  });

  group('an unbounded counter', () {
    // With no limit there is no "full", so the ring paints a rotating gradient
    // instead of an arc that grows.
    testWidgets('paints a gradient rather than an arc', (tester) async {
      await pumpProgress(tester, progress: 0.3, isInfinite: true);

      expect(painterOf(tester).useGradient, isTrue);
    });

    testWidgets('the gradient turns with the count', (tester) async {
      await pumpProgress(tester, isInfinite: true);
      final double atZero = painterOf(tester).startAngle;

      await pumpProgress(tester, progress: 0.5, isInfinite: true);

      expect(painterOf(tester).startAngle, greaterThan(atZero));
    });
  });

  testWidgets('never repaints, since every value comes in as a parameter', (
    tester,
  ) async {
    await pumpProgress(tester, progress: 0.5);

    expect(painterOf(tester).shouldRepaint(painterOf(tester)), isFalse);
  });
}
