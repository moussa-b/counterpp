import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class BottomSheetItem extends StatelessWidget {
  final Icon icon;
  final String label;
  final void Function() onTap;
  final bool closeOnTap;
  final bool showConfirmationDialog;
  final Widget? dialogTitle;
  final Widget? dialogContent;

  void _showDialog(BuildContext context, void Function() confirmCallback, Widget title, Widget content) {
    showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: title,
            content: content,
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                },
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              TextButton(
                onPressed: () {
                  confirmCallback();
                  Navigator.of(ctx).pop();
                },
                child: Text(AppLocalizations.of(context)!.validate),
              ),
            ],
          );
        });
  }

  const BottomSheetItem({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.closeOnTap = true,
    this.showConfirmationDialog = false,
    this.dialogTitle,
    this.dialogContent,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (closeOnTap) {
          Navigator.pop(context);
        }
        if (showConfirmationDialog && dialogContent != null && dialogTitle != null) {
          _showDialog(context, onTap, dialogTitle!, dialogContent!);
        } else {
          onTap();
        }
      },
      child: ListTile(
        leading: icon,
        title: Text(label),
      ),
    );
  }
}
