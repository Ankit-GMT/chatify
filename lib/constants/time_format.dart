import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TimeFormat {
  static String getFormattedTime(
      {required BuildContext context, required String time}) {
    DateTime dt = DateTime.parse(time);

    // Format to 12-hour clock with AM/PM
    String formatted = DateFormat('hh:mm a').format(dt);
    return formatted;
  }
}