import 'dart:ui';

import 'package:flutter/material.dart';

class Utils {
  static Color hexToColor(String? color, {Color? defaultColor}) {
    if (color != null && color.isNotEmpty) {
      color = color.replaceAll("#", "");
      if (color.length == 6) {
        color = "FF$color";
      }

      if (color.length == 8) {
        return Color(int.parse("0x$color"));
      }
    }
    return defaultColor ?? hexToColor('#ff2196f3'); // blue
  }

  static int getNumberOfDaysInMonth(int year, int month) {
    final DateTime lastDayOfMonth = DateTime(
      year,
      month + 1,
      1,
    ).subtract(const Duration(days: 1));
    return lastDayOfMonth.day;
  }

  static DateTime getFirstDayOfWeek(DateTime date) {
    int daysUntilFirstDay = date.weekday - 1;
    return date.subtract(Duration(days: daysUntilFirstDay));
  }

  static DateTime getLastDayOfWeek(DateTime date) {
    int daysUntilLastDay = DateTime.daysPerWeek - date.weekday;
    return date.add(Duration(days: daysUntilLastDay));
  }

  static DateTime getFirstDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  static DateTime getLastDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }

  static DateTime getFirstDayOfYear(DateTime date) {
    return DateTime(date.year, 1, 1);
  }

  static DateTime getLastDayOfYear(DateTime date) {
    return DateTime(date.year, 12, 31);
  }

  static int getDaysInMonth(DateTime date) {
    DateTime firstDayOfNextMonth = DateTime(date.year, date.month + 1, 1);
    DateTime lastDayOfMonth = firstDayOfNextMonth.subtract(
      const Duration(days: 1),
    );
    return lastDayOfMonth.day;
  }
}
