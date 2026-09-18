import 'package:counter/models/counter.dart';
import 'package:counter/models/settings.dart';
import 'package:counter/models/sorting_options.dart';
import 'package:counter/providers/counter_repository_provider.dart';
import 'package:counter/providers/counters_provider.dart';
import 'package:counter/providers/settings_provider.dart';
import 'package:counter/widgets/counter_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EditableCounterList extends ConsumerWidget {
  final List<Counter> counters;

  const EditableCounterList({super.key, required this.counters});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ReorderableListView(
      children: counters.map((Counter counter) {
        final String keyValue =
            '${counter.id!}-${counter.lastModificationTimeStamp ?? counter.creationTimeStamp!}';
        return CounterListItem(
          key: ValueKey<String>(keyValue),
          counter: counter,
          active: false,
        );
      }).toList(),
      onReorderItem: (int oldIndex, int newIndex) async {
        bool result = await ref
            .read(countersProvider.notifier)
            .onReorder(oldIndex, newIndex);
        if (result) {
          Settings settings = await ref
              .read(counterRepositoryProvider)
              .getSettings();
          settings.counterSorting = SortingOptions.custom;
          ref.read(settingsProvider.notifier).updateSettings(settings);
        }
      },
    );
  }
}
