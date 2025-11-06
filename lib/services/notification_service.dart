import 'dart:async';
import 'package:chatify/Screens/video_call_screen.dart';
import 'package:chatify/Screens/voice_call_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';


class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// 🔹 Initialize Firebase + FCM listeners
  Future<void> initialize() async {
    await _requestPermissions();
    await _initFirebaseListeners();

  }

  ///  Ask for notification permission (Android 13+, iOS)
  Future<void> _requestPermissions() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
    if(await Permission.microphone.isDenied){
      await Permission.microphone.request();
    }
    if(await Permission.camera.isDenied){
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
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
    FirebaseMessaging.onBackgroundMessage(_backgroundHandler);

    FlutterCallkitIncoming.onEvent.listen(_handleCallkitEvent);
  }

  /// 🔹 Foreground/Background message handler
  Future<void> _handleMessage(RemoteMessage message) async {
    if (message.data['type'] == 'call_invite') {
      await _showIncomingCall(message.data);
    }
    else if (message.data['type'] == 'call_end') {
      await FlutterCallkitIncoming.endAllCalls();
      // navigatorKey.currentState?.popUntil((route) => route.isFirst);
    }
  }

  /// 🔹 Background handler (required to be static)
  @pragma('vm:entry-point')
  static Future<void> _backgroundHandler(RemoteMessage message) async {
    await Firebase.initializeApp();
    if (message.data['type'] == 'call_invite') {
      final callData = message.data;
      final callType = callData['callType'];
      final params = CallKitParams(
        id: callData['channelId'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        nameCaller: callData['callerName'] ?? 'Unknown',
        appName: 'MyApp',
        handle: callType == 'video' ? 'Video Call' : 'Voice Call',
        type: callType == 'video' ? 1 : 0,
        extra: callData,
      );
      await FlutterCallkitIncoming.showCallkitIncoming(params);
    }
  }

  /// 🔹 Show CallKit screen
  Future<void> _showIncomingCall(Map<String, dynamic> callData) async {

    final callType = callData['callType'];

    final params = CallKitParams(
      id: callData['channelId'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      nameCaller: callData['callerName'] ?? 'Unknown',
      appName: 'MyApp',
      handle: callType == 'video' ? 'Video Call' : 'Voice Call',
      type: callType == 'video' ? 1 : 0,
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
        print("CALL DATA :- $callData");
        if (callData['callType'] == 'voice') {
          Navigator.push(navigatorKey.currentContext!, MaterialPageRoute(
            builder: (_) => VoiceCallScreen(
              channelId: callData['channelId'],
              token: callData['token'],
              callerId: callData['callerId'],
              receiverId: callData['receiverId'],
            ),
          ));
        } else {
          Navigator.push(navigatorKey.currentContext!, MaterialPageRoute(
            builder: (_) => VideoCallScreen(
              channelId: callData['channelId'],
              token: callData['token'],
              callerId: callData['callerId'],
              receiverId: callData['receiverId'],
            ),
          ));
        }

        // Navigator.push(
        //   navigatorKey.currentContext!,
        //   MaterialPageRoute(
        //     builder: (_) => VoiceCallScreen(channelId: callData['channelId'],token: callData['token'],),
        //   ),
        // );
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
}