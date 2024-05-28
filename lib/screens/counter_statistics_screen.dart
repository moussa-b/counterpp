import 'package:counterpp/models/calendar_period.dart';
import 'package:counterpp/models/counter.dart';
import 'package:counterpp/models/statistics.dart';
import 'package:counterpp/providers/counter_repository_provider.dart';
import 'package:counterpp/utils/utils.dart';
import 'package:counterpp/widgets/counter_statistics_chart.dart';
import 'package:counterpp/widgets/counter_statistics_data_table.dart';
import 'package:counterpp/widgets/loading_indicator.dart';
import 'package:counterpp/widgets/period_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class CounterStatisticsScreen extends ConsumerStatefulWidget {
  final Counter counter;

  const CounterStatisticsScreen({super.key, required this.counter});

  @override
  ConsumerState<CounterStatisticsScreen> createState() =>
      _CounterStatisticsScreenState();
}

class _CounterStatisticsScreenState extends ConsumerState<CounterStatisticsScreen> {
  CalendarPeriod _calendarPeriod = CalendarPeriod.day;
  DateTime _selectedDate = DateTime.now();
  List<Statistics>? _statistics;

  @override
  void initState() {
    super.initState();
    getCounterStatistics();
  }

  void getCounterStatistics() async {
    DateTime start;
    DateTime end;
    switch(_calendarPeriod) {
      case CalendarPeriod.day:
        final DateTime startDate = _selectedDate;
        start = DateTime(startDate.year, startDate.month, startDate.day, 0, 0, 0);
        end = DateTime(startDate.year, startDate.month, startDate.day, 23, 59, 59);
        break;
      case CalendarPeriod.week:
        final DateTime startDate = Utils.getFirstDayOfWeek(_selectedDate);
        final DateTime endDate = Utils.getLastDayOfWeek(_selectedDate);
        start = DateTime(startDate.year, startDate.month, startDate.day, 0, 0, 0);
        end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
        break;
      case CalendarPeriod.month:
        final DateTime startDate = Utils.getFirstDayOfMonth(_selectedDate);
        final DateTime endDate = Utils.getLastDayOfMonth(_selectedDate);
        start = DateTime(startDate.year, startDate.month, startDate.day, 0, 0, 0);
        end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
        break;
      case CalendarPeriod.year:
        final DateTime startDate = Utils.getFirstDayOfYear(_selectedDate);
        final DateTime endDate = Utils.getLastDayOfYear(_selectedDate);
        start = DateTime(startDate.year, startDate.month, startDate.day, 0, 0, 0);
        end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
        break;
    }
    final List<Statistics> statistics = await ref.read(counterRepositoryProvider).getCounterStatistics(widget.counter.id!, start, end);
    setState(() {
      _statistics = statistics;
    });
  }

  String get textButtonLabel {
    switch (_calendarPeriod) {
      case CalendarPeriod.day:
        return DateFormat('dd MMMM yyyy', Localizations.localeOf(context).languageCode).format(_selectedDate);
      case CalendarPeriod.week:
        {
          final DateTime firstDayOfWeek = Utils.getFirstDayOfWeek(_selectedDate);
          final DateTime lastDayOfWeek = Utils.getLastDayOfWeek(_selectedDate);
          final String firstDayOfWeekStr = DateFormat('dd MMMM yyyy', Localizations.localeOf(context).languageCode).format(firstDayOfWeek);
          final String lastDayOfWeekStr = DateFormat('dd MMMM yyyy', Localizations.localeOf(context).languageCode).format(lastDayOfWeek);
          return '$firstDayOfWeekStr - $lastDayOfWeekStr';
        }
      case CalendarPeriod.month:
        {
          final DateTime firstDayOfMonth = Utils.getFirstDayOfMonth(_selectedDate);
          final DateTime lastDayOfMonth = Utils.getLastDayOfMonth(_selectedDate);
          final String firstDayOfMonthStr = DateFormat('dd MMMM yyyy', Localizations.localeOf(context).languageCode).format(firstDayOfMonth);
          final String lastDayOfMonthStr = DateFormat('dd MMMM yyyy', Localizations.localeOf(context).languageCode).format(lastDayOfMonth);
          return '$firstDayOfMonthStr - $lastDayOfMonthStr';
        }
      case CalendarPeriod.year:
        {
          final DateTime firstDayOfYear = Utils.getFirstDayOfYear(_selectedDate);
          final DateTime lastDayOfYear = Utils.getLastDayOfYear(_selectedDate);
          final String firstDayOfYearStr = DateFormat('dd MMMM yyyy', Localizations.localeOf(context).languageCode).format(firstDayOfYear);
          final String lastDayOfYearStr = DateFormat('dd MMMM yyyy', Localizations.localeOf(context).languageCode).format(lastDayOfYear);
          return '$firstDayOfYearStr - $lastDayOfYearStr';
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> content = [];
    if (_statistics == null) {
      content.add(const Expanded(child: Center(child: LoadingIndicator())));
    } else if (_statistics!.isEmpty) {
      content.add(Expanded(
          child: Center(
              child: Text(
        AppLocalizations.of(context)!.noStatistics,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: Theme.of(context).textTheme.titleLarge!.fontSize!,
        ),
      ))));
    } else {
      content.add(Expanded(
        flex: 1,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
          child: CounterStatisticsChart(
            statistics: _statistics != null ? _statistics! : [],
            calendarPeriod: _calendarPeriod,
            selectedDate: _selectedDate,
          ),
        ),
      ));
      content.add(
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: SingleChildScrollView(
                child: SizedBox(
                  width: double.infinity,
                  child: CounterStatisticsDataTable(
                    statistics: _statistics != null ? _statistics! : [],
                    calendarPeriod: _calendarPeriod,
                    selectedDate: _selectedDate,
                  ),
                ),
              ),
            ),
          ));
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!
            .counterStatistics(widget.counter.name!)),
        scrolledUnderElevation: 0.0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Center(
              child: PeriodSelector(
                onPeriodChange: (CalendarPeriod calendarPeriod) =>
                    setState(() {
                      _calendarPeriod = calendarPeriod;
                      _statistics = null;
                      getCounterStatistics();
                    }),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() {
                      switch(_calendarPeriod) {
                        case CalendarPeriod.day:
                          _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                          break;
                        case CalendarPeriod.week:
                          _selectedDate = _selectedDate.subtract(const Duration(days: 7));
                          break;
                        case CalendarPeriod.month:
                          _selectedDate = _selectedDate.subtract(Duration(days: Utils.getDaysInMonth(_selectedDate)));
                          break;
                        case CalendarPeriod.year:
                          _selectedDate = DateTime(_selectedDate.year - 1, _selectedDate.month, _selectedDate.day);
                          break;
                      }
                      _statistics = null;
                      getCounterStatistics();
                    });
                  },
                ),
                Expanded(
                  child: Center(
                    child: TextButton(
                      onPressed: () async {
                        DateTime? selectedDate = await showDatePicker(
                          // initialDatePickerMode: DatePickerMode.year,
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(DateTime.now().year - 3),
                            lastDate: DateTime(DateTime.now().year + 1));
                        if (selectedDate != null) {
                          setState(() {
                            _selectedDate = selectedDate;
                            _statistics = null;
                            getCounterStatistics();
                          });
                        }
                      },
                      child: Text(textButtonLabel),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    setState(() {
                      switch(_calendarPeriod) {
                        case CalendarPeriod.day:
                          _selectedDate = _selectedDate.add(const Duration(days: 1));
                          break;
                        case CalendarPeriod.week:
                          _selectedDate = _selectedDate.add(const Duration(days: 7));
                          break;
                        case CalendarPeriod.month:
                          _selectedDate = _selectedDate.add(Duration(days: Utils.getDaysInMonth(_selectedDate)));
                          break;
                        case CalendarPeriod.year:
                          _selectedDate = DateTime(_selectedDate.year + 1, _selectedDate.month, _selectedDate.day);
                          break;
                      }
                      _statistics = null;
                      getCounterStatistics();
                    });
                  },
                ),
              ],
            ),
            ...content
          ],
        ),
      ),
    );
  }
}
