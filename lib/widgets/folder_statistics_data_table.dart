import 'package:counter/models/counter.dart';
import 'package:flutter/material.dart';
import 'package:counter/l10n/app_localizations.dart';

class FolderStatisticsDataTable extends StatelessWidget {
  const FolderStatisticsDataTable({super.key, required this.counters});

  final List<Counter> counters;

  @override
  Widget build(BuildContext context) {
    return DataTable(
      headingRowColor: WidgetStateColor.resolveWith(
        (states) => Theme.of(context).primaryColor,
      ),
      columns: <DataColumn>[
        DataColumn(
          label: Text(
            AppLocalizations.of(context)!.counterName,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        DataColumn(
          label: Text(
            AppLocalizations.of(context)!.value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
      rows: counters.map((Counter counter) {
        return DataRow(
          cells: <DataCell>[
            DataCell(Text(counter.name!)),
            DataCell(Text(counter.counterCount!.toString())),
          ],
        );
      }).toList(),
    );
  }
}
