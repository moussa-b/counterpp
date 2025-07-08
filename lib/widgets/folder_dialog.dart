import 'package:counterpp/models/folder.dart';
import 'package:counterpp/providers/folders_provider.dart';
import 'package:flutter/material.dart';
import 'package:counterpp/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FolderDialog extends ConsumerStatefulWidget {
  final Folder? folder;

  const FolderDialog({super.key, this.folder});

  @override
  ConsumerState<FolderDialog> createState() => _FolderDialogState();
}

class _FolderDialogState extends ConsumerState<FolderDialog> {
  final TextEditingController _controller = TextEditingController();

  void _onSubmitted(BuildContext ctx) async {
    var folderName = _controller.text.trim();
    if (folderName.isNotEmpty) {
      final foldersNotifier = ref.read(foldersProvider.notifier);
      if (widget.folder?.id != null && widget.folder!.id! > 0) {
        foldersNotifier.renameFolder(widget.folder!.id!, folderName).then((Folder? updatedFolder) {
          closeAddFolderDialog(ctx, folder: updatedFolder);
        });
      } else {
        foldersNotifier.addFolder(folderName).then((Folder? createdFolder) {
          closeAddFolderDialog(ctx, folder: createdFolder);
        });
      }
      return;
    }
    closeAddFolderDialog(ctx);
  }

  void closeAddFolderDialog(BuildContext ctx, {Folder? folder}) {
    Navigator.of(ctx).pop(folder);
    _controller.clear();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.folder?.name?.isNotEmpty ?? false) {
      _controller.text = widget.folder!.name!;
    }
    final bool isUpdate = (widget.folder?.id != null && widget.folder!.id! > 0);
    return AlertDialog(
      title: Text(isUpdate ? AppLocalizations.of(context)!.renameFolder : AppLocalizations.of(context)!.createNewFolder),
      content: TextField(
        autofocus: true,
        controller: _controller,
        onSubmitted: (_) => _onSubmitted(context),
        decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.createNewFolderPlaceholder),
      ),
      actions: [
        TextButton(
          onPressed: () {
            closeAddFolderDialog(context);
          },
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        TextButton(
          onPressed: () => _onSubmitted(context),
          child: Text(AppLocalizations.of(context)!.validate),
        ),
      ],
    );
  }
}
