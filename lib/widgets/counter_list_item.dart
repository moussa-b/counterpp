import 'package:audioplayers/audioplayers.dart';
import 'package:counter/models/bottom_sheet_result.dart';
import 'package:counter/models/counter.dart';
import 'package:counter/models/settings.dart';
import 'package:counter/providers/counter_repository_provider.dart';
import 'package:counter/providers/last_modified_counter_provider.dart';
import 'package:counter/repository/counter_repository.dart';
import 'package:counter/screens/counter_screen.dart';
import 'package:counter/utils/utils.dart';
import 'package:counter/widgets/counter_bottom_sheet.dart';
import 'package:counter/widgets/counter_progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CounterListItem extends ConsumerStatefulWidget {
  final Counter counter;
  final bool active;
  final Settings? settings;

  const CounterListItem({super.key, required this.counter, this.active = true, this.settings});

  @override
  ConsumerState<CounterListItem> createState() => _CounterListItemState();
}

class _CounterListItemState extends ConsumerState<CounterListItem> {
  int _count = 0;

  @override
  void initState() {
    super.initState();
    _count = widget.counter.counterCount ?? 0;
  }

  void onSelectCounter(Counter counter) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) {
          return CounterScreen(counter: counter);
        },
      ),
    );
  }

  int getStep() {
    return widget.counter.step != null && widget.counter.step! > 0 ? widget.counter.step! : 1;
  }

  @override
  Widget build(BuildContext context) {
    final isInfinite = widget.counter.counterLimit == null || widget.counter.counterLimit! <= 0;
    final limit = isInfinite ? 20 : widget.counter.counterLimit!;
    double progress = 0.0;
    if (!isInfinite) {
      if (_count >= limit && _count % limit == 0) {
        progress = 1;
      } else {
        progress = (_count % limit) / limit;
      }
    } else {
      progress = (_count % 20) / 20;
    }

    final double infinityContainerSize = Theme.of(context).textTheme.titleLarge!.fontSize! + 8;
    const double size = 55; // can not be too big
    final bool activateVibrator = widget.settings?.activateVibrator ?? false;
    final bool activateSounds = widget.settings?.activateSounds ?? false;

    return Card(
      child: ListTile(
        title: Text(widget.counter.name!, style: Theme.of(context).textTheme.titleLarge,textAlign: TextAlign.center),
        subtitle: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(FontAwesomeIcons.minus),
              onPressed: _count <= 0 || !widget.active ? null : () {
                if (activateSounds) {
                  AudioPlayer().play(AssetSource('audio/decrease.mp3'));
                }
                if (activateVibrator) {
                  HapticFeedback.mediumImpact();
                }
                setState(() {
                  _count = _count - getStep();
                  final CounterRepository counterRepository = ref.read(counterRepositoryProvider);
                  counterRepository.decrementCounterById(widget.counter.id!);
                  ref.read(lastModifiedCounterProvider.notifier).refresh();
                });
              },
            ),
            Text(_count.toString(), style: Theme.of(context).textTheme.titleLarge,),
            IconButton(
              icon: const Icon(FontAwesomeIcons.plus),
              onPressed: !widget.active ? null : () {
                if (activateSounds) {
                  AudioPlayer().play(AssetSource('audio/increase.mp3'));
                }
                if (activateVibrator) {
                  HapticFeedback.mediumImpact();
                }
                setState(() {
                  _count = _count + getStep();
                  final CounterRepository counterRepository = ref.read(counterRepositoryProvider);
                  counterRepository.incrementCounterById(widget.counter.id!);
                  ref.read(lastModifiedCounterProvider.notifier).refresh();
                });
              },
            ),
          ],
        ),
        onTap: !widget.active ? null : () => onSelectCounter(widget.counter),
        leading: CounterProgress(
          color: widget.counter.color,
          size: size,
          circleWidth: size * 0.05,
          progress: progress,
          isInfinite: isInfinite,
          onTap: () {
            if (widget.active) {
              onSelectCounter(widget.counter);
            }
          },
          content: isInfinite
              ? SizedBox(
              width: infinityContainerSize,
              height: infinityContainerSize,
              child: Icon(
                FontAwesomeIcons.infinity,
                color: Utils.hexToColor(widget.counter.color),
                size: Theme.of(context).textTheme.titleMedium!.fontSize! + 4,
              ))
              : Text(
            _count.toString(),
            style: TextStyle(
                color: Utils.hexToColor(widget.counter.color),
                fontSize:
                Theme.of(context).textTheme.titleLarge!.fontSize),
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: !widget.active ? null : () async {
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
        ),
      ),
    );
  }
}
