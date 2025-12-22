import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:chatify/Screens/chat_screen.dart';
import 'package:chatify/Screens/group_video_screen.dart';
import 'package:chatify/Screens/group_voice_screen.dart';
import 'package:chatify/Screens/main_screen.dart';
import 'package:chatify/Screens/video_call_screen1.dart';
import 'package:chatify/Screens/voice_call_screen_1.dart';
import 'package:chatify/controllers/message_controller.dart';
import 'package:chatify/controllers/video_call_controller.dart';
import 'package:chatify/controllers/voice_call_controller.dart';
import 'package:chatify/services/floating_call_bubble_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

Map<String, dynamic>? pendingCallData;

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  final data = message.data ?? {};
  log("_+_MESSAGE:_ $data");
  final type = data['type']?.toString() ?? '';

  print("TYPE:- $type");

  if (type == 'call_invite' || type == 'group_call_invite') {
    final id = data['channelId'] ?? DateTime.now().millisecondsSinceEpoch.toString();

    final isGroup = type == 'group_call_invite';
    final callType = (data['callType'] ?? '') as String;

    final params = CallKitParams(
      id: id.toString(),
      nameCaller: data['callerName'] ?? 'Unknown',
      appName: 'Chatify',
      handle: (callType.toLowerCase() == 'video')
          ? (isGroup ? 'Group Video Call' : 'Video Call')
          : (isGroup ? 'Group Voice Call' : 'Voice Call'),
      type: (callType.toLowerCase() == 'video') ? 1 : 0,
      extra: data,
    );

    // Show incoming using CallKit
    if (isCallExpired(data)) {
      print("Ignoring expired call invite");
      return;
    }
    print("not ignoring123");
    await FlutterCallkitIncoming.showCallkitIncoming(params);
    return;
  }
  if (type == 'call_end' || type == 'call_declined') {
    await FlutterCallkitIncoming.endAllCalls();

    return;
  }
  if (type == 'group_call_end') {
    await FlutterCallkitIncoming.endAllCalls();
  }

  // Call timeout (30s)
  if (type == 'call_timeout') {
    await FlutterCallkitIncoming.endAllCalls();
    return;
  }

  // Missed call
  if (type == 'call_missed') {
    await FlutterCallkitIncoming.endAllCalls();

    // show missed call notification
    await NotificationService.showBackgroundMessageNotification({
      "chatId": "",
      "name": "Missed ${data['callType']} call",
      "message": "From ${data['callerName']}",
      "chatType": "SINGLE",
    });
    return;
  }

  if (type == 'chat_message') {
    await NotificationService.showBackgroundMessageNotification(data);
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final messageController = Get.put(MessageController());

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final FlutterLocalNotificationsPlugin localNotifications = FlutterLocalNotificationsPlugin();

  bool _initialized = false; // prevent double-init
  bool _listenersAttached = false; // prevent multiple listeners

  Future<void> initialize() async {
    if (_initialized) return;
    await _requestPermissions();
    await _initLocalNotifications();
    await _initFirebaseListeners();
    _initialized = true;
  }

  Future<void> _requestPermissions() async {
    try {
      if (await Permission.notification.isDenied) {
        await Permission.notification.request();
      }
      if (await Permission.microphone.isDenied) {
        await Permission.microphone.request();
      }
      if (await Permission.camera.isDenied) {
        await Permission.camera.request();
      }
    } catch (e) {
      print('Permission request error: $e');
    }

    await _fcm.requestPermission(alert: true, badge: true, sound: true);
  }

  Future<void> printFcmToken() async {
    final token = await _fcm.getToken();
    print("FCM Token: $token");

    _fcm.onTokenRefresh.listen((newToken) {
      print("FCM Token refreshed: $newToken");
    });
  }

  Future<void> _initFirebaseListeners() async {
    if (_listenersAttached) return;

    // Foreground messages
    FirebaseMessaging.onMessage.listen((message) async {
      await _handleMessage(message);
    });

    // When the app is opened from a notification
    FirebaseMessaging.onMessageOpenedApp.listen((message) async {
      await _handleMessage(message);
    });

    // CallKit events
    FlutterCallkitIncoming.onEvent.listen((event) async {
      await _handleCallkitEvent(event);
    });

    _listenersAttached = true;
  }

  Future<void> _handleMessage(RemoteMessage message) async {
    final data = message.data ?? {};
    final type = data['type']?.toString() ?? '';

    log("📩 MESSAGE: $data");

    // Incoming ringing
    if (type == 'call_invite' || type == 'group_call_invite') {
      if (isCallExpired(data)) {
        print("Ignoring expired call invite");
        await _showMissedCallNotification(data);
        return;
      }
      print("not ignoring");
      await _showIncomingCall(data);
    }

    if (type == 'group_call_end') {
      await FlutterCallkitIncoming.endAllCalls();

      if (Navigator.canPop(Get.context!)) {
        Navigator.pop(Get.context!);
      } else {
        Get.offAll(() => MainScreen());
      }
    }

    // Caller hung up OR receiver declined
    if (type == 'call_end' || type == 'call_declined') {

      await FlutterCallkitIncoming.endAllCalls();
      Get.delete<VoiceCallController>(force: true);

      Get.delete<VideoCallController>(force: true);

      if (Navigator.canPop(Get.context!)) {
        Navigator.pop(Get.context!);
      } else {
        Get.offAll(() => MainScreen());
      }
      NotificationService().localNotifications.cancel(999);

      FloatingCallBubbleService.to.hide();
    }

    //  AUTO TIMEOUT (30s)
     if (type == 'call_timeout' || type == 'call_missed_timeout') {
      await FlutterCallkitIncoming.endAllCalls();

      if (Get.isRegistered<VoiceCallController>() && data['callType'] == 'VOICE') {
        Get.find<VoiceCallController>().onCallTimeout();
      }

      if (Get.isRegistered<VideoCallController>() && data['callType'] == 'VIDEO') {
        Get.find<VideoCallController>().onCallTimeout();
      }
    }

    //  MISSED CALL
     if (type == 'call_missed') {
      await FlutterCallkitIncoming.endAllCalls();
      await _showMissedCallNotification(data);
    }

     if (type == 'chat_message') {
      await showBackgroundMessageNotification(data);
    }
  }

  Future<void> _showMissedCallNotification(Map<String, dynamic> data) async {
    final android = AndroidNotificationDetails(
      'missed_call_channel',
      'Missed Calls',
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.missedCall,
    );

    await localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      "Missed ${data['callType']} call",
      "From ${data['callerName']}",
      NotificationDetails(android: android),
    );
  }

  Future<void> _showIncomingCall(Map<String, dynamic> data) async {
    final id = data['channelId'] ?? DateTime.now().millisecondsSinceEpoch.toString();

    // Prevent duplicates: if an active call with same id already exists, skip
    try {
      final active = await FlutterCallkitIncoming.activeCalls();
      if (active != null) {
        final exists = active.any((c) {
          try {
            return c['id']?.toString() == id.toString();
          } catch (e) {
            return false;
          }
        });
        if (exists) {
          print('Incoming call for id $id already active — skipping duplicate.');
          return;
        }
      }
    } catch (e) {
      print('Error checking active calls: $e');
    }

    final callType = (data['callType'] ?? '').toString();
    final isVideo = callType.toLowerCase() == 'video' || callType == 'VIDEO';
    final params = CallKitParams(
      id: id.toString(),
      nameCaller: data['callerName'] ?? 'Unknown',
      appName: 'Chatify',
      handle: isVideo ? 'Video Call' : 'Voice Call',
      type: isVideo ? 1 : 0,
      extra: data,
    );

    await FlutterCallkitIncoming.showCallkitIncoming(params);
  }

  Future<void> _handleCallkitEvent(CallEvent? event) async {
    if (event == null) return;

    final raw = event.body['extra'];
    final Map<String, dynamic> data =
    raw is Map ? raw.map((k, v) => MapEntry(k.toString(), v)) : {};

    switch (event.event) {

      case Event.actionCallAccept:
        if (navigatorKey.currentContext == null) {
          pendingCallData = data;
        } else {
          openCallScreen(data);
        }
        break;

    // ❌ DECLINED
      case Event.actionCallDecline:
        await messageController.endCall(
          channelId: data['channelId'],
          // callerId: data['callerId'],
          // receiverId: data['receiverId'],
          endReason: "call_declined",
        );
        await FlutterCallkitIncoming.endAllCalls();
        break;

      case Event.actionCallEnded:
      case Event.actionCallTimeout:
        await FlutterCallkitIncoming.endAllCalls();
        break;

      default:
        break;
    }
  }

  void openCallScreen(Map<String, dynamic> callData) {
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;

    final participantsJson = callData['participants'];

    try {
      final callType = (callData['callType'] ?? '').toString();

      if (callType.toLowerCase() == 'voice' && callData['receiverId']!= null) {
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
        return;
      }

      if (callType.toLowerCase() == 'video' && callData['receiverId']!= null) {
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
        return;
      }

      // Group call variants: accept both 'VIDEO'/'VOICE' and lowercase
      if (callType == 'VIDEO' || callType == 'VOICE') {
        List<dynamic> participantsList = [];
        if (participantsJson != null && participantsJson is String && participantsJson.isNotEmpty) {
          participantsList = jsonDecode(participantsJson) as List<dynamic>;
        } else if (participantsJson is List) {
          participantsList = participantsJson;
        }

        if (callType == 'VIDEO') {
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
        } else {
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
    } catch (e) {
      print('openCallScreen error: $e');
    }
  }
  Future<void> showCallerOngoingCallNotification(Map<String, dynamic> data) async {
    const androidDetails = AndroidNotificationDetails(
      'chatify_caller_channel',
      'Ongoing Voice Call',
      channelDescription: 'Shows ongoing voice call while user is calling',
      importance: Importance.max,
      priority: Priority.high,
      ongoing: true, // IMPORTANT: keeps notification active
      autoCancel: false, // DO NOT REMOVE UNTIL CALL ENDS
      onlyAlertOnce: true, // doesn't re-alert
      visibility: NotificationVisibility.public,
      category: AndroidNotificationCategory.call,
    );

    await localNotifications.show(
      999, // FIXED ID, so it updates not duplicates
      "Calling ${data['receiverName']}...",
      "Tap to return to call",
      const NotificationDetails(android: androidDetails),
      payload: jsonEncode({
        "navigateCall": true,
        ...data,
      }),
    );
  }



  Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          _handleNotificationTap(payload);
        }
      },
    );
  }

  void _handleNotificationTap(String? payload) {
    if (payload == null || payload.isEmpty) return;

    try {
      print("📨 Notification tapped. Payload = $payload");

      // If notification is call related → open call screen
      final data = jsonDecode(payload);
      if (data["openCall"] == true) {
        openCallScreen(data);
        return;
      }

      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => ChatScreen(chatId: int.parse(payload)),
        ),
      );
    } catch (e) {
      print('Notification tap parse error: $e');
    }
  }

  void navigateToChat(String chatId) {
    try {
      print("navigate to chat :- $chatId");
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            chatId: int.parse(chatId),
          ),
        ),
      );
    } catch (e) {
      print('navigateToChat error: $e');
    }
  }

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

    final title = data['chatType'] == 'GROUP' ? data['groupName'] : data['name'];

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

bool isCallExpired(Map<String, dynamic> data) {
  final ts = int.tryParse(data['inviteTimestamp']?.toString() ?? '');
  final expiry = 35;

  if (ts == null) return true;

  final now = DateTime.now().millisecondsSinceEpoch;
  return now - ts > expiry * 1000;
}