import 'package:counter/models/folder.dart';
import 'package:counter/models/settings.dart';
import 'package:counter/models/sorting_options.dart';
import 'package:counter/providers/counter_repository_provider.dart';
import 'package:counter/providers/folders_provider.dart';
import 'package:counter/providers/settings_provider.dart';
import 'package:counter/widgets/folder_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EditableFolderList extends ConsumerWidget {
  final List<Folder> folders;

  const EditableFolderList({super.key, required this.folders});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ReorderableListView(
      children: folders.map((Folder folder) {
        final String keyValue =
            '${folder.id!}-${folder.lastModificationTimeStamp!}';
        return FolderListItem(
          key: ValueKey<String>(keyValue),
          folder: folder,
          active: false,
        );
      }).toList(),
      onReorderItem: (int oldIndex, int newIndex) async {
        bool result = await ref
            .read(foldersProvider.notifier)
            .onReorder(oldIndex, newIndex);
        if (result) {
          Settings settings = await ref
              .read(counterRepositoryProvider)
              .getSettings();
          settings.folderSorting = SortingOptions.custom;
          ref.read(settingsProvider.notifier).updateSettings(settings);
        }
      },
    );
  }
}
