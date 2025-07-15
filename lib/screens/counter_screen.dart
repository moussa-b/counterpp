import 'package:counterpp/models/counter.dart';
import 'package:counterpp/providers/counters_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/counter_widget.dart';

class CounterScreen extends ConsumerStatefulWidget {

  const CounterScreen({super.key, required this.counter});

  final Counter counter;

  @override
  ConsumerState<CounterScreen> createState() => _CounterScreenState();
}

class _CounterScreenState extends ConsumerState<CounterScreen> {
  void Function()? _resetCounter;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        ref.read(countersProvider.notifier).refresh();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.counter.name!),
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.settings_backup_restore),
              onPressed: () {
                if (_resetCounter != null) {
                  _resetCounter!.call();
                }
              },
            )
          ],
        ),
        body: SafeArea(
          child: CounterWidget(
            counterId: widget.counter.id!,
            builder: (BuildContext context, void Function() resetCounter) {
              _resetCounter = resetCounter;
            },
          ),
        ),
      ),
    );
  }
}
