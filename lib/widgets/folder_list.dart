import 'package:counter/models/folder.dart';
import 'package:counter/widgets/folder_list_item.dart';
import 'package:flutter/material.dart';

class FolderList extends StatelessWidget {
  final List<Folder> folders;

  const FolderList({super.key, required this.folders});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemBuilder: (ctx, index) {
        final Folder folder = folders[index];
        final String keyValue = '${folder.id!}-${folder.lastModificationTimeStamp!}';
        return FolderListItem(
          key: ValueKey<String>(keyValue),
          folder: folder,
        );
      },
      itemCount: folders.length,
    );
  }
}
