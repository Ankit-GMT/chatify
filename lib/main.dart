import 'package:chatify/Screens/splash_screen.dart';
import 'package:chatify/controllers/auth_controller.dart';
import 'package:chatify/controllers/theme_controller.dart';
import 'package:chatify/firebase_options.dart';
import 'package:chatify/services/notification_service.dart';
import 'package:chatify/theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
