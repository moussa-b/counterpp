import 'package:counter/models/counter.dart';
import 'package:counter/models/settings.dart';
import 'package:counter/models/sorting_options.dart';
import 'package:counter/providers/counter_repository_provider.dart';
import 'package:counter/providers/counters_provider.dart';
import 'package:counter/providers/settings_provider.dart';
import 'package:counter/widgets/counter_grid_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';

class EditableCounterGrid extends ConsumerWidget {
  final List<Counter> counters;

  const EditableCounterGrid({super.key, required this.counters});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ReorderableGridView.builder(
      padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 8.0),
      itemBuilder: (BuildContext ctx, int index) {
        final Counter counter = counters[index];
        final String keyValue =
            '${counter.id!}-${counter.lastModificationTimeStamp ?? counter.creationTimeStamp!}';
        return CounterGridItem(
            key: ValueKey<String>(keyValue),
            counter: counter,
            active: false
        );
      },
      itemCount: counters.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // number of items in each row
        mainAxisSpacing: 8.0, // spacing between rows
        crossAxisSpacing: 8.0, // spacing between columns
        childAspectRatio: 1.5,
      ),
      onReorder: (int oldIndex, int newIndex) async {
        bool result = await ref.read(countersProvider.notifier).onReorder(oldIndex, newIndex + 1); // newIndex + 1 to have behavior similar to ReorderableListView
        if (result) {
          Settings settings = await ref.read(counterRepositoryProvider).getSettings();
          settings.counterSorting = SortingOptions.custom;
          ref.read(settingsProvider.notifier).updateSettings(settings);
        }
      },
    );
  }
}
