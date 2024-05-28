import 'package:counterpp/models/counter.dart';
import 'package:counterpp/providers/counters_provider.dart';
import 'package:counterpp/providers/last_modified_counter_provider.dart';
import 'package:counterpp/screens/counter_form_screen.dart';
import 'package:counterpp/screens/counter_screen.dart';
import 'package:counterpp/screens/counter_statistics_screen.dart';
import 'package:counterpp/widgets/bottom_sheet_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CounterBottomSheet extends ConsumerWidget {
  const CounterBottomSheet({
    super.key,
    required this.counter,
  });

  final Counter counter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Wrap(
      children: <Widget>[
        ListTile(
          title: Center(child: Text(counter.name!)),
          subtitle: Center(
              child: Column(
                children: [
                  Text(counter.counterCount?.toString() != null ? '${AppLocalizations.of(context)!.value} : ${counter.counterCount}' : ''),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(AppLocalizations.of(context)!.close),
                  ),
                ],
              )),
        ),
        const Divider(),
        BottomSheetItem(
          icon: const Icon(FontAwesomeIcons.maximize),
          label: AppLocalizations.of(context)!.fullScreen,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (ctx) {
                  return CounterScreen(counter: counter);
                },
              ),
            );
          },
        ),
        BottomSheetItem(
          icon: const Icon(Icons.edit_note),
          label: AppLocalizations.of(context)!.editCounter,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (ctx) {
                return CounterFormScreen(counterId: counter.id);
              }),
            );
          },
        ),
        BottomSheetItem(
          icon: const Icon(Icons.copy_all),
          label: AppLocalizations.of(context)!.duplicate,
          onTap: () {
            ref.read(countersProvider.notifier).duplicateCounterById(counter.id!, suffix: ' - ${AppLocalizations.of(context)!.copy}');
          },
        ),
        BottomSheetItem(
          icon: const Icon(Icons.refresh),
          label: AppLocalizations.of(context)!.reset,
          closeOnTap: false,
          showConfirmationDialog: true,
          dialogTitle: Text(AppLocalizations.of(context)!.warning),
          dialogContent: Text(AppLocalizations.of(context)!.warningMsgResetCounter),
          onTap: () {
            ref.read(countersProvider.notifier).resetCounterById(counter.id!);
            Navigator.pop(context);
          },
        ),
        BottomSheetItem(
          icon: const Icon(Icons.delete),
          label: AppLocalizations.of(context)!.delete,
          closeOnTap: false,
          showConfirmationDialog: true,
          dialogTitle: Text(AppLocalizations.of(context)!.warning),
          dialogContent: Text(AppLocalizations.of(context)!.warningMsgDeleteCounter),
          onTap: () {
            ref.read(countersProvider.notifier).deleteCounter(counter);
            ref.read(lastModifiedCounterProvider.notifier).refresh();
            Navigator.pop(context);
          },
        ),
        BottomSheetItem(
          icon: const Icon(Icons.bar_chart),
          label: AppLocalizations.of(context)!.statistics,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (ctx) {
                return CounterStatisticsScreen(counter: counter);
              }),
            );
          },
        ),
      ],
    );
  }
}
