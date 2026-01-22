import 'dart:convert';

import 'package:chatify/constants/apis.dart';
import 'package:chatify/services/api_service.dart';
import 'package:chatify/services/notification_service.dart';
import 'package:chatify/widgets/birthday_top_sheet.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class BirthdayController extends GetxController {

  final box = GetStorage();
  var listBirthdays = [].obs;

  Future<List<dynamic>> fetchTodayBirthdays() async {
    try {
      final res = await ApiService.request(
          url: "${APIs.url}/api/birthdays/today", method: "GET");

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        print("API Birthday:- $data");
        return data["birthdayContacts"] ?? [];

      } else {
        return [];
      }
    } catch (e) {
      print("Birthday API error: $e");
      return [];
    }
  }
  @override
  void onReady() {
    // TODO: implement onReady
    super.onReady();
    checkBirthdays();
    checkMyBirthday();
  }

  void checkBirthdays() async {
    final today = DateTime.now().toString().substring(0, 10);
    final lastShown = box.read("birthday_shown");

    if (lastShown == today) return;

    final birthdays = await fetchTodayBirthdays();
    listBirthdays.value = birthdays;
    // print("Birthdays:- $birthdays");
    if (birthdays.isNotEmpty) {
      box.write("birthday_shown", today);
      handleBirthdayFromApi(birthdays);
    }
  }


  void handleBirthdayFromApi(List<dynamic> apiUsers) {
    final context = NotificationService().navigatorKey.currentContext;
    if (context == null) return;

    try {
      List<Map<String, dynamic>> birthdayUsers =
      apiUsers.map((e) => {
        "userId": e["userId"],
        "fullName": e["fullName"],
        "profilePhoto": e["profileImageUrl"],
      }).toList();


      final int totalBirthdaysToday = birthdayUsers.length;

      showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: "BirthdaySheet",
        barrierColor: Colors.black.withOpacity(0.7),
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, __, ___) {
          return Align(
            alignment: Alignment.topCenter,
            child: BirthdayTopSheet(
              birthdayUsers: birthdayUsers,
              isMultiple: totalBirthdaysToday > 1,
              title: totalBirthdaysToday == 1
                  ? "Today is ${birthdayUsers[0]["fullName"]}'s Birthday"
                  : "Today are $totalBirthdaysToday birthdays",
            ),
          );
        },
        transitionBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            )),
            child: child,
          );
        },
      );
    } catch (e) {
      print("Error showing birthday from API: $e");
    }
  }

  Future<Map<String, dynamic>?> fetchMyBirthday() async {
    try {
      final res = await ApiService.request(
        url: "${APIs.url}/api/birthdays/my-birthday",
        method: "GET",
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 200 && data['success']) {
        print("My Birthday:- $data");
        return jsonDecode(res.body);
      } else {
        return null;
      }
    } catch (e) {
      print("My Birthday API error: $e");
      return null;
    }
  }
  void checkMyBirthday() async {
    final today = DateTime.now().toString().substring(0, 10);
    final lastShown = box.read("my_birthday_shown");

    if (lastShown == today) return;

    final data = await fetchMyBirthday();

    if (data != null && data["isBirthdayToday"] == true) {
      box.write("my_birthday_shown", today);
      // showMyBirthdayDialog(data["age"]);
    }
  }




}
