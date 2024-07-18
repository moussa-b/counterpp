import 'package:counterpp/models/calendar_period.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PeriodSelector extends StatefulWidget {
  final void Function(CalendarPeriod calendarPeriod)? onPeriodChange;
  
  const PeriodSelector({super.key, this.onPeriodChange});

  @override
  State<PeriodSelector> createState() => _PeriodSelectorState();
}

class _PeriodSelectorState extends State<PeriodSelector> {
  CalendarPeriod calendarView = CalendarPeriod.day;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<CalendarPeriod>(
      segments: <ButtonSegment<CalendarPeriod>>[
        ButtonSegment<CalendarPeriod>(
          value: CalendarPeriod.day,
          label: Text(
            AppLocalizations.of(context)!.day,
            overflow: TextOverflow.ellipsis,
          ),
          icon: const Icon(Icons.calendar_view_day),
        ),
        ButtonSegment<CalendarPeriod>(
          value: CalendarPeriod.week,
          label: Text(
            AppLocalizations.of(context)!.week,
            overflow: TextOverflow.ellipsis,
          ),
          icon: const Icon(Icons.calendar_view_week),
        ),
        ButtonSegment<CalendarPeriod>(
          value: CalendarPeriod.month,
          label: Text(
            AppLocalizations.of(context)!.month,
            overflow: TextOverflow.ellipsis,
          ),
          icon: const Icon(Icons.calendar_view_month),
        ),
        ButtonSegment<CalendarPeriod>(
          value: CalendarPeriod.year,
          label: Text(
            AppLocalizations.of(context)!.year,
            overflow: TextOverflow.ellipsis,
          ),
          icon: const Icon(Icons.calendar_today),
        ),
      ],
      selected: <CalendarPeriod>{calendarView},
      onSelectionChanged: (Set<CalendarPeriod> newSelection) {
        setState(() {
          calendarView = newSelection.first;
          if (widget.onPeriodChange != null) {
            widget.onPeriodChange!(calendarView);
          }
        });
      },
    );
  }
}
