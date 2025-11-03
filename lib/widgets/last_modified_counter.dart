import 'package:counter/models/counter.dart';
import 'package:counter/providers/last_modified_counter_provider.dart';
import 'package:flutter/material.dart';
import 'package:counter/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class LastModifiedCounter extends ConsumerWidget {
  const LastModifiedCounter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    AsyncValue<Counter?> lastModifiedCounter =
        ref.watch(lastModifiedCounterProvider);
    if (lastModifiedCounter.hasValue) {
      final String lastModificationLabel;
      if (lastModifiedCounter.value != null && lastModifiedCounter.value!.lastModificationTimeStamp != null) {
        lastModificationLabel = '${lastModifiedCounter.value!.name} - ${DateFormat('dd/MM/yy').format(DateTime.fromMillisecondsSinceEpoch(lastModifiedCounter.value!.lastModificationTimeStamp!))}';
      } else {
        lastModificationLabel = AppLocalizations.of(context)!.none;
      }
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          AppLocalizations.of(context)!
              .lastCounterModified(lastModificationLabel),
          style: TextStyle(color: Theme.of(context).textTheme.titleMedium!.color),
          textAlign: TextAlign.center,
        ),
      );
    } else {
      return Container();
    }
  }
}
