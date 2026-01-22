import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class TimeFormat {
  static String getFormattedTime({
    required BuildContext context,
    required String? time,
  }) {
    DateTime dt = DateTime.parse(time!);
    DateTime now = DateTime.now();


    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime yesterday = today.subtract(const Duration(days: 1));
    DateTime dateOnly = DateTime(dt.year, dt.month, dt.day);

    // Today - return time
    if (dateOnly == today) {
      return DateFormat('hh:mm a').format(dt);
    }

    // Yesterday
    if (dateOnly == yesterday) {
      return "Yesterday";
    }

    // Older
    return DateFormat('MM/dd/yy').format(dt);
  }

 static String formatTime(String? time) {

   DateTime dt = DateTime.parse(time!);

    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dt.year, dt.month, dt.day);

    final dayDiff = today.difference(date).inDays;

    if (dayDiff == 0) {
      return TimeOfDay.fromDateTime(dt).format(Get.context!);
    }

    if (dayDiff == 1) {
      return "Yesterday";
    }

    return "${dt.day.toString().padLeft(2, '0')}/"
        "${dt.month.toString().padLeft(2, '0')}/"
        "${dt.year}";
        // "${TimeOfDay.fromDateTime(dt).format(Get.context!)}";
  }
}
