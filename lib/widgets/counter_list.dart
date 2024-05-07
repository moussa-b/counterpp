import 'package:counterpp/models/counter.dart';
import 'package:counterpp/widgets/counter_list_item.dart';
import 'package:flutter/material.dart';

class CounterList extends StatelessWidget {
  final List<Counter> counters;

  const CounterList({super.key, required this.counters});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemBuilder: (ctx, index) {
        final Counter counter = counters[index];
        final String keyValue = '${counter.id!}-${counter.lastModificationTimeStamp!}';
        return CounterListItem(
          key: ValueKey<String>(keyValue),
          counter: counter,
        );
      },
      itemCount: counters.length,
    );
  }
}
