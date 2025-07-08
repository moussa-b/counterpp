import 'package:counterpp/models/bottom_sheet_result.dart';
import 'package:flutter/material.dart';
import 'package:counterpp/l10n/app_localizations.dart';

class BottomSheetItem extends StatelessWidget {
  final Icon icon;
  final String label;
  final BottomSheetAction? result; // result to send back to Widget that opened the BottomSheet
  final void Function() onTap;
  final bool closeOnTap;
  final bool showConfirmationDialog;
  final Widget? dialogTitle;
  final Widget? dialogContent;

  void _showDialog(BuildContext context, void Function() confirmCallback, Widget title, Widget content, BottomSheetAction? result) {
    showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: title,
            content: content,
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                },
                child: Text(AppLocalizations.of(ctx)!.cancel),
              ),
              TextButton(
                onPressed: () {
                  confirmCallback();
                  Navigator.pop(ctx, result);
                },
                child: Text(AppLocalizations.of(ctx)!.validate),
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
    this.result,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (closeOnTap) {
          Navigator.pop(context);
        }
        if (showConfirmationDialog && dialogContent != null && dialogTitle != null) {
          _showDialog(context, onTap, dialogTitle!, dialogContent!, result);
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
