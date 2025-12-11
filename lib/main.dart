
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
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  if (!await Permission.contacts.isGranted) {
    await Permission.contacts.request();
  }
  Get.put(AuthController(), permanent: true);
  Get.put(ThemeController(), permanent: true);
  Get.put(FloatingCallBubbleService());

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
        print("App launched by NOTIFICATION. Payload = $payload");

        WidgetsBinding.instance.addPostFrameCallback((_) {
          NotificationService().navigateToChat(payload);
        });
      }
    }
  }


  Future<void> _checkActiveCallsOnLaunch() async {
    await Future.delayed(Duration(milliseconds: 600));

    final calls = await FlutterCallkitIncoming.activeCalls();
    print("ACTIVE CALLS ON APP LAUNCH: $calls");

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
      home: const SplashScreen(),

      // ⬇⬇⬇ THIS is the important part
      builder: (context, child) {
        return Overlay(
          initialEntries: [
            OverlayEntry(
              builder: (context) {
                return Stack(
                  children: [
                    // Current route
                    child ?? const SizedBox.shrink(),

                    // Floating bubble
                    Obx(() {
                      final bubble = FloatingCallBubbleService.to;
                      if (!bubble.isVisible.value) return SizedBox.shrink();
                      final c = Get.find<VoiceCallController>();

                      return Positioned(
                        left: c.bubbleX.value,
                        top: c.bubbleY.value,
                        child: Draggable(
                          feedback: _buildBubble(c,bubble),
                          childWhenDragging: Opacity(
                            opacity: 0.3,
                            child: _buildBubble(c,bubble),
                          ),
                          onDragEnd: (details) {
                            double x = details.offset.dx;
                            double y = details.offset.dy;

                            // Screen width
                            double screenWidth = Get.width;

                            // SNAP LEFT or RIGHT
                            if (x < screenWidth / 2) {
                              x = 10; // left padding
                            } else {
                              x = screenWidth - 160; // right side bubble width included
                            }

                            c.bubbleX.value = x;
                            c.bubbleY.value = y.clamp(40, Get.height - 160);
                          },

                          child: _buildBubble(c,bubble),
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
  Widget _buildBubble(VoiceCallController c,FloatingCallBubbleService bubble) {
    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        onTap: () {
          // Reopen full call screen
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
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.80),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 8)],
          ),
          child:
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(c.callerName.value,
                  style: TextStyle(color: Colors.white, fontSize: 15)),
              SizedBox(height: 4),
              Text(c.formatDuration(c.callDuration.value),
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              SizedBox(height: 8),

              // End Call Button
              GestureDetector(
                onTap: () {
                  final c = Get.find<VoiceCallController>();
                  c.endCall();
                  bubble.hide();
                },
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text("End Call",
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
