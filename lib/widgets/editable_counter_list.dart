import 'package:counterpp/models/counter.dart';
import 'package:counterpp/models/settings.dart';
import 'package:counterpp/models/sorting_options.dart';
import 'package:counterpp/providers/counter_repository_provider.dart';
import 'package:counterpp/providers/counters_provider.dart';
import 'package:counterpp/providers/settings_provider.dart';
import 'package:counterpp/widgets/counter_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EditableCounterList extends ConsumerWidget {
  final List<Counter> counters;

  const EditableCounterList({super.key, required this.counters});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    return ReorderableListView(
      children: counters.map((Counter counter) {
        final String keyValue = '${counter.id!}-${counter.lastModificationTimeStamp ?? counter.creationTimeStamp!}';
        return CounterListItem(
            key: ValueKey<String>(keyValue),
            counter: counter,
            active: false
        );
      }).toList(),
      onReorder: (int oldIndex, int newIndex) async {
        bool result = await ref.read(countersProvider.notifier).onReorder(oldIndex, newIndex);
        if (result) {
          Settings settings = await ref.read(counterRepositoryProvider).getSettings();
          settings.counterSorting = SortingOptions.custom;
          ref.read(settingsProvider.notifier).updateSettings(settings);
        }
      },
    );
  }
}
