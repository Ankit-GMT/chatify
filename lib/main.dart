// import 'package:chatify/Screens/splash_screen.dart';
// import 'package:chatify/controllers/auth_controller.dart';
// import 'package:chatify/controllers/theme_controller.dart';
// import 'package:chatify/firebase_options.dart';
// import 'package:chatify/services/notification_service.dart';
// import 'package:chatify/theme.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:permission_handler/permission_handler.dart';
//
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.currentPlatform,
//   );
//   FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
//
//   // SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
//   if (!await Permission.contacts.isGranted) {
//     await Permission.contacts.request();
//   }
//   Get.put(AuthController(), permanent: true);
//   Get.put(ThemeController(), permanent: true);
//   final notificationService = NotificationService();
//   await notificationService.initialize();
//   await notificationService.printFcmToken();
//   runApp(MyApp(
//     notificationService: notificationService,
//   ));
// }
//
// class MyApp extends StatefulWidget {
//   final NotificationService notificationService;
//
//   const MyApp({super.key, required this.notificationService});
//
//   @override
//   State<MyApp> createState() => _MyAppState();
// }
//
// class _MyAppState extends State<MyApp> {
//   final themeController = Get.find<ThemeController>();
//
//   @override
//   Widget build(BuildContext context) {
//     return GetMaterialApp(
//       title: 'Chatify',
//       navigatorKey: widget.notificationService.navigatorKey,
//       debugShowCheckedModeBanner: false,
//       theme: AppThemes.lightTheme,
//       darkTheme: AppThemes.darkTheme,
//       themeMode:
//           themeController.isDarkMode.value ? ThemeMode.dark : ThemeMode.light,
//       home: SplashScreen(),
//     );
//   }
// }

import 'package:chatify/Screens/splash_screen.dart';
import 'package:chatify/controllers/auth_controller.dart';
import 'package:chatify/controllers/theme_controller.dart';
import 'package:chatify/firebase_options.dart';
import 'package:chatify/services/notification_service.dart';
import 'package:chatify/theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  if (!await Permission.contacts.isGranted) {
    await Permission.contacts.request();
  }
  Get.put(AuthController(), permanent: true);
  Get.put(ThemeController(), permanent: true);
  final notificationService = NotificationService();
  await notificationService.initialize();
  await notificationService.printFcmToken();
  final box = GetStorage();
  print("accessToken: ${box.read("accessToken")}");
  runApp(MyApp(
    notificationService: notificationService,
  ));
}

class MyApp extends StatefulWidget {
  final NotificationService notificationService;

  const MyApp({super.key, required this.notificationService});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final themeController = Get.find<ThemeController>();

  @override
  void initState() {
    super.initState();
    _checkLaunchFromNotification();   // ADD THIS
    _checkActiveCallsOnLaunch();
  }

  Future<void> _checkLaunchFromNotification() async {
    await Future.delayed(Duration(seconds: 1));

    final details = await NotificationService()
        .localNotifications
        .getNotificationAppLaunchDetails();

    if (details != null && details.didNotificationLaunchApp) {
      final payload = details.notificationResponse?.payload;

      if (payload != null && payload.isNotEmpty) {
        print("🔥 App launched by NOTIFICATION. Payload = $payload");

        WidgetsBinding.instance.addPostFrameCallback((_) {
          NotificationService().navigateToChat(payload);
        });
      }
    }
  }


  Future<void> _checkActiveCallsOnLaunch() async {
    await Future.delayed(Duration(milliseconds: 600));

    final calls = await FlutterCallkitIncoming.activeCalls();
    print("🔥 ACTIVE CALLS ON APP LAUNCH: $calls");

    if (calls != null && calls.isNotEmpty) {
      final call = calls.first;

      // If call is invalid or ended, CLEAN IT
      if (call['id'] == null || call['extra'] == null) {
        await FlutterCallkitIncoming.endAllCalls();
        return;
      }

      final raw = call['extra'];
      Map<String, dynamic> data =
      raw is Map ? raw.map((k, v) => MapEntry(k.toString(), v)) : {};

      WidgetsBinding.instance.addPostFrameCallback((_) {
        NotificationService().openCallScreen(data);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Chatify',
      navigatorKey: widget.notificationService.navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,
      themeMode:
      themeController.isDarkMode.value ? ThemeMode.dark : ThemeMode.light,
      home: SplashScreen(),
    );
  }
}
