import 'package:counter/l10n/app_localizations.dart';
import 'package:counter/models/folder.dart';
import 'package:counter/providers/counter_repository_provider.dart';
import 'package:counter/providers/counters_provider.dart';
import 'package:counter/providers/last_modified_counter_provider.dart';
import 'package:counter/screens/counters_screen.dart';
import 'package:counter/widgets/folder_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FolderListItem extends ConsumerWidget {
  const FolderListItem({super.key, required this.folder, this.active = true});

  final Folder folder;
  final bool active;

  void onSelectFolder(BuildContext context, WidgetRef ref, Folder folder) {
    final int folderId = folder.id!;
    ref.read(countersProvider.notifier).setFolderId(folderId);
    ref.read(lastModifiedCounterProvider.notifier).setFolderId(folderId);
    Navigator.of(context).push(MaterialPageRoute(builder: (ctx) {
      return CountersScreen(folder: folder);
    })).then((_) async {
      ref.read(counterRepositoryProvider).synchronizeCountersCount(folderId);
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: InkWell(
        onTap: () => active ? onSelectFolder(context, ref, folder) : null,
        child: ListTile(
          leading: const Icon(Icons.folder),
          title: Text(folder.name!),
          subtitle: Text(AppLocalizations.of(context)!
              .counterNumber(folder.counterNumber!)),
          trailing: active ? IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              showModalBottomSheet<void>(
                context: context,
                builder: (BuildContext context) {
                  return FolderBottomSheet(folder: folder);
                },
              );
            },
          ) : null,
        ),
      ),
    );
  }
}
