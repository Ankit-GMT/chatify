import 'dart:async';
import 'dart:convert';
import 'package:chatify/Screens/chat_screen.dart';
import 'package:chatify/Screens/group_video_screen.dart';
import 'package:chatify/Screens/group_voice_screen.dart';
import 'package:chatify/Screens/settings_screen.dart';
import 'package:chatify/Screens/video_call_screen1.dart';
import 'package:chatify/Screens/voice_call_screen_1.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

// for background / terminated
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  if (message.data['type'] == 'call_invite') {
    final callData = message.data;
    final callType = callData['callType'];
    final params = CallKitParams(
      id: callData['channelId'] ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      nameCaller: callData['callerName'] ?? 'Unknown',
      appName: 'MyApp',
      handle: callType == 'video' ? 'Video Call' : 'Voice Call',
      type: callType == 'video' ? 1 : 0,
      extra: callData,
    );
    await FlutterCallkitIncoming.showCallkitIncoming(params);
  } else if (message.data['type'] == 'group_call_invite') {
    final callData = message.data;
    final callType = callData['callType'];
    final params = CallKitParams(
      id: callData['channelId'] ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      nameCaller: callData['callerName'] ?? 'Unknown',
      appName: 'MyApp',
      handle: callType == 'groupVideo'
          ? 'Group Video Call From ${callData['callerName']}'
          : 'Group Voice Call From ${callData['callerName']}',
      type: callType == 'groupVideo' ? 1 : 0,
      extra: callData,
    );
    await FlutterCallkitIncoming.showCallkitIncoming(params);
  } else if (message.data['type'] == 'chat_message') {
    await NotificationService.showBackgroundMessageNotification(message.data);
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// 🔹 Initialize Firebase + FCM listeners
  Future<void> initialize() async {
    await _requestPermissions();
    await _initLocalNotifications();
    await _initFirebaseListeners();
  }

  ///  Ask for notification permission (Android 13+, iOS)
  Future<void> _requestPermissions() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
    if (await Permission.microphone.isDenied) {
      await Permission.microphone.request();
    }
    if (await Permission.camera.isDenied) {
      await Permission.camera.request();
    }

    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  /// 🔹 Get and print current FCM token
  Future<void> printFcmToken() async {
    final token = await _fcm.getToken();
    print("🔹 FCM Token: $token");

    // Optional: handle refresh
    _fcm.onTokenRefresh.listen((newToken) {
      print("🔁 FCM Token refreshed: $newToken");
    });
  }

  /// 🔹 Configure FCM listeners for foreground & background messages
  Future<void> _initFirebaseListeners() async {
    FirebaseMessaging.onMessage.listen(_handleMessage);
    // FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
    // FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    // FlutterCallkitIncoming.onEvent.listen(_handleCallkitEvent);
  }

  /// 🔹 Foreground/Background message handler
  Future<void> _handleMessage(RemoteMessage message) async {
    if (message.data['type'] == 'call_invite') {
      await _showIncomingCall(message.data);
    } else if (message.data['type'] == 'call_end') {
      await FlutterCallkitIncoming.endAllCalls();
      // navigatorKey.currentState?.popUntil((route) => route.isFirst);
    } else if (message.data['type'] == "group_call_invite") {
      await _showIncomingCall(message.data);
    } else if (message.data['type'] == "group_call_end") {
      await FlutterCallkitIncoming.endAllCalls();
    } else if (message.data['type'] == "chat_message") {
      await showBackgroundMessageNotification(message.data);
    }
  }

  /// 🔹 Show CallKit screen
  Future<void> _showIncomingCall(Map<String, dynamic> callData) async {
    final callType = callData['callType'];

    final params = CallKitParams(
      id: callData['channelId'] ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      nameCaller: callData['callerName'] ?? 'Unknown',
      appName: 'MyApp',
      handle: (callType == 'video' || callType == 'groupVideo')
          ? 'Video Call'
          : 'Voice Call',
      type: (callType == 'video' || callType == 'groupVideo') ? 1 : 0,
      extra: callData,
    );
    await FlutterCallkitIncoming.showCallkitIncoming(params);
  }

  ///  Handle user actions from CallKit
  Future<void> _handleCallkitEvent(CallEvent? event) async {
    if (event == null) return;

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
          if (navigatorKey.currentContext == null) {
            print(" Waiting for navigator context...");
            await Future.delayed(const Duration(seconds: 1));
          }
        });

        if (navigatorKey.currentContext != null) {
        if (callData['callType'] == 'voice') {
          Navigator.push(
              navigatorKey.currentContext!,
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
              navigatorKey.currentContext!,
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
              navigatorKey.currentContext!,
              MaterialPageRoute(
                builder: (_) => GroupVideoCallScreen(
                    channelId: callData['channelId'],
                    token: callData['token'],
                    callerId: callData['callerId'],
                    receiverIds: ids),
              ));
        } else if (callData['callType'] == 'groupVoice') {
          Navigator.push(
              navigatorKey.currentContext!,
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
  }

  /// 🔹 Initialize local notifications
  Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings initSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings =
        InitializationSettings(android: initSettingsAndroid);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final chatId = response.payload;
        if (chatId != null && chatId.isNotEmpty) {
          // navigatorKey.currentState?.pushAndRemoveUntil(
          // '/chat',
          // arguments: {'chatId': chatId},
          // );
          Get.offAll(() => ChatScreen(chatUser: null, chatType: null));
        }
      },
    );
  }

  ///  Show message notification (for chat messages)
  static Future<void> showBackgroundMessageNotification(
      Map<String, dynamic> data) async {
    final FlutterLocalNotificationsPlugin localNotifications =
        FlutterLocalNotificationsPlugin();

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'chat_messages_channel',
      'Chat Messages',
      channelDescription: 'Notifications for chat messages',
      importance: Importance.high,
      priority: Priority.high,
    );

    final NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    final chatType = data['chatType'] ?? 'PRIVATE';
    final chatId = data['chatId'] ?? '';
    final senderName = data['name'] ?? 'Someone';
    final message = data['message'] ?? 'New message';

    String title;
    String body;

    if (chatType == 'GROUP') {
      final groupName = data['groupName'] ?? 'Group Chat';
      title = groupName;
      body = '$senderName: $message';
    } else {
      title = senderName;
      body = message;
    }

    await localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      platformDetails,
      payload: chatId,
    );
  }

  Future<void> checkForPendingCall() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString('pending_call');
    if (savedData == null) return;

    final callData = jsonDecode(savedData);
    print("🚀 Launching pending call: $callData");
    // await prefs.remove('pending_call');

    await Future.delayed(const Duration(milliseconds: 500));

    if (navigatorKey.currentContext == null) {
      print("⏳ Waiting for navigator context...");
      await Future.delayed(const Duration(seconds: 1));
    }

    if (navigatorKey.currentContext == null) return;

    List<String> ids = [];
    if (callData['receiverIds'] != null) {
      ids = callData['receiverIds']
          .toString()
          .split(',')
          .map((e) => e.trim())
          .toList();
    }

    switch (callData['callType']) {
      case 'voice':
        Navigator.push(
          navigatorKey.currentContext!,
          MaterialPageRoute(
            builder: (_) => VoiceCallScreen1(
              name: callData['callerName'],
              channelId: callData['channelId'],
              token: callData['token'],
              callerId: callData['callerId'],
              receiverId: callData['receiverId'],
            ),
          ),
        );
        break;
      case 'video':
        Navigator.push(
          navigatorKey.currentContext!,
          MaterialPageRoute(
            builder: (_) => VideoCallScreen1(
              name: callData['callerName'],
              channelId: callData['channelId'],
              token: callData['token'],
              callerId: callData['callerId'],
              receiverId: callData['receiverId'],
            ),
          ),
        );
        break;
      case 'groupVoice':
        Navigator.push(
          navigatorKey.currentContext!,
          MaterialPageRoute(
            builder: (_) => GroupVoiceCallScreen(
              channelId: callData['channelId'],
              token: callData['token'],
              callerId: callData['callerId'],
              receiverIds: ids,
            ),
          ),
        );
        break;
      case 'groupVideo':
        Navigator.push(
          navigatorKey.currentContext!,
          MaterialPageRoute(
            builder: (_) => GroupVideoCallScreen(
              channelId: callData['channelId'],
              token: callData['token'],
              callerId: callData['callerId'],
              receiverIds: ids,
            ),
          ),
        );
        break;
    }
  }


  // for testing
  Future<NotificationAppLaunchDetails?> getLaunchDetails() async {
    return await _localNotifications.getNotificationAppLaunchDetails();
  }

}
