import 'package:counter/screens/tutorial_screen.dart';
import 'package:counter/widgets/tutorial_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../helpers/fake_counter_repository.dart';
import '../helpers/test_app.dart';

void main() {
  late FakeCounterRepository repository;
  late int continues;

  setUp(() {
    repository = FakeCounterRepository();
    continues = 0;
  });

  Future<void> pumpTutorial(
    WidgetTester tester, {
    bool withCallback = true,
    Locale locale = const Locale('en'),
  }) {
    return pumpApp(
      tester,
      TutorialScreen(continueCallback: withCallback ? () => continues++ : null),
      repository: repository,
      locale: locale,
      wrapInScaffold: false,
    );
  }

  Future<void> tapNext(WidgetTester tester) async {
    await tester.tap(find.text(l10n(tester).next));
    await tester.pumpAndSettle();
  }

  testWidgets('opens on the first page with a page indicator', (tester) async {
    await pumpTutorial(tester);

    expect(find.text(l10n(tester).tutorialMsg1), findsOneWidget);
    expect(find.byType(SmoothPageIndicator), findsOneWidget);
  });

  testWidgets('offers skip and next while there are pages left', (
    tester,
  ) async {
    await pumpTutorial(tester);

    expect(find.text(l10n(tester).skip), findsOneWidget);
    expect(find.text(l10n(tester).next), findsOneWidget);
    expect(find.text(l10n(tester).start), findsNothing);
  });

  testWidgets('next moves to the following page', (tester) async {
    await pumpTutorial(tester);

    await tapNext(tester);

    expect(find.text(l10n(tester).tutorialMsg2), findsOneWidget);
  });

  testWidgets('the last page swaps the buttons for start', (tester) async {
    await pumpTutorial(tester);

    for (int i = 0; i < 3; i++) {
      await tapNext(tester);
    }

    expect(find.text(l10n(tester).tutorialMsg4), findsOneWidget);
    expect(find.text(l10n(tester).start), findsOneWidget);
    expect(find.text(l10n(tester).skip), findsNothing);
    expect(find.text(l10n(tester).next), findsNothing);
  });

  testWidgets('skip jumps straight to the end', (tester) async {
    await pumpTutorial(tester);

    await tester.tap(find.text(l10n(tester).skip));
    await tester.pumpAndSettle();

    expect(find.text(l10n(tester).start), findsOneWidget);
  });

  testWidgets('start reports that the tutorial is done', (tester) async {
    await pumpTutorial(tester);
    await tester.tap(find.text(l10n(tester).skip));
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n(tester).start));
    await tester.pumpAndSettle();

    expect(continues, 1);
  });

  testWidgets('it shows four pages', (tester) async {
    await pumpTutorial(tester);

    expect(find.byType(TutorialPage), findsWidgets);
    final PageView pageView = tester.widget<PageView>(find.byType(PageView));
    expect(pageView.childrenDelegate.estimatedChildCount, 4);
  });

  testWidgets('it uses the illustrations of the current language', (
    tester,
  ) async {
    // There is one set of screenshots per locale, so the wrong language shows
    // an English phone next to French text.
    await pumpTutorial(tester, locale: const Locale('fr'));

    final Image image = tester.widget<Image>(find.byType(Image).first);
    expect((image.image as AssetImage).assetName, contains('_fr'));
  });

  testWidgets('the buttons fit on a narrow phone in French too', (
    tester,
  ) async {
    // "Suivant" and "Passer" are wider than "Next" and "Skip". The row used to
    // overflow by 5px at 390dp, which a 360dp Android phone makes worse.
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await pumpTutorial(tester, locale: const Locale('fr'));

    expect(tester.takeException(), isNull);
    expect(find.text(l10n(tester).next), findsOneWidget);
    expect(find.text(l10n(tester).skip), findsOneWidget);
  });
}
