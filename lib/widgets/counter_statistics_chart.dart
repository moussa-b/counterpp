import 'package:counter/models/calendar_period.dart';
import 'package:counter/models/statistics.dart';
import 'package:counter/utils/utils.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:counter/l10n/app_localizations.dart';

class CounterStatisticsChart extends StatelessWidget {
  final List<Statistics> statistics;
  final CalendarPeriod calendarPeriod;
  final DateTime selectedDate;

  const CounterStatisticsChart({
    super.key,
    required this.statistics,
    required this.calendarPeriod,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context) {
    if (statistics.isEmpty) {
      return Center(child: Text(AppLocalizations.of(context)!.noStatistics));
    }

    return BarChart(
      BarChartData(
        barGroups: barGroups,
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (double value, TitleMeta meta) =>
                  getTitlesWidget(context, value, meta),
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 30),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
      ),
    );
  }

  SideTitleWidget getTitlesWidget(
    BuildContext context,
    double value,
    TitleMeta meta,
  ) {
    switch (calendarPeriod) {
      case CalendarPeriod.day:
        return getTitlesWidgetForDay(value, meta);
      case CalendarPeriod.week:
        return getTitlesWidgetForWeek(context, value, meta);
      case CalendarPeriod.month:
        return getTitlesWidgetForMonth(value, meta);
      case CalendarPeriod.year:
        return getTitlesWidgetForYear(context, value, meta);
    }
  }

  List<BarChartGroupData> get barGroups {
    final List<int> increments = [];
    final List<int> decrements = [];
    final List<int> resets = [];
    switch (calendarPeriod) {
      case CalendarPeriod.day:
        for (int i = 0; i < 24; i += 2) {
          increments.add(0);
          decrements.add(0);
          resets.add(0);
        }
        break;
      case CalendarPeriod.week:
        for (int i = 0; i < 7; i++) {
          increments.add(0);
          decrements.add(0);
          resets.add(0);
        }
        break;
      case CalendarPeriod.month:
        {
          int daysInMonth = Utils.getDaysInMonth(selectedDate);
          for (int i = 1; i <= daysInMonth; i++) {
            final int index = getIndexWithLowerBound(i);
            if (index > (increments.length - 1)) {
              increments.add(0);
              decrements.add(0);
              resets.add(0);
            }
          }
        }
        break;
      case CalendarPeriod.year:
        for (int i = 0; i < 12; i++) {
          increments.add(0);
          decrements.add(0);
          resets.add(0);
        }
        break;
    }

    if (statistics.isNotEmpty) {
      for (Statistics stat in statistics) {
        if (stat.dateTimeStamp == null || stat.type == null) {
          continue;
        }
        int index;
        final DateTime statDateTime = DateTime.fromMillisecondsSinceEpoch(
          stat.dateTimeStamp!,
        );
        switch (calendarPeriod) {
          case CalendarPeriod.day:
            index = (statDateTime.hour / 2.0).floor();
            break;
          case CalendarPeriod.week:
            index = statDateTime.weekday - 1;
            break;
          case CalendarPeriod.month:
            index = getIndexWithLowerBound(statDateTime.day);
            break;
          case CalendarPeriod.year:
            index = statDateTime.month - 1;
            break;
        }
        switch (stat.type!) {
          case StatisticsType.DECREMENT:
            decrements[index] = decrements[index] + 1;
            break;
          case StatisticsType.INCREMENT:
            increments[index] = increments[index] + 1;
            break;
          case StatisticsType.RESET:
            resets[index] = resets[index] + 1;
            break;
        }
      }
    }
    final List<BarChartGroupData> datas = [];
    for (int i = 0; i < increments.length; i++) {
      datas.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: increments[i].toDouble(),
              width: 8,
              borderRadius: BorderRadius.zero,
              color: Colors.green,
            ),
            BarChartRodData(
              toY: decrements[i].toDouble(),
              width: 8,
              borderRadius: BorderRadius.zero,
              color: Colors.yellow,
            ),
            BarChartRodData(
              toY: resets[i].toDouble(),
              width: 8,
              borderRadius: BorderRadius.zero,
              color: Colors.red,
            ),
          ],
        ),
      );
    }
    return datas;
  }

  int getIndexWithLowerBound(int day) {
    // must match CounterStatisticsDataTable.getLowerBound
    int closestLowerBound;
    if (day > 30) {
      closestLowerBound = 28;
    } else if (day % 3 != 0) {
      closestLowerBound = 1 + 3 * (day / 3.0).floor();
    } else {
      closestLowerBound = day - 2;
    }
    return (closestLowerBound / 3.0).floor();
  }

  SideTitleWidget getTitlesWidgetForDay(double value, TitleMeta meta) {
    return SideTitleWidget(
      meta: meta,
      space: 4,
      child: Text('${(value.toInt() * 2).toString()}h'),
    );
  }

  SideTitleWidget getTitlesWidgetForWeek(
    BuildContext context,
    double value,
    TitleMeta meta,
  ) {
    String text;
    switch (value.toInt()) {
      case 0:
        text = AppLocalizations.of(context)!.shortDateMonday;
        break;
      case 1:
        text = AppLocalizations.of(context)!.shortDateTuesday;
        break;
      case 2:
        text = AppLocalizations.of(context)!.shortDateWednesday;
        break;
      case 3:
        text = AppLocalizations.of(context)!.shortDateThursday;
        break;
      case 4:
        text = AppLocalizations.of(context)!.shortDateFriday;
        break;
      case 5:
        text = AppLocalizations.of(context)!.shortDateSaturday;
        break;
      case 6:
        text = AppLocalizations.of(context)!.shortDateSunday;
        break;
      default:
        text = '';
        break;
    }
    return SideTitleWidget(meta: meta, space: 4, child: Text(text));
  }

  SideTitleWidget getTitlesWidgetForMonth(double value, TitleMeta meta) {
    return SideTitleWidget(
      meta: meta,
      space: 4,
      child: Text((1 + 3 * value.toInt()).toString()),
    );
  }

  SideTitleWidget getTitlesWidgetForYear(
    BuildContext context,
    double value,
    TitleMeta meta,
  ) {
    String text;
    switch (value.toInt()) {
      case 0:
        text = AppLocalizations.of(context)!.shortDateJanuary;
        break;
      case 1:
        text = AppLocalizations.of(context)!.shortDateFebruary;
        break;
      case 2:
        text = AppLocalizations.of(context)!.shortDateMarch;
        break;
      case 3:
        text = AppLocalizations.of(context)!.shortDateApril;
        break;
      case 4:
        text = AppLocalizations.of(context)!.shortDateMay;
        break;
      case 5:
        text = AppLocalizations.of(context)!.shortDateJune;
        break;
      case 6:
        text = AppLocalizations.of(context)!.shortDateJuly;
        break;
      case 7:
        text = AppLocalizations.of(context)!.shortDateAugust;
        break;
      case 8:
        text = AppLocalizations.of(context)!.shortDateSeptember;
        break;
      case 9:
        text = AppLocalizations.of(context)!.shortDateOctober;
        break;
      case 10:
        text = AppLocalizations.of(context)!.shortDateNovember;
        break;
      case 11:
        text = AppLocalizations.of(context)!.shortDateDecember;
        break;
      default:
        text = '';
        break;
    }
    return SideTitleWidget(meta: meta, space: 4, child: Text(text));
  }
}
