import 'dart:math';

import 'package:counterpp/models/counter.dart';
import 'package:counterpp/models/statistics.dart';
import 'package:counterpp/repository/counter_repository.dart';
import 'package:counterpp/utils/utils.dart';

class TestUtils {

  void generateRandomStatistics(CounterRepository counterRepository, int folderId, DateTime selectedDate) async {
    List<Counter> counters = await counterRepository.getCountersByFolderId(folderId);
    counters.forEach((counter) {
      // generateRandomStatisticsForDay(counter.id!, widget.selectedDate, 10);
      // generateRandomStatisticsForWeek(counter.id!, widget.selectedDate);
      generateRandomStatisticsForMonth(counterRepository, counter.id!, selectedDate);
      // generateRandomStatisticsForYear(counter.id!, widget.selectedDate);
    });
  }

  void generateRandomStatisticsForDay(CounterRepository counterRepository, int counterId, DateTime selectedDate, int nbStats) async {
    final Random random = Random();
    for (int i = 0; i < nbStats; i++) {
      final DateTime randomDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, random.nextInt(24), random.nextInt(60));
      await counterRepository.addStatistics(Statistics.fromJson({
        'counterId': counterId,
        'type': getRandomStatisticsType(),
        'dateTimeStamp': randomDate.millisecondsSinceEpoch
      }));
    }
  }

  void generateRandomStatisticsForWeek(CounterRepository counterRepository, int counterId, DateTime selectedDate) async {
    DateTime firstDayOfWeek = Utils.getFirstDayOfWeek(selectedDate);
    for (int i = 0; i < 7; i++) {
      generateRandomStatisticsForDay(counterRepository, counterId, firstDayOfWeek.add(Duration(days: i)), 5);
    }
  }

  void generateRandomStatisticsForMonth(CounterRepository counterRepository, int counterId, DateTime selectedDate) async {
    DateTime firstDayOfMonth = Utils.getFirstDayOfMonth(selectedDate);
    for (int i = 0; i < 4; i++) {
      generateRandomStatisticsForWeek(counterRepository, counterId, firstDayOfMonth.add(Duration(days: 7 * i)));
    }
  }

  void generateRandomStatisticsForYear(CounterRepository counterRepository, int counterId, DateTime selectedDate) async {
    int year = selectedDate.year;
    for (int i = 1; i <= 12; i++) {
      generateRandomStatisticsForMonth(counterRepository, counterId, DateTime(year, i, 1));
    }
  }

  String getRandomStatisticsType() {
    final Random random = Random();
    const types = StatisticsType.values;
    final randomIndex = random.nextInt(types.length);
    return types[randomIndex].name;
  }
}
