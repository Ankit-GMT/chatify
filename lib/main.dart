import 'package:chatify/Screens/splash_screen.dart';
import 'package:chatify/Screens/voice_call_screen_1.dart';
import 'package:chatify/controllers/auth_controller.dart';
import 'package:chatify/controllers/theme_controller.dart';
import 'package:chatify/controllers/voice_call_controller.dart';
import 'package:chatify/firebase_options.dart';
import 'package:chatify/services/floating_call_bubble_service.dart';
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

  // Register background handler once (keep as you had it)
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  if (!await Permission.contacts.isGranted) {
    await Permission.contacts.request();
  }

  Get.put(AuthController(), permanent: true);
  Get.put(ThemeController(), permanent: true);
  Get.put(FloatingCallBubbleService());

  // Use the singleton NotificationService and initialize once
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

    // Use the injected singleton instead of creating new instances
    _checkLaunchFromNotification();
    _checkActiveCallsOnLaunch();
  }

  Future<void> _checkLaunchFromNotification() async {
    // small delay to let plugin initialize
    await Future.delayed(const Duration(milliseconds: 800));

    final details = await widget.notificationService
        .localNotifications
        .getNotificationAppLaunchDetails();

    if (details != null && details.didNotificationLaunchApp) {
      final payload = details.notificationResponse?.payload;

      if (payload != null && payload.isNotEmpty && payload.length <15) {
        print("App launched by NOTIFICATION. Payload = $payload");

        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.notificationService.navigateToChat(payload);
        });
      }
    }
  }

  Future<void> _checkActiveCallsOnLaunch() async {
    await Future.delayed(const Duration(milliseconds: 700));

    final calls = await FlutterCallkitIncoming.activeCalls();
    print("ACTIVE CALLS ON APP LAUNCH: $calls");

    if (calls != null && calls.isNotEmpty) {
      final call = calls.first;

      if (call == null) return;

      if (call['id'] == null || call['extra'] == null) {
        await FlutterCallkitIncoming.endAllCalls();
        return;
      }

      final raw = call['extra'];
      Map<String, dynamic> data =
      raw is Map ? raw.map((k, v) => MapEntry(k.toString(), v)) : {};

      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.notificationService.openCallScreen(data);
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
      home: const SplashScreen(),

      builder: (context, child) {
        return Overlay(
          initialEntries: [
            OverlayEntry(
              builder: (context) {
                return Stack(
                  children: [
                    child ?? const SizedBox.shrink(),
                    Obx(() {
                      final bubble = FloatingCallBubbleService.to;
                      if (!bubble.isVisible.value) return const SizedBox.shrink();
                      final c = Get.find<VoiceCallController>();

                      return Positioned(
                        left: c.bubbleX.value,
                        top: c.bubbleY.value,
                        child: Draggable(
                          feedback: _buildBubble(c, bubble),
                          childWhenDragging: Opacity(
                            opacity: 0.3,
                            child: _buildBubble(c, bubble),
                          ),
                          onDragEnd: (details) {
                            double x = details.offset.dx;
                            double y = details.offset.dy;

                            double screenWidth = Get.width;

                            if (x < screenWidth / 2) {
                              x = 10;
                            } else {
                              x = screenWidth - 160;
                            }

                            c.bubbleX.value = x;
                            c.bubbleY.value = y.clamp(40, Get.height - 160);
                          },

                          child: _buildBubble(c, bubble),
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildBubble(VoiceCallController c, FloatingCallBubbleService bubble) {
    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        onTap: () {
          final c = Get.find<VoiceCallController>();
          Get.to(() => VoiceCallScreen1(
            channelId: c.channelId,
            token: c.token,
            callerId: c.callerId,
            receiverId: c.receiverId,
            name: c.callerName.value,
          ));
          bubble.hide();
        },
        child: Container(
          width: 160,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.80),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 8)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(c.callerName.value,
                  style: const TextStyle(color: Colors.white, fontSize: 15)),
              const SizedBox(height: 4),
              Text(c.formatDuration(c.callDuration.value),
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  final c = Get.find<VoiceCallController>();
                  c.endCall();
                  bubble.hide();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Text("End Call",
                      style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}