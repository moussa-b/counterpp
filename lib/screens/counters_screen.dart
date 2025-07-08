import 'package:counterpp/l10n/app_localizations.dart';
import 'package:counterpp/models/counter.dart';
import 'package:counterpp/models/folder.dart';
import 'package:counterpp/models/settings.dart';
import 'package:counterpp/providers/counter_repository_provider.dart';
import 'package:counterpp/providers/counters_provider.dart';
import 'package:counterpp/providers/settings_provider.dart';
import 'package:counterpp/screens/counter_form_screen.dart';
import 'package:counterpp/widgets/counter_grid.dart';
import 'package:counterpp/widgets/counter_list.dart';
import 'package:counterpp/widgets/counters_popup_menu.dart';
import 'package:counterpp/widgets/editable_counter_grid.dart';
import 'package:counterpp/widgets/editable_counter_list.dart';
import 'package:counterpp/widgets/last_modified_counter.dart';
import 'package:counterpp/widgets/loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CountersScreen extends ConsumerStatefulWidget {
  final Folder folder;

  const CountersScreen({super.key, required this.folder});

  @override
  ConsumerState<CountersScreen> createState() => _CountersScreenState();
}

class _CountersScreenState extends ConsumerState<CountersScreen>{
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
    } if (counters.value == null || counters.value!.isEmpty) {
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
      final bool showCounterGrid = settings.hasValue && settings.value != null && settings.value!.counterCompactView == true;
      content = Column(
        children: [
          const LastModifiedCounter(),
          if (!_editMode)
            Expanded(
              child: showCounterGrid
                  ? CounterGrid(counters: counters.value!, settings: settings.value!)
                  : CounterList(counters: counters.value!, settings: settings.value!),
            ),
          if (_editMode)
            Expanded(
              child: showCounterGrid
                  ? EditableCounterGrid(counters: counters.value!)
                  : EditableCounterList(counters: counters.value!),
            )
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
              icon: const Icon(FontAwesomeIcons.checkDouble),
              onPressed: () {
                setState(() {
                  _editMode = false;
                });
              },
            ),
          if (!_editMode)
            IconButton(
              icon: const Icon(FontAwesomeIcons.penToSquare),
              onPressed: () {
                setState(() {
                  _editMode = true;
                });
              },
            ),
          if (!_editMode) const CountersPopupMenu()
        ],
        scrolledUnderElevation: 0.0,
      ),
      body: SafeArea(
          child: content,
        ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addCounter(context),
        child: const Icon(FontAwesomeIcons.plus),
      ),
    );
  }

  void _addCounter(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (ctx) {
      return CounterFormScreen(currentFolder: widget.folder);
    }));
  }

  void _synchronizeCountersCount() {
    final int folderId = widget.folder.id!;
    ref.read(counterRepositoryProvider).synchronizeCountersCount(folderId);
  }
}
