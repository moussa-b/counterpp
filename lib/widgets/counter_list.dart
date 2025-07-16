import 'package:counter/models/counter.dart';
import 'package:counter/models/settings.dart';
import 'package:counter/widgets/counter_list_item.dart';
import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class CounterList extends StatelessWidget {
  final List<Counter> counters;
  final Settings settings;

  CounterList({super.key, required this.counters, required this.settings}) {
    WakelockPlus.enabled.then((bool wakelockEnabled) {
      if (settings.keepScreenOn != null && settings.keepScreenOn != wakelockEnabled) {
        WakelockPlus.toggle(enable: settings.keepScreenOn!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemBuilder: (ctx, index) {
        final Counter counter = counters[index];
        final String keyValue = '${counter.id!}-${counter.lastModificationTimeStamp ?? counter.creationTimeStamp!}';
        return CounterListItem(
          key: ValueKey<String>(keyValue),
          counter: counter,
          settings: settings,
        );
      },
      itemCount: counters.length,
    );
  }
}
