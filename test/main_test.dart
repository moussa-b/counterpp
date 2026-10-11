// Value: protects=the app theme renders text in the bundled Lato family, and
// the font files plus their OFL licence ship in the asset bundle;
// fails_when=fontFamily is dropped from the theme, the pubspec `fonts:` entry
// (or its bold weight) is removed, or OFL.txt stops being declared as an
// asset; why_new=no test read the app theme or the asset bundle, and a
// missing font family only falls back silently at runtime; seam=none;
// no_claim=does not exercise the LicenseRegistry callback inside main(),
// which also calls runApp, nor glyph rendering.
import 'dart:convert';

import 'package:counter/main.dart' show theme;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('text under the app theme resolves to Lato', (tester) async {
    late TextStyle? body;
    late TextStyle? title;
    await pumpApp(
      tester,
      Builder(
        builder: (context) {
          body = Theme.of(context).textTheme.bodyMedium;
          title = Theme.of(context).textTheme.titleLarge;
          return const Text('x');
        },
      ),
    );

    expect(body?.fontFamily, 'Lato');
    expect(title?.fontFamily, 'Lato');
    expect(theme.primaryTextTheme.bodyMedium?.fontFamily, 'Lato');
  });

  test('Lato regular and bold are bundled under the Lato family', () async {
    // Offline first launch depends on these files being in the bundle: there
    // is no runtime download to fall back on any more.
    final List<dynamic> manifest = jsonDecode(
      await rootBundle.loadString('FontManifest.json'),
    ) as List<dynamic>;
    final Map<String, dynamic> lato = manifest
        .cast<Map<String, dynamic>>()
        .firstWhere((family) => family['family'] == 'Lato');
    final List<Map<String, dynamic>> fonts = (lato['fonts'] as List<dynamic>)
        .cast<Map<String, dynamic>>();

    expect(
      fonts.map((font) => font['asset']),
      unorderedEquals(<String>[
        'assets/fonts/lato/Lato-Regular.ttf',
        'assets/fonts/lato/Lato-Bold.ttf',
      ]),
    );
    expect(
      fonts.firstWhere(
        (font) => font['asset'] == 'assets/fonts/lato/Lato-Bold.ttf',
      )['weight'],
      700,
    );
    for (final Map<String, dynamic> font in fonts) {
      final ByteData bytes = await rootBundle.load(font['asset'] as String);
      expect(bytes.lengthInBytes, greaterThan(0), reason: font['asset']);
    }
  });

  test('the Lato OFL licence ships in the asset bundle', () async {
    // main() registers this file with LicenseRegistry; if it is not declared
    // as an asset the licence page fails to load it.
    final String licence = await rootBundle.loadString(
      'assets/fonts/lato/OFL.txt',
    );

    expect(licence, contains('SIL Open Font License'));
  });
}
