import 'dart:async';
import 'dart:convert';

import 'package:chatify/Screens/chat_screen.dart';
import 'package:chatify/Screens/group_video_screen.dart';
import 'package:chatify/Screens/group_voice_screen.dart';
import 'package:chatify/Screens/main_screen.dart';
import 'package:chatify/Screens/splash_screen.dart';
import 'package:chatify/Screens/video_call_screen1.dart';
import 'package:chatify/Screens/voice_call_screen_1.dart';
import 'package:chatify/controllers/auth_controller.dart';
import 'package:chatify/controllers/theme_controller.dart';
import 'package:chatify/firebase_options.dart';
import 'package:chatify/services/notification_service.dart';
import 'package:chatify/theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Background CallKit event handler — works even when app is killed
@pragma('vm:entry-point')
Future<void> callkitBackgroundHandler(CallEvent? event) async {
  final notificationService = NotificationService();
  if (event == null) return;
  print('📞 BACKGROUND EVENT: ${event.event}');
  await Firebase.initializeApp();
  final prefs = await SharedPreferences.getInstance();

  if (event.body != null && event.body['extra'] != null) {
    final callData = event.body['extra'];
    switch (event.event) {
      case Event.actionCallAccept:
        final callData = event.body['extra'];
        List<String> ids = [];
        if (callData['receiverIds'] != null) {
          ids = callData['receiverIds']
              .toString()
              .split(',')
              .map((e) => e.trim())
              .toList()
              .cast<String>();
        }
        print("CALL DATA :- $callData");
        Future.delayed(const Duration(seconds: 1), () async {
          if (notificationService.navigatorKey.currentContext == null) {
            print(" Waiting for navigator context...");
            await Future.delayed(const Duration(seconds: 1));
          }
        });

        if (notificationService.navigatorKey.currentContext != null) {
          if (callData['callType'] == 'voice') {
            Navigator.push(
                notificationService.navigatorKey.currentContext!,
                MaterialPageRoute(
                  builder: (_) => VoiceCallScreen1(
                    name: callData['callerName'],
                    channelId: callData['channelId'],
                    token: callData['token'],
                    callerId: callData['callerId'],
                    receiverId: callData['receiverId'],
                  ),
                ));
          } else if (callData['callType'] == 'video') {
            Navigator.push(
                notificationService.navigatorKey.currentContext!,
                MaterialPageRoute(
                  builder: (_) => VideoCallScreen1(
                    name: callData['callerName'],
                    channelId: callData['channelId'],
                    token: callData['token'],
                    callerId: callData['callerId'],
                    receiverId: callData['receiverId'],
                  ),
                ));
          } else if (callData['callType'] == 'groupVideo') {
            Navigator.push(
                notificationService.navigatorKey.currentContext!,
                MaterialPageRoute(
                  builder: (_) => GroupVideoCallScreen(
                      channelId: callData['channelId'],
                      token: callData['token'],
                      callerId: callData['callerId'],
                      receiverIds: ids),
                ));
          } else if (callData['callType'] == 'groupVoice') {
            Navigator.push(
                notificationService.navigatorKey.currentContext!,
                MaterialPageRoute(
                  builder: (_) => GroupVoiceCallScreen(
                      channelId: callData['channelId'],
                      token: callData['token'],
                      callerId: callData['callerId'],
                      receiverIds: ids),
                ));
          }
        }
        break;

      case Event.actionCallDecline:
        await FlutterCallkitIncoming.endAllCalls();
        break;

      case Event.actionCallTimeout:
      case Event.actionCallEnded:
        await FlutterCallkitIncoming.endAllCalls();
        break;

      default:
        break;
    }
    switch (event.event) {
      case Event.actionCallAccept:
        print("✅ Call accepted in background, saving pending_call");
        await prefs.setString('pending_call', jsonEncode(callData));
        break;
      case Event.actionCallDecline:
      case Event.actionCallEnded:
      case Event.actionCallTimeout:
      await prefs.remove('pending_call');
        break;
      default:
        break;
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  RemoteMessage? initialMessage =
      await FirebaseMessaging.instance.getInitialMessage();
  await SharedPreferences.getInstance();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  // Listen for events when app was killed
  FlutterCallkitIncoming.onEvent.listen((CallEvent? event) async {
    if (event == null) return;
    await callkitBackgroundHandler(event);
  });

  // SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  if (!await Permission.contacts.isGranted) {
    await Permission.contacts.request();
  }
  Get.put(AuthController(), permanent: true);
  Get.put(ThemeController(), permanent: true);
  final notificationService = NotificationService();
  await notificationService.initialize();
  await notificationService.printFcmToken();
  final prefs = await SharedPreferences.getInstance();

  // final launchDetails = await notificationService.getLaunchDetails();
  // final launchPayload = launchDetails?.notificationResponse?.payload;
  //
  // int? chatId;
  // if (launchPayload != null && launchPayload.isNotEmpty) {
  //   try {
  //     final data = jsonDecode(launchPayload);
  //     chatId = int.parse(data['chatId']);
  //     print("data :- $data");
  //   } catch (e) {
  //     print('Invalid launch payload: $e');
  //   }
  // }

  runApp(MyApp(
    notificationService: notificationService,
    // chatId: chatId,
    initialMessage: initialMessage,
  ));
  print("Initial Message:- $initialMessage");
  print("main function :- ${prefs.getString('pending_call')}");
  Future.delayed(const Duration(seconds: 2), () async {
    final notificationService = NotificationService();
    await notificationService.checkForPendingCall();
  });
}

class MyApp extends StatefulWidget {
  final NotificationService notificationService;

  // int? chatId;
  final RemoteMessage? initialMessage;

  const MyApp(
      {super.key, required this.notificationService, this.initialMessage});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // Handle background (app already running)
    // FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    //   _handleMessage(message);
    // });

    // Handle killed (cold start)
    if (widget.initialMessage != null) {
      _handleMessage(widget.initialMessage!);
    }
  }

  Future<void> _handleMessage(RemoteMessage message) async {
    // if (message.data['type'] == 'call_invite') {
    //   await _showIncomingCall(message.data);
    // } else if (message.data['type'] == 'call_end') {
    //   await FlutterCallkitIncoming.endAllCalls();
    //   // navigatorKey.currentState?.popUntil((route) => route.isFirst);
    // } else if (message.data['type'] == "group_call_invite") {
    //   await _showIncomingCall(message.data);
    // } else if (message.data['type'] == "group_call_end") {
    //   await FlutterCallkitIncoming.endAllCalls();
    // } else
      if (message.data['type'] == "chat_message") {
      // await NotificationService.showBackgroundMessageNotification(message.data);
      Get.to(() => ChatScreen(chatUser: null,chatType: null,));
    }
  }


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
      // home: SplashScreen(),
      home: Builder(
         builder: (context) {
           if (widget.initialMessage != null) {
             Future.delayed(const Duration(milliseconds: 300), () {
               Get.offAll(() => ChatScreen(chatUser: null, chatType: null));
               // Future.delayed(const Duration(milliseconds: 300), () {
               //   ChatScreen(chatUser: null, chatType: null);
               // });
             });
             return const SizedBox();
           } else {
             return SplashScreen();
           }
         },
       ),
    );
  }
}

/// this is for testing
