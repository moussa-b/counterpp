import 'package:counterpp/models/counter.dart';
import 'package:counterpp/models/folder.dart';
import 'package:counterpp/providers/counters_provider.dart';
import 'package:counterpp/widgets/folder_statistics_chart.dart';
import 'package:counterpp/widgets/folder_statistics_data_table.dart';
import 'package:counterpp/widgets/loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FolderStatisticsScreen extends ConsumerStatefulWidget {
  final Folder folder;

  const FolderStatisticsScreen({super.key, required this.folder});

  @override
  ConsumerState<FolderStatisticsScreen> createState() => _FolderStatisticsScreenState();
}

class _FolderStatisticsScreenState extends ConsumerState<FolderStatisticsScreen> {

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Counter>> counters = ref.watch(countersProvider);
    Widget content;
    if (counters.isLoading) {
      content = const LoadingIndicator();
    } if (counters.value == null || counters.value!.isEmpty) {
      content = Center(
        child: Text(AppLocalizations.of(context)!.noCounter),
      );
    } else {
      content = Column(
        children: [
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
              child: FolderStatisticsChart(counters: counters.value!),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: SingleChildScrollView(
                child: SizedBox(
                  width: double.infinity,
                  child: FolderStatisticsDataTable(counters: counters.value!),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.statistics),
        scrolledUnderElevation: 0.0,
      ),
      body: SafeArea(
        child: content,
      ),
    );
  }
}
