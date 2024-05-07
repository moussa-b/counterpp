import 'package:counterpp/models/counter.dart';
import 'package:counterpp/widgets/counter_grid_item.dart';
import 'package:flutter/material.dart';

class EditableCounterGrid extends StatelessWidget {
  final List<Counter> counters;

  const EditableCounterGrid({super.key, required this.counters});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 8.0),
      itemBuilder: (ctx, index) {
        final Counter counter = counters[index];
        final String keyValue =
            '${counter.id!}-${counter.lastModificationTimeStamp!}';
        return CounterGridItem(
          key: ValueKey<String>(keyValue),
          counter: counter,
        );
      },
      itemCount: counters.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // number of items in each row
        mainAxisSpacing: 8.0, // spacing between rows
        crossAxisSpacing: 8.0, // spacing between columns
        childAspectRatio: 1.5,
      ),
    );

  }
}
