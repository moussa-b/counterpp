import 'package:counterpp/models/bottom_sheet_result.dart';
import 'package:counterpp/models/counter.dart';
import 'package:counterpp/providers/counter_repository_provider.dart';
import 'package:counterpp/providers/last_modified_counter_provider.dart';
import 'package:counterpp/repository/counter_repository.dart';
import 'package:counterpp/utils/utils.dart';
import 'package:counterpp/widgets/counter_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CounterGridItem extends ConsumerStatefulWidget {
  final Counter counter;
  final bool active;

  const CounterGridItem({super.key, required this.counter, this.active = true});

  @override
  ConsumerState<CounterGridItem> createState() => _CounterGridItemState();
}

class _CounterGridItemState extends ConsumerState<CounterGridItem> {
  int _count = 0;

  @override
  void initState() {
    super.initState();
    _count = widget.counter.counterCount ?? 0;
  }

  int getStep() {
    return widget.counter.step != null && widget.counter.step! > 0 ? widget.counter.step! : 1;
  }

  @override
  Widget build(BuildContext context) {
    final Color color = Utils.hexToColor(widget.counter.color!);
    return Material(
      child: InkWell(
        onTap: !widget.active ? null : () {
          setState(() {
            _count = _count + getStep();
            final CounterRepository counterRepository = ref.read(counterRepositoryProvider);
            counterRepository.incrementCounterById(widget.counter.id!);
            ref.read(lastModifiedCounterProvider.notifier).refresh();
          });
        },
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(8.0, 0, 0, 0),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.counter.name!,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize:
                          Theme.of(context).textTheme.titleLarge!.fontSize!,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      alignment: Alignment.centerRight,
                      child: MaterialButton(
                        minWidth: 0,
                        onPressed: () async {
                          if (!widget.active) {
                            return;
                          }
                          BottomSheetAction? value = await showModalBottomSheet<BottomSheetAction?>(
                            context: context,
                            builder: (BuildContext context) {
                              return CounterBottomSheet(counter: widget.counter);
                            },
                          );
                          if (value == BottomSheetAction.reset) {
                            setState(() {
                              _count = 0;
                            });
                          }
                        },
                        color: Colors.white,
                        textColor: color,
                        shape: const CircleBorder(),
                        child: const Icon(
                          FontAwesomeIcons.ellipsisVertical,
                        ),
                      ),
                    ),
                  )
                ],
              ),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${_count}',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: Theme.of(context).textTheme.titleLarge!.fontSize! + 15,
                      ),
                    ),
                    if (widget.counter.counterLimit != null && widget.counter.counterLimit! > 0)
                      Text(
                        '/${widget.counter.counterLimit!}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize:
                          Theme.of(context).textTheme.titleMedium!.fontSize! + 15,
                        ),
                      )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
