import 'package:counter/models/counter.dart';
import 'package:counter/utils/utils.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class FolderStatisticsChart extends StatelessWidget {
  final List<Counter> counters;

  const FolderStatisticsChart({super.key, required this.counters});

  List<PieChartSectionData> getChartSections(List<Counter> counters) {
    const fontSize = 16.0;
    const radius = 50.0;
    final int total = counters
        .map((Counter counter) => counter.counterCount!)
        .reduce((a, b) => a + b);
    const shadows = [Shadow(color: Colors.black, blurRadius: 2)];
    return counters
        .where((Counter counter) => counter.counterCount != null && counter.counterCount! > 0)
        .map((Counter counter) {
      return PieChartSectionData(
          color: Utils.hexToColor(counter.color!),
          value: (100.0 * counter.counterCount! / total).roundToDouble(),
          title: counter.name,
          radius: radius,
          titleStyle: const TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: shadows,
          ));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final GridView legend = GridView.count(
      shrinkWrap: true,
      crossAxisCount: counters.length > 5 ? 5 : counters.length,
      childAspectRatio: 4,
      children: counters
          .where((Counter counter) => counter.counterCount != null && counter.counterCount! > 0)
          .map((Counter counter) =>
          Row(
                children: [
                  Container(
                    width: 12.0,
                    height: 12.0,
                    decoration: BoxDecoration(color: Utils.hexToColor(counter.color!)),
                  ),
                  const SizedBox(width: 4),
                  Text(counter.name!),
                ],
              ))
          .toList(),
    );

    return Column(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(sections: getChartSections(counters)),
          ),
        ),
        const SizedBox(height: 8),
        legend
      ],
    );
  }
}
