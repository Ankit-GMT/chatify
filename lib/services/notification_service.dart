import 'dart:async';
import 'dart:io';
import 'package:chatify/Screens/group_video_screen.dart';
import 'package:chatify/Screens/group_voice_screen.dart';
import 'package:chatify/Screens/video_call_screen.dart';
import 'package:chatify/Screens/video_call_screen1.dart';
import 'package:chatify/Screens/voice_call_screen.dart';
import 'package:chatify/Screens/voice_call_screen_1.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

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
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
    FirebaseMessaging.onBackgroundMessage(_backgroundHandler);

    FlutterCallkitIncoming.onEvent.listen(_handleCallkitEvent);
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
    }
    else if(message.data['type'] == "group_call_end"){
      await FlutterCallkitIncoming.endAllCalls();
    }
    else if(message.data['type'] == "chat_message"){
      await _showMessageNotification(message.data);
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
        id: callData['channelId'] ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        nameCaller: callData['callerName'] ?? 'Unknown',
        appName: 'MyApp',
        handle: callType == 'video' ? 'Video Call' : 'Voice Call',
        type: callType == 'video' ? 1 : 0,
        extra: callData,
      );
      await FlutterCallkitIncoming.showCallkitIncoming(params);
    } else if (message.data['type'] == "group_call_invite") {
      final callData = message.data;
      final callType = callData['callType'];
      final params = CallKitParams(
        id: callData['channelId'] ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        nameCaller: callData['callerName'] ?? 'Unknown',
        appName: 'MyApp',
        handle: callType == 'groupVideo' ? 'Group Video Call From ${callData['callerName']}' : 'Group Voice Call From ${callData['callerName']}',
        type: callType == 'groupVideo' ? 1 : 0,
        extra: callData,
      );
      await FlutterCallkitIncoming.showCallkitIncoming(params);
    }
    else if (message.data['type'] == 'chat_message'){
      try {
        final data = message.data;

        // ✅ Initialize notification plugin (needed in background isolate)
        final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

        const AndroidInitializationSettings initSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
        const InitializationSettings initSettings =
        InitializationSettings(android: initSettingsAndroid);

        await flutterLocalNotificationsPlugin.initialize(initSettings);

        // ✅ Create a notification channel (important for Android 8+)
        const AndroidNotificationChannel channel = AndroidNotificationChannel(
          'chat_channel', // unique id
          'Chat Messages', // human-readable name
          description: 'Notifications for new chat messages',
          importance: Importance.high,
        );

        await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(channel);

        // ✅ Extract message data
        final String senderName = data['name'] ?? 'Unknown';
        final String messageText = data['message'] ?? '';
        final String chatType = data['chatType'] ?? 'PRIVATE';
        final String groupName = data['groupName'] ?? '';
        final String chatId = data['chatId'] ?? '';
        final String? profilePicUrl = data['profilePic'];

        // ✅ (Optional) Download profile image if available
        // AndroidBitmap<Object>? largeIcon;
        // if (profilePicUrl != null && profilePicUrl.isNotEmpty) {
        //   try {
        //     final httpClient = HttpClient();
        //     final request = await httpClient.getUrl(Uri.parse(profilePicUrl));
        //     final response = await request.close();
        //     final bytes = await consolidateHttpClientResponseBytes(response);
        //     final filePath = '${(await getTemporaryDirectory()).path}/profile.jpg';
        //     final file = File(filePath);
        //     await file.writeAsBytes(bytes);
        //     largeIcon = FilePathAndroidBitmap(filePath);
        //   } catch (e) {
        //     print('⚠️ Failed to load profile picture: $e');
        //   }
        // }

        // ✅ Prepare notification details
        final androidDetails = AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          importance: Importance.max,
          priority: Priority.high,
          // largeIcon: largeIcon,
          styleInformation: const DefaultStyleInformation(true, true),
          category: AndroidNotificationCategory.message,
        );

        final notificationDetails = NotificationDetails(android: androidDetails);

        // ✅ Title based on chat type
        final String title =
        chatType == 'GROUP' ? '$groupName - $senderName' : senderName;

        // ✅ Show the notification
        await flutterLocalNotificationsPlugin.show(
          DateTime.now().millisecondsSinceEpoch ~/ 1000, // unique id
          title,
          messageText,
          notificationDetails,
          payload: chatId, // pass chatId for navigation when tapped
        );

        print('✅ Chat message notification shown for $senderName');
      } catch (e) {
        print('❌ Error showing chat message notification: $e');
      }
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
      handle: (callType == 'video' || callType == 'groupVideo') ? 'Video Call' : 'Voice Call',
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
        if (callData['callType'] == 'voice') {
          Navigator.push(
              navigatorKey.currentContext!,
              MaterialPageRoute(
                builder: (_) => VoiceCallScreen1(
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
        }
        else if (callData['callType'] == 'groupVoice'){
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
          navigatorKey.currentState?.pushNamed(
            '/chat',
            arguments: {'chatId': chatId},
          );
        }
      },
    );
  }

  ///  Show message notification (for chat messages)

  Future<void> _showMessageNotification(Map<String, dynamic> data) async {
    final chatType = data['chatType'] ?? 'PRIVATE';
    final chatId = data['chatId'] ?? '';
    final senderName = data['name'] ?? 'Someone';
    final message = data['message'] ?? 'New message';

    String title;
    String body;

    if (chatType == 'GROUP') {
      // Example: "Developers Team" → "Yashraj Deshmukh: Hey everyone!"
      final groupName = data['groupName'] ?? 'Group Chat';
      title = groupName;
      body = '$senderName: $message';
    } else {
      // Example: "Yashraj Deshmukh" → "Hey!"
      title = senderName;
      body = message;
    }
    // final profilePicUrl = 'https://picsum.photos/200/300';
    //
    // final person = Person(
    //   name: senderName,
    //   icon: profilePicUrl.isNotEmpty
    //       ? BitmapFilePathAndroidIcon(profilePicUrl) // Needs local file
    //       : const BitmapFilePathAndroidIcon('@mipmap/ic_launcher'),
    // );
    //
    // final messagingStyle = MessagingStyleInformation(
    //   person,
    //   messages: [Message(message, DateTime.now(), person)],
    //   conversationTitle:
    //   chatType == 'GROUP' ? (data['groupName'] ?? 'Group Chat') : null,
    // );

    final AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'chat_messages_channel',
      'Chat Messages',
      channelDescription: 'Notifications for chat messages',
      importance: Importance.high,
      priority: Priority.high,
      // styleInformation: messagingStyle,
      // styleInformation: messagingStyle,
    );

    final NotificationDetails platformDetails =
    NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      platformDetails,
      payload: chatId,
    );
  }
}
