import 'package:counter/models/counter.dart';
import 'package:counter/models/folder.dart';
import 'package:counter/providers/last_modified_counter_provider.dart';
import 'package:counter/widgets/last_modified_counter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import '../helpers/fake_counter_repository.dart';
import '../helpers/test_app.dart';

void main() {
  late FakeCounterRepository repository;
  late Folder folder;

  setUp(() {
    repository = FakeCounterRepository();
    folder = repository.seedFolder('Work');
  });

  /// Pumps the banner, then points the provider at [folderId] the way the
  /// counters screen does when it opens a folder.
  Future<void> pumpBanner(WidgetTester tester, {int? folderId}) async {
    await pumpApp(tester, const LastModifiedCounter(), repository: repository);
    if (folderId != null) {
      await tester
          .container()
          .read(lastModifiedCounterProvider.notifier)
          .setFolderId(folderId);
      await tester.pumpAndSettle();
    }
  }

  testWidgets('says none while no counter has been touched', (tester) async {
    repository.seedCounter(name: 'Verses', folder: folder);

    await pumpBanner(tester, folderId: folder.id);

    expect(
      find.text(l10n(tester).lastCounterModified(l10n(tester).none)),
      findsOneWidget,
    );
  });

  testWidgets('names the counter and when it was touched', (tester) async {
    final Counter counter = repository.seedCounter(
      name: 'Verses',
      folder: folder,
    );
    final DateTime touchedAt = DateTime(2026, 3, 14, 9, 5);
    counter.lastModificationTimeStamp = touchedAt.millisecondsSinceEpoch;

    await pumpBanner(tester, folderId: folder.id);

    final String stamp = DateFormat('dd/MM/yy HH:mm').format(touchedAt);
    expect(
      find.text(l10n(tester).lastCounterModified('Verses - $stamp')),
      findsOneWidget,
    );
  });

  testWidgets('an empty folder still says none rather than nothing', (
    tester,
  ) async {
    await pumpBanner(tester, folderId: folder.id);

    expect(
      find.text(l10n(tester).lastCounterModified(l10n(tester).none)),
      findsOneWidget,
    );
  });

  testWidgets('it follows the folder it is pointed at', (tester) async {
    final Folder home = repository.seedFolder('Home');
    final Counter elsewhere = repository.seedCounter(
      name: 'Elsewhere',
      folder: home,
    );
    elsewhere.lastModificationTimeStamp = DateTime(
      2026,
      3,
      14,
    ).millisecondsSinceEpoch;

    await pumpBanner(tester, folderId: folder.id);
    expect(find.textContaining('Elsewhere'), findsNothing);

    await tester
        .container()
        .read(lastModifiedCounterProvider.notifier)
        .setFolderId(home.id!);
    await tester.pumpAndSettle();

    expect(find.textContaining('Elsewhere'), findsOneWidget);
  });
}
