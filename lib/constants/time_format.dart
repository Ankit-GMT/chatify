import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// class TimeFormat {
//   static String getFormattedTime(
//       {required BuildContext context, required String time}) {
//     DateTime dt = DateTime.parse(time);
//
//     // Format to 12-hour clock with AM/PM
//     String formatted = DateFormat('hh:mm a').format(dt);
//     return formatted;
//   }
// }

class TimeFormat {
  static String getFormattedTime({
    required BuildContext context,
    required String time,
  }) {
    DateTime dt = DateTime.parse(time);
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
}
