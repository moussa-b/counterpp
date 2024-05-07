import 'package:counterpp/models/counter.dart';
import 'package:counterpp/providers/counter_repository_provider.dart';
import 'package:counterpp/repository/counter_repository.dart';
import 'package:counterpp/utils/utils.dart';
import 'package:counterpp/widgets/counter_progress.dart';
import 'package:counterpp/widgets/loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CounterWidget extends ConsumerStatefulWidget {
  final int counterId;

  final void Function(BuildContext context, void Function() resetCounter) builder;

  const CounterWidget({super.key, required this.counterId, required this.builder});

  @override
  ConsumerState<CounterWidget> createState() => _CounterWidgetState();
}

class _CounterWidgetState extends ConsumerState<CounterWidget> {
  int? _count;
  String? _color;
  String? _name;
  int? _limit;
  int? _id = 0;

  @override
  void initState() {
    super.initState();
    getCounter();
    widget.builder.call(context, () {
      ref.read(counterRepositoryProvider).resetCounterById(_id!).then((bool result) {
        if (result) {
          setState(() {
            _count = 0;
          });
        }
      });
    });
  }

  void getCounter() async {
    final CounterRepository counterRepository = ref.read(counterRepositoryProvider);
    final Counter counter = await counterRepository.getCounterById(widget.counterId);
    setState(() {
      _count = counter.counterCount ?? 0;
      _color = counter.color;
      _limit = counter.counterLimit;
      _name = counter.name;
      _id = counter.id;
    });
  }

  @override
  Widget build(BuildContext context) {
    final CounterRepository counterRepository = ref.read(counterRepositoryProvider);
    final isInfinite = _limit == null || _limit! <= 0;
    final limit = isInfinite ? 20 : _limit!;
    var progress = 0.0;
    if (_count != null) {
      if (!isInfinite) {
        if (_count! >= limit && _count! % limit == 0) {
          progress = 1;
        } else {
          progress = (_count! % limit) / limit;
        }
      } else {
        progress = (_count! % 20) / 20;
      }
    }
    Widget separator = SizedBox(height: MediaQuery.of(context).size.width * 0.05);
    String? color = _id == 1 ? '#${Theme.of(context).primaryColor.value.toRadixString(16)}' : _color ;
    return _count == null
        ? const LoadingIndicator()
        : Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_name != null && _name!.isNotEmpty)
                  ...[
                    Text(
                    _name!,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  separator
                ],
                if (_limit != null && _limit! > 0) ...[
                  Text(
                    '${AppLocalizations.of(context)!.objective} : $_limit',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  separator
                  ],
                CounterProgress(
                  color: color,
                  size: MediaQuery.of(context).size.width * 0.6,
                  circleWidth: MediaQuery.of(context).size.width * 0.05,
                  progress: progress,
                  isInfinite: isInfinite,
                  onTap: () {
                    setState(() {
                      _count = _count! + 1;
                      counterRepository.incrementCounterById(widget.counterId);
                    });
                  },
                  content: Text(
                    _count.toString(),
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width * 0.3,
                      color: Utils.hexToColor(color),
                    ),
                  ),
                ),
                separator,
                ElevatedButton(
                  onPressed: _count == 0 ? null : () {
                    setState(() {
                      _count = _count! - 1;
                      counterRepository.decrementCounterById(widget.counterId);
                    });
                  },
                  child: const Text('-1'),
                ),
              ],
            ),
          );
  }
}
