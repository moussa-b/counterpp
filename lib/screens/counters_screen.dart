import 'package:counter/l10n/app_localizations.dart';
import 'package:counter/models/counter.dart';
import 'package:counter/models/folder.dart';
import 'package:counter/models/settings.dart';
import 'package:counter/providers/counter_repository_provider.dart';
import 'package:counter/providers/counters_provider.dart';
import 'package:counter/providers/settings_provider.dart';
import 'package:counter/screens/counter_form_screen.dart';
import 'package:counter/widgets/counter_grid.dart';
import 'package:counter/widgets/counter_list.dart';
import 'package:counter/widgets/counters_popup_menu.dart';
import 'package:counter/widgets/editable_counter_grid.dart';
import 'package:counter/widgets/editable_counter_list.dart';
import 'package:counter/widgets/last_modified_counter.dart';
import 'package:counter/widgets/loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CountersScreen extends ConsumerStatefulWidget {
  final Folder folder;

  const CountersScreen({super.key, required this.folder});

  @override
  ConsumerState<CountersScreen> createState() => _CountersScreenState();
}

class _CountersScreenState extends ConsumerState<CountersScreen> {
  bool _editMode = false;

  @override
  void initState() {
    super.initState();
    _synchronizeCountersCount();
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    AsyncValue<Settings> settings = ref.watch(settingsProvider);
    AsyncValue<List<Counter>> counters = ref.watch(countersProvider);
    if (settings.isLoading || counters.isLoading) {
      content = const LoadingIndicator();
    }
    if (counters.value == null || counters.value!.isEmpty) {
      content = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppLocalizations.of(context)!.noCounter),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _addCounter(context),
              child: Text(AppLocalizations.of(context)!.createNewCounter),
            ),
          ],
        ),
      );
    } else {
      final bool showCounterGrid =
          settings.hasValue &&
          settings.value != null &&
          settings.value!.counterCompactView == true;
      content = Column(
        children: [
          const LastModifiedCounter(),
          if (!_editMode)
            Expanded(
              child: showCounterGrid
                  ? CounterGrid(
                      counters: counters.value!,
                      settings: settings.value!,
                    )
                  : CounterList(
                      counters: counters.value!,
                      settings: settings.value!,
                    ),
            ),
          if (_editMode)
            Expanded(
              child: showCounterGrid
                  ? EditableCounterGrid(counters: counters.value!)
                  : EditableCounterList(counters: counters.value!),
            ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.folder.name!),
        actions: [
          // IconButton(
          //   icon: const Icon(Icons.add),
          //   onPressed: () => _addCounter(context),
          // ),
          if (_editMode)
            IconButton(
              icon: const FaIcon(FontAwesomeIcons.checkDouble),
              onPressed: () {
                setState(() {
                  _editMode = false;
                });
              },
            ),
          if (!_editMode)
            IconButton(
              icon: const Icon(Icons.swap_vert),
              onPressed: () {
                setState(() {
                  _editMode = true;
                });
              },
            ),
          if (!_editMode) const CountersPopupMenu(),
        ],
        scrolledUnderElevation: 0.0,
      ),
      body: SafeArea(child: content),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addCounter(context),
        child: const FaIcon(FontAwesomeIcons.plus),
      ),
    );
  }

  void _addCounter(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) {
          return CounterFormScreen(currentFolder: widget.folder);
        },
      ),
    );
  }

  void _synchronizeCountersCount() {
    final int folderId = widget.folder.id!;
    ref.read(counterRepositoryProvider).synchronizeCountersCount(folderId);
  }
}
