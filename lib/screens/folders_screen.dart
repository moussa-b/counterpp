import 'package:counter/models/folder.dart';
import 'package:counter/providers/folders_provider.dart';
import 'package:counter/widgets/editable_folder_list.dart';
import 'package:counter/widgets/folder_dialog.dart';
import 'package:counter/widgets/folder_list.dart';
import 'package:counter/widgets/loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:counter/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FoldersScreen extends ConsumerWidget {
  final bool? editMode;

  const FoldersScreen({super.key, this.editMode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Widget content;
    AsyncValue<List<Folder>> folders = ref.watch(foldersProvider);
    if (folders.isLoading) {
      content = const LoadingIndicator();
    } else if (folders.value == null || folders.value!.isEmpty) {
      content = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppLocalizations.of(context)!.noFolder),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => const FolderDialog(),
                );
              },
              child: Text(AppLocalizations.of(context)!.createNewFolder),
            ),
          ],
        ),
      );
    } else {
      content = editMode == true
          ? EditableFolderList(folders: folders.value!)
          : FolderList(folders: folders.value!);
    }

    return content;
  }
}
