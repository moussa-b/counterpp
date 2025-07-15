import 'package:counterpp/widgets/folders_popup_menu.dart';
import 'package:flutter/material.dart';
import 'package:counterpp/l10n/app_localizations.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class FoldersAppBar extends StatefulWidget implements PreferredSizeWidget {
  final Function(bool editMode) onEditModeChange;

  const FoldersAppBar({super.key, required this.onEditModeChange});

  @override
  Size get preferredSize => Size.fromHeight(AppBar().preferredSize.height);

  @override
  State<FoldersAppBar> createState() => _FoldersAppBarState();
}

class _FoldersAppBarState extends State<FoldersAppBar> {
  bool _editMode = false;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(AppLocalizations.of(context)!.folderList),
      actions: <Widget>[
        // IconButton(
        //   icon: const Icon(Icons.add),
        //   onPressed: () {
        //     showDialog(
        //       context: context,
        //       builder: (ctx) => const FolderDialog(),
        //     );
        //   },
        // ),
        if (_editMode)
          IconButton(
            icon: const Icon(FontAwesomeIcons.checkDouble),
            onPressed: () {
              setState(() {
                _editMode = false;
                widget.onEditModeChange(_editMode);
              });
            },
          ),
        if (!_editMode)
          IconButton(
            icon: const Icon(Icons.swap_vert),
            onPressed: () {
              setState(() {
                _editMode = true;
                widget.onEditModeChange(_editMode);
              });
            },
          ),
        if (!_editMode) const FoldersPopupMenu(),
      ],
    );
  }
}
