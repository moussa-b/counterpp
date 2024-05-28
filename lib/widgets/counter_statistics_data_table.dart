import 'package:counterpp/models/calendar_period.dart';
import 'package:counterpp/models/statistics.dart';
import 'package:counterpp/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class CounterStatisticsDataTable extends ConsumerWidget {
  final List<Statistics> statistics;
  final CalendarPeriod calendarPeriod;
  final DateTime selectedDate;

  const CounterStatisticsDataTable({super.key, required this.statistics, required this.calendarPeriod, required this.selectedDate });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Map<String, Map<StatisticsType, int>> groupedStatistics = getGroupedStatistics();
    final List<DataRow> rows = [];
    for (var entry in groupedStatistics.entries) {
      if (entry.value[StatisticsType.INCREMENT] != null && entry.value[StatisticsType.INCREMENT]! > 0) {
        rows.add(DataRow(cells: [
          DataCell(Text(entry.key)),
          DataCell(Text(getStatisticsTypeLabel(context, StatisticsType.INCREMENT))),
          DataCell(Text(entry.value[StatisticsType.INCREMENT].toString())),
        ]));
      }
      if (entry.value[StatisticsType.DECREMENT] != null && entry.value[StatisticsType.DECREMENT]! > 0) {
        rows.add(DataRow(cells: [
          DataCell(Text(entry.key)),
          DataCell(Text(getStatisticsTypeLabel(context, StatisticsType.DECREMENT))),
          DataCell(Text(entry.value[StatisticsType.DECREMENT].toString())),
        ]));
      }
      if (entry.value[StatisticsType.RESET] != null && entry.value[StatisticsType.RESET]! > 0) {
        rows.add(DataRow(cells: [
          DataCell(Text(entry.key)),
          DataCell(Text(getStatisticsTypeLabel(context, StatisticsType.RESET))),
          DataCell(Text(entry.value[StatisticsType.RESET].toString())),
        ]));
      }
    }

    if (rows.isEmpty) {
      return Center(child: Text(AppLocalizations.of(context)!.noStatistics));
    }

    return DataTable(
      headingRowColor: MaterialStateColor.resolveWith((states) => Theme.of(context).primaryColor),
      columns: <DataColumn>[
        DataColumn(
          label: Text(
            AppLocalizations.of(context)!.date,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        DataColumn(
          label: Text(
            AppLocalizations.of(context)!.type,
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
      rows: rows
    );
  }

  String getStatisticsTypeLabel(BuildContext context, StatisticsType type) {
    switch (type) {
      case StatisticsType.DECREMENT:
        return AppLocalizations.of(context)!.decrement;
      case StatisticsType.INCREMENT:
        return AppLocalizations.of(context)!.increment;
      case StatisticsType.RESET:
        return AppLocalizations.of(context)!.resetName;
    }
  }

  String formatDate(DateTime date) {
    switch (calendarPeriod) {
      case CalendarPeriod.day:
        return DateFormat('HH:mm').format(date);
      case CalendarPeriod.week:
        return DateFormat('EEE dd MMM yy').format(date);
      case CalendarPeriod.month:
        return DateFormat('dd MMM yy').format(date);
      case CalendarPeriod.year:
        return DateFormat('MMM yyyy').format(date);
    }
  }

  Map<String, Map<StatisticsType, int>> getGroupedStatistics() {
    final Map<String, Map<StatisticsType, int>> groupedStatistics = {};
    if (statistics.isNotEmpty) {
      for (Statistics statistics in statistics) {
        final String key = getStatisticsGroupKey(statistics);
        if (groupedStatistics[key] == null) {
          groupedStatistics[key] = {};
        }
        if (groupedStatistics[key]![statistics.type!] == null) {
          groupedStatistics[key]![statistics.type!] = 0;
        }
        groupedStatistics[key]![statistics.type!] = groupedStatistics[key]![statistics.type!]! + 1;
      }
    }
    return groupedStatistics;
  }

  String getStatisticsGroupKey(Statistics statistics) {
    final DateTime statDate = DateTime.fromMillisecondsSinceEpoch(statistics.dateTimeStamp!);
    switch (calendarPeriod) {
      case CalendarPeriod.day:
        {
          final int hour = statDate.hour;
          if (hour % 2 == 0) {
            return formatDate(DateTime(statDate.year, statDate.month, statDate.day, statDate.hour, 0));
          } else {
            int closestHourDivisibleBy2 = 2 * (hour / 2.0).floor();
            DateTime closestDateDivisibleBy2 = DateTime(statDate.year, statDate.month, statDate.day, closestHourDivisibleBy2, 0);
            return formatDate(closestDateDivisibleBy2);
          }
        }
      case CalendarPeriod.week:
      {
        return formatDate(statDate);
      }
      case CalendarPeriod.month:
      {
        final int day = statDate.day;
        if (day % 3 == 0) {
          return '$day - ${formatDate(statDate.add(const Duration(days: 2)))}';
        } else {
          final int closestDayDivisibleBy3 = 3 * (day / 3.0).floor();
          DateTime closestDateDivisibleBy3 = DateTime(statDate.year, statDate.month, closestDayDivisibleBy3);
          return '${closestDateDivisibleBy3.day} - ${formatDate(closestDateDivisibleBy3.add(const Duration(days: 2)))}';
        }
      }
      case CalendarPeriod.year:
        {
          final DateTime startOfMonth = Utils.getFirstDayOfMonth(statDate);
          return formatDate(startOfMonth);
        }
    }
  }
}
