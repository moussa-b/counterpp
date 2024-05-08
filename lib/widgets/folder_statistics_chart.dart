import 'package:counterpp/models/counter.dart';
import 'package:counterpp/utils/utils.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class FolderStatisticsChart extends StatelessWidget {
  final List<Counter> counters;

  const FolderStatisticsChart({super.key, required this.counters});

  List<PieChartSectionData> getChartSections(List<Counter> counters) {
    final isTouched = false;
    final fontSize = isTouched ? 25.0 : 16.0;
    final radius = isTouched ? 60.0 : 50.0;
    final int total = counters
        .map((Counter counter) => counter.counterCount!)
        .reduce((a, b) => a + b);
    const shadows = [Shadow(color: Colors.black, blurRadius: 2)];
    return counters.map((Counter counter) {
      return PieChartSectionData(
          color: Utils.hexToColor(counter.color!),
          value: (100.0 * counter.counterCount! / total).roundToDouble(),
          title: counter.name,
          radius: radius,
          titleStyle: TextStyle(
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
      crossAxisCount: counters.length > 5 ? 5 : counters.length,
      childAspectRatio: 4,
      children: counters
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
          flex: 4,
          child: PieChart(
            PieChartData(sections: getChartSections(counters)),
          ),
        ),
        Expanded(child: legend)
      ],
    );
  }
}
