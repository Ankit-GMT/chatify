import 'dart:async';
import 'dart:convert';
import 'package:chatify/constants/apis.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

class SocketService extends GetxService {
  final box = GetStorage();

  late StompClient _client;
  final isConnected = false.obs;
  bool _connecting = false;

  final lastRawMsg = ''.obs;

  final onlineUsers = <int, bool>{}.obs;
  final lastSeenTimes = <int, DateTime>{}.obs;

  final typingUsers = <int, bool>{}.obs;
  Timer? _typingTimer;
  final List<VoidCallback> _pendingSubscriptions = [];


  StompClient get client => _client;

  void connect() {
    if (isConnected.value || _connecting) return;

    final token = box.read("accessToken");
    if (token == null) {
      debugPrint("⛔ Socket connect skipped: no token");
      _connecting = false; // 🔴 RESET
      return;
    }

    _connecting = true;

    final wsUrl = "${APIs.url.replaceFirst("http", "ws")}/ws";

    _client = StompClient(
      config: StompConfig(
        url: wsUrl,
        stompConnectHeaders: {"Authorization": "Bearer $token"},
        webSocketConnectHeaders: {"Authorization": "Bearer $token"},
        onConnect: (_) {
          isConnected.value = true;
          _connecting = false;
          sendOnline(true);
          for (final action in _pendingSubscriptions) {
            action();
          }
          _pendingSubscriptions.clear();
          debugPrint("✅ GLOBAL SOCKET CONNECTED");
        },
        onDisconnect: (_) {
          isConnected.value = false;
          _connecting = false;
          debugPrint("🔌 GLOBAL SOCKET DISCONNECTED");
        },
        onWebSocketError: (e) {
          _connecting = false;
          debugPrint("❌ WS ERROR $e");
        },
      ),
    );

    _client.activate();
  }

  void disconnect() {
    if (!isConnected.value) return;
    sendOnline(false);
    _client.deactivate();
    isConnected.value = false;
  }

  // -------- PRESENCE --------
  void sendOnline(bool status) {
    if (!isConnected.value) return;
    _client.send(
      destination: "/app/user.status",
      body: jsonEncode({"isOnline": status}),
    );
  }

  void subscribeToUserStatus(int userId) {
    _safeSubscribe(() {
      _client.subscribe(
        destination: "/topic/user/$userId/status",
        callback: (frame) {
          if (frame.body == null) return;

          final data = jsonDecode(frame.body!);

          // 🛡️ Ensure ID is an INT and Status is a BOOL
          final int receivedId = int.parse(data["userId"].toString());
          final bool status = data["online"] ?? data["isOnline"] ?? false;

          onlineUsers[receivedId] = status;
          print("Online Users:- $onlineUsers");

          if (!status && data["timestamp"] != null) {
            try {
              lastSeenTimes[receivedId] = DateTime.parse(data["timestamp"]);
            } catch (e) {
              debugPrint("Error parsing lastSeen: $e");
            }
          }

          onlineUsers.refresh();
          lastSeenTimes.refresh();
          requestUserStatus(userId);

          debugPrint("📥 Received Status: User $receivedId is $status");
        },
      );
    });
  }

  void requestUserStatus(int userId) {
    if (!isConnected.value) return;
    // This tells the server: "I just joined, please tell me if this specific user is online"
    _client.send(
      destination: "/app/user.status.request",
      body: jsonEncode({"targetUserId": userId}),
    );
  }


  // -------- TYPING --------
  void sendTyping(int chatId, bool isTyping) {
    if (!isConnected.value) return;
    _typingTimer?.cancel();
    _client.send(
      destination: "/app/chat.typing/$chatId",
      body: jsonEncode({"isTyping": isTyping}),
    );
    if (isTyping) {
      _typingTimer = Timer(const Duration(seconds: 1), () {
        sendTyping(chatId, false);
      });
    }
  }

  void subscribeTyping(int chatId) {
    _safeSubscribe(() {
      _client.subscribe(
        destination: "/topic/chat/$chatId/typing",
        callback: (frame) {
          final data = jsonDecode(frame.body!);
          final userId = data["userId"];
          final isTyping = data["typing"] as bool;
          final myId = box.read("userId");
          if (userId.toString() != myId.toString()) {
            typingUsers[userId] = isTyping;
            typingUsers.refresh();
          }
        },
      );
    });
  }


  // -------- MESSAGES --------
  void subscribeMyMessages(
      int myId,
      void Function(Map<String, dynamic>) onMessage,
      ) {
    _safeSubscribe(() {
      _client.subscribe(
        destination: "/topic/chat/user/$myId",
        callback: (frame) {
          if (frame.body == null) return;
          final Map<String, dynamic> data =
          jsonDecode(frame.body!) as Map<String, dynamic>;
          onMessage(data);
        },
      );
    });
  }
  void _safeSubscribe(VoidCallback action) {
    if (isConnected.value) {
      action();
    } else {
      _pendingSubscriptions.add(action);
    }
  }

  void sendMessage(Map body) {
      if (!isConnected.value) return;
      _client.send(destination: "/app/send", body: jsonEncode(body));
    }

  // -------- MESSAGE READ STATUS --------
  void sendReadReceipt(int chatId, int messageId) {
    if (!isConnected.value) return;

    // We send the chatId so the server knows which conversation was read
    _client.send(
      destination: "/app/message.read",
      body: jsonEncode({
        "messageId": messageId,
        "chatId": chatId
      }),
    );
    debugPrint("📤 Sent Read Receipt for Chat: $chatId");
  }
  void subscribeReadStatus(int messageId) {
    _safeSubscribe(() {
      _client.subscribe(
        destination: "/topic/message/$messageId/read",
        callback: (frame) {
          final data = jsonDecode(frame.body!);
          final readerId = data["userId"];

          // Logic: Mark all messages sent by 'me' in this chat as 'read'
          // This usually involves updating your chatController.messages list
          debugPrint("📖 User $readerId read messages in chat $messageId");
        },
      );
    });
  }
}
