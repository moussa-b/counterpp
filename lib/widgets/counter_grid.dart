import 'package:counter/models/counter.dart';
import 'package:counter/models/settings.dart';
import 'package:counter/widgets/counter_grid_item.dart';
import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class CounterGrid extends StatelessWidget {
  final List<Counter> counters;
  final Settings settings;

  CounterGrid({super.key, required this.counters, required this.settings}) {
    WakelockPlus.enabled.then((bool wakelockEnabled) {
          if (settings.keepScreenOn != null && settings.keepScreenOn != wakelockEnabled) {
            WakelockPlus.toggle(enable: settings.keepScreenOn!);
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 8.0),
      itemBuilder: (ctx, index) {
        final Counter counter = counters[index];
        final String keyValue =
            '${counter.id!}-${counter.lastModificationTimeStamp ?? counter.creationTimeStamp!}';
        return CounterGridItem(
          key: ValueKey<String>(keyValue),
          counter: counter,
          settings: settings
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
