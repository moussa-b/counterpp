import 'package:counterpp/models/folder.dart';
import 'package:counterpp/providers/counters_provider.dart';
import 'package:counterpp/providers/folders_provider.dart';
import 'package:counterpp/screens/folder_statistics_screen.dart';
import 'package:counterpp/widgets/bottom_sheet_item.dart';
import 'package:counterpp/widgets/folder_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FolderBottomSheet extends ConsumerWidget {
  const FolderBottomSheet({
    super.key,
    required this.folder,
  });

  final Folder folder;

  bool get hasCounters {
    return folder.counterNumber != null && folder.counterNumber! > 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Wrap(
      children: <Widget>[
        ListTile(
          title: Center(child: Text(folder.name!)),
          subtitle: Center(
              child: Column(
            children: [
              Text(AppLocalizations.of(context)!
                  .counterNumber(folder.counterNumber!)),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.close),
              ),
            ],
          )),
        ),
        const Divider(),
        BottomSheetItem(
          icon: const Icon(Icons.edit_note),
          label: AppLocalizations.of(context)!.rename,
          onTap: () {
            showDialog(
              context: context,
              builder: (ctx) => FolderDialog(folder: folder),
            );
          },
        ),
        BottomSheetItem(
          icon: const Icon(Icons.copy_all),
          label: AppLocalizations.of(context)!.duplicate,
          onTap: () {
            ref.read(foldersProvider.notifier).duplicateFolderById(folder.id!, suffix: ' - ${AppLocalizations.of(context)!.copy}');
          },
        ),
        if (hasCounters)
          ...[
            BottomSheetItem(
              icon: const Icon(Icons.refresh),
              label: AppLocalizations.of(context)!.resetAllCounters,
              closeOnTap: false,
              showConfirmationDialog: true,
              dialogTitle: Text(AppLocalizations.of(context)!.warning),
              dialogContent: Text(AppLocalizations.of(context)!.warningMsgResetFolderCounters),
              onTap: () {
                ref.read(foldersProvider.notifier).resetAllCountersForFolderId(folder.id!);
                Navigator.pop(context);
              },
            ),
            BottomSheetItem(
              icon: const Icon(Icons.delete),
              label: AppLocalizations.of(context)!.delete,
              closeOnTap: false,
              showConfirmationDialog: true,
              dialogTitle: Text(AppLocalizations.of(context)!.warning),
              dialogContent: Text(AppLocalizations.of(context)!.warningMsgDeleteFolder),
              onTap: () {
                ref.read(foldersProvider.notifier).deleteFolderById(folder.id!);
                Navigator.pop(context);
              },
            ),
            BottomSheetItem(
              icon: const Icon(Icons.delete_forever),
              label: AppLocalizations.of(context)!.deleteAllCounters,
              closeOnTap: false,
              showConfirmationDialog: true,
              dialogTitle: Text(AppLocalizations.of(context)!.warning),
              dialogContent: Text(AppLocalizations.of(context)!.warningMsgDeleteFolderCounters),
              onTap: () {
                ref.read(foldersProvider.notifier).deleteAllCountersForFolderId(folder.id!);
                Navigator.pop(context);
              },
            ),
          ],
        if (!hasCounters)
          BottomSheetItem(
            icon: const Icon(Icons.delete),
            label: AppLocalizations.of(context)!.delete,
            closeOnTap: false,
            showConfirmationDialog: true,
            dialogTitle: Text(AppLocalizations.of(context)!.warning),
            dialogContent:
                Text(AppLocalizations.of(context)!.warningMsgDeleteFolder),
            onTap: () {
              ref.read(foldersProvider.notifier).deleteFolderById(folder.id!);
              Navigator.pop(context);
            },
          ),
        if (hasCounters)
          BottomSheetItem(
            icon: const Icon(Icons.bar_chart),
            label: AppLocalizations.of(context)!.statistics,
            onTap: () {
              ref
                  .read(countersProvider.notifier)
                  .setFolderId(folder.id!)
                  .then((value) {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (ctx) {
                    return FolderStatisticsScreen(folder: folder);
                  }),
                );
              });
            },
          ),
      ],
    );
  }
}
