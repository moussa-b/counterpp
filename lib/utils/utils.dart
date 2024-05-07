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
}
