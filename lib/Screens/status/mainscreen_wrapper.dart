import 'package:flutter/material.dart';
import 'package:chatify/Screens/main_screen.dart';
import 'package:chatify/services/notification_service.dart';
import 'package:get_storage/get_storage.dart';

class MainScreenWrapper extends StatefulWidget {
  const MainScreenWrapper({super.key});

  @override
  State<MainScreenWrapper> createState() => _MainScreenWrapperState();
}

class _MainScreenWrapperState extends State<MainScreenWrapper> {

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final box = GetStorage();
      final savedData = box.read("pendingBirthday");

      if (savedData != null) {
        NotificationService().handleBirthdayNotification(
          NotificationService().navigatorKey.currentContext!,
          Map<String, dynamic>.from(savedData),
        );

        // VERY IMPORTANT — clear after showing
        await box.remove("pendingBirthday");
      }
    });

  }

  @override
  Widget build(BuildContext context) {
    return const MainScreen();
  }
}
