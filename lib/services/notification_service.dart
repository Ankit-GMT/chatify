import 'dart:async';
import 'dart:convert';
import 'package:chatify/Screens/chat_screen.dart';
import 'package:chatify/Screens/group_video_screen.dart';
import 'package:chatify/Screens/group_voice_screen.dart';
import 'package:chatify/Screens/video_call_screen1.dart';
import 'package:chatify/Screens/voice_call_screen_1.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

/// Stores call data when the app is killed and opened from CallKit
Map<String, dynamic>? pendingCallData;

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  // ----------- NORMAL CALL ------------
  if (message.data['type'] == 'call_invite') {
    final data = message.data;

    final params = CallKitParams(
      id: data['channelId'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      nameCaller: data['callerName'] ?? 'Unknown',
      appName: 'Chatify',
      handle: data['callType'] == 'video' ? 'Video Call' : 'Voice Call',
      type: data['callType'] == 'video' ? 1 : 0,
      extra: data,
    );

    await FlutterCallkitIncoming.showCallkitIncoming(params);
  }

  // ----------- GROUP CALL ------------
  else if (message.data['type'] == 'group_call_invite') {
    final data = message.data;

    final params = CallKitParams(
      id: data['channelId'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      nameCaller: data['callerName'] ?? 'Unknown',
      appName: 'Chatify',
      handle: data['callType'] == 'VIDEO'
          ? 'Group Video Call'
          : 'Group Voice Call',
      type: data['callType'] == 'VIDEO' ? 1 : 0,
      extra: data,
    );

    await FlutterCallkitIncoming.showCallkitIncoming(params);
  }

  // ---------- MESSAGE NOTIFICATION ----------
  else if (message.data['type'] == 'chat_message') {
    await NotificationService.showBackgroundMessageNotification(message.data);
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final FlutterLocalNotificationsPlugin localNotifications =
      FlutterLocalNotificationsPlugin();

  /// INITIALIZE NOTIFICATION SYSTEM
  Future<void> initialize() async {
    await _requestPermissions();
    await _initLocalNotifications();
    await _initFirebaseListeners();
  }

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

    await _fcm.requestPermission(alert: true, badge: true, sound: true);
  }

  Future<void> printFcmToken() async {
    final token = await _fcm.getToken();
    print(" FCM Token: $token");

    _fcm.onTokenRefresh.listen((newToken) {
      print("FCM Token refreshed: $newToken");
    });
  }

  // ----------------------------------------------------

  Future<void> _initFirebaseListeners() async {
    FirebaseMessaging.onMessage.listen(_handleMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);

    // Listen for CallKit events
    FlutterCallkitIncoming.onEvent.listen(_handleCallkitEvent);
  }

  Future<void> _handleMessage(RemoteMessage message) async {
    print("MESSAGE FIRED: ${message.data}");

    if (message.data['type'] == 'call_invite') {
      await _showIncomingCall(message.data);
    } else if (message.data['type'] == "group_call_invite") {
      await _showIncomingCall(message.data);
    } else if (message.data['type'] == "call_end" ||
        message.data['type'] == "group_call_end") {
      await FlutterCallkitIncoming.endAllCalls();
    } else if (message.data['type'] == "chat_message") {
      await showBackgroundMessageNotification(message.data);
    }
  }

  // ----------------------------------------------------

  Future<void> _showIncomingCall(Map<String, dynamic> data) async {
    final params = CallKitParams(
      id: data['channelId'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      nameCaller: data['callerName'] ?? 'Unknown',
      appName: 'Chatify',
      handle: (data['callType'] == 'video' || data['callType'] == 'VIDEO')
          ? 'Video Call'
          : 'Voice Call',
      type: (data['callType'] == 'video' || data['callType'] == 'VIDEO')
          ? 1
          : 0,
      extra: data,
    );

    await FlutterCallkitIncoming.showCallkitIncoming(params);
  }

  // ----------------------------------------------------

  Future<void> _handleCallkitEvent(CallEvent? event) async {
    if (event == null) return;

    print("📞 CALLKIT EVENT FIRED: ${event.event}");
    print("📞 EVENT BODY: ${event.body}");

    final raw = event.body['extra'];
    Map<String, dynamic> data =
        raw is Map ? raw.map((k, v) => MapEntry(k.toString(), v)) : {};

    switch (event.event) {
      case Event.actionCallIncoming:
        print(" actionCallIncoming received");
        pendingCallData = data;
        break;

      case Event.actionCallAccept:
        print(" actionCallAccept received ;- Data = $data");
        if (navigatorKey.currentContext == null) {
          pendingCallData = data;
        } else {
          openCallScreen(data);
        }
        break;

      case Event.actionCallDecline:
        print("❌ Call ended/declined");
        await FlutterCallkitIncoming.endAllCalls();
        break;
      case Event.actionCallEnded:
        print("❌ Call ended/declined");
        await FlutterCallkitIncoming.endAllCalls();
        break;
      case Event.actionCallTimeout:
        print("❌ Call ended/declined");
        await FlutterCallkitIncoming.endAllCalls();
        break;

      default:
        print("Unknown CallKit event: ${event.event}");
        break;
    }
  }

  // ----------------------------------------------------

  void openCallScreen(Map<String, dynamic> callData) {
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;

    // List<String> ids = [];
    // if (callData['receiverIds'] != null) {
    //   ids = callData['receiverIds']
    //       .toString()
    //       .split(',')
    //       .map((e) => e.trim())
    //       .toList();
    // }
    final participantsJson = callData['participants'];



    if (callData['callType'] == 'voice') {
      Navigator.push(
        ctx,
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
    } else if (callData['callType'] == 'video') {
      Navigator.push(
        ctx,
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
    }
    else if (callData['callType'] == 'VIDEO') {
      final List<dynamic> participantsList = jsonDecode(participantsJson);
      Navigator.push(
        ctx,
        MaterialPageRoute(
          builder: (_) => GroupVideoCallScreen(
            channelId: callData['channelId'],
            token: callData['token'],
            callerId: callData['callerId'],
            receiverIds: participantsList,
          ),
        ),
      );
    } else if (callData['callType'] == 'VOICE') {
      final List<dynamic> participantsList = jsonDecode(participantsJson);
      Navigator.push(
        ctx,
        MaterialPageRoute(
          builder: (_) => GroupVoiceCallScreen(
            channelId: callData['channelId'],
            token: callData['token'],
            callerId: callData['callerId'],
            receiverIds: participantsList,
          ),
        ),
      );
    }
  }

  // ----------------------------------------------------

  Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(android: androidInit);

    await localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        _handleNotificationTap(response.payload);
      },
    );
  }

  void _handleNotificationTap(String? payload) {
    if (payload == null || payload.isEmpty) return;

    print("📨 Notification tapped. Payload = $payload");

    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(chatId: int.parse(payload)),
      ),
    );

  }

  void navigateToChat(String chatId) {

    print("navigate to chat :- $chatId");
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          chatId: int.parse(chatId),
        ),
      ),
    );
  }

  // ----------------------------------------------------

  static Future<void> showBackgroundMessageNotification(
      Map<String, dynamic> data) async {
    final local = FlutterLocalNotificationsPlugin();

    final androidDetails = AndroidNotificationDetails(
      'chat_messages_channel',
      'Chat Messages',
      channelDescription: 'Chat Message Alerts',
      importance: Importance.high,
      priority: Priority.high,
    );

    final details = NotificationDetails(android: androidDetails);

    final title =
        data['chatType'] == 'GROUP' ? data['groupName'] : data['name'];

    final body = data['chatType'] == 'GROUP'
        ? "${data['name']}: ${data['message']}"
        : data['message'];

    await local.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: data['chatId'] ?? '',
    );
  }
}
