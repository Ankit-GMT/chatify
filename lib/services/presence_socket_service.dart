import 'dart:async';
import 'dart:convert';
import 'package:chatify/constants/apis.dart';
import 'package:chatify/controllers/chat_screen_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

class SocketService extends GetxService with WidgetsBindingObserver{
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

  Timer? _heartbeatTimer;

  void startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 20), (timer) {
      // THE FIX: Check if the client is physically connected before sending
      if (isConnected.value && _client.connected) {
        try {
          sendOnline(true);

          for (var userId in onlineUsers.keys) {
            requestUserStatus(userId);
          }
          debugPrint("Status Heartbeat: Syncing all user states");
        } catch (e) {
          debugPrint("Heartbeat failed: $e");
          // If a transmit fails, it's safer to stop the heartbeat until reconnect
          stopHeartbeat();
        }
      } else {
        // If we are not connected, stop the timer to prevent more errors
        stopHeartbeat();
      }
    });
  }

  void stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

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

          startHeartbeat();
          subscribeToReceipts();
          for (final action in _pendingSubscriptions) {
            action();
          }
          _pendingSubscriptions.clear();
          debugPrint("✅ GLOBAL SOCKET CONNECTED");
        },
        heartbeatOutgoing: const Duration(seconds: 10), // Ping server every 10s
        heartbeatIncoming: const Duration(seconds: 10), // Expect pong from server every 10s

        reconnectDelay: const Duration(seconds: 5),
        onDisconnect: (_) {
          isConnected.value = false;
          _connecting = false;
          stopHeartbeat();
          Future.delayed(const Duration(seconds: 3), connect);
          debugPrint("🔌 GLOBAL SOCKET DISCONNECTED");
        },
        onWebSocketError: (e) {
          _connecting = false;
          Future.delayed(const Duration(seconds: 3), connect);
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
    if (!isConnected.value) {
      // If not connected yet, queue it for when onConnect fires
      _pendingSubscriptions.add(() => sendOnline(status));
      return;
    }
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

          debugPrint("📥 Received Status: User $receivedId is $status");
        },
      );
      Future.delayed(const Duration(milliseconds: 500), () {
        requestUserStatus(userId);
      });
    });
  }

  // void subscribeToReceipts() {
  //   // 1. Listen for Delivery Receipts
  //   _client.subscribe(
  //     destination: '/user/queue/receipts/delivered',
  //     callback: (frame) {
  //       if (frame.body != null) {
  //         final data = jsonDecode(frame.body!);
  //         _handleReceiptUpdate(
  //           data['messageId'],
  //           'DELIVERED',
  //           data['deliveredAt'],
  //           data['chatId'],
  //         );
  //
  //       }
  //     },
  //   );
  //
  //   // 2. Listen for Read Receipts
  //   _client.subscribe(
  //     destination: '/user/queue/receipts/read',
  //     callback: (frame) {
  //       if (frame.body != null) {
  //         final data = jsonDecode(frame.body!);
  //         _handleReceiptUpdate(
  //           data['messageId'],
  //           'READ',
  //           data['readAt'],
  //           data['chatId'],
  //         );
  //
  //       }
  //     },
  //   );
  // }

  void subscribeToReceipts() {
    // Existing subscriptions for sender's receipts
    _client.subscribe(
      destination: '/user/queue/receipts/delivered',
      callback: (frame) {
        if (frame.body != null) {
          final data = jsonDecode(frame.body!);
          _handleReceiptUpdate(
            data['messageId'],
            'DELIVERED',
            data['deliveredAt'],
            data['chatId'],
          );
        }
      },
    );

    _client.subscribe(
      destination: '/user/queue/receipts/read',
      callback: (frame) {
        if (frame.body != null) {
          final data = jsonDecode(frame.body!);
          _handleReceiptUpdate(
            data['messageId'],
            'READ',
            data['readAt'],
            data['chatId'],
          );
        }
      },
    );

    // 🆕 NEW: Subscribe to confirmations for the reader
    _client.subscribe(
      destination: '/user/queue/receipts/read-confirmation',
      callback: (frame) {
        print('🟢 READ CONFIRMATION received: ${frame.body}');
        if (frame.body != null) {
          final data = jsonDecode(frame.body!);
          if (data['success'] == true) {
            _handleReceiptUpdate(
              data['messageId'],
              'READ',
              data['readAt'],
              data['chatId'],
            );
          }
        }
      },
    );

    _client.subscribe(
      destination: '/user/queue/receipts/delivered-confirmation',
      callback: (frame) {
        print('🟢 DELIVERY CONFIRMATION received: ${frame.body}');
        if (frame.body != null) {
          final data = jsonDecode(frame.body!);
          if (data['success'] == true) {
            _handleReceiptUpdate(
              data['messageId'],
              'DELIVERED',
              data['deliveredAt'],
              data['chatId'],
            );
          }
        }
      },
    );
  }


  void _handleReceiptUpdate(int messageId, String status, String timestamp,dynamic chatId) {
    print('🟡 _handleReceiptUpdate called: messageId=$messageId, timestamp=$timestamp, chatId=$chatId');
    final activeChatId = box.read("activeChatId");
    if (activeChatId == null || activeChatId != chatId) return;

    if (!Get.isRegistered<ChatScreenController>()) return;

    final chatController = Get.find<ChatScreenController>();

    final int id = int.parse(messageId.toString());

    final msg = chatController.messages.firstWhereOrNull(

          (m) => m.id == id,
    );


    if (msg == null) return;

    final parsedTime = DateTime.tryParse(timestamp);

    if (status == 'DELIVERED') {
      msg.isDelivered.value = true;
      if (parsedTime != null) msg.deliveredAt.value = parsedTime;
    }

    if (status == 'READ') {
      msg.isRead.value = true;
      if (parsedTime != null) msg.readAt.value = parsedTime;
    }
  }

  void subscribeGroupReceipts(int chatId) {
    _safeSubscribe(() {
      _client.subscribe(
        destination: '/topic/chat/$chatId/receipts/read',
        callback: (frame) {
          final data = jsonDecode(frame.body!);
          _handleReceiptUpdate(
            data['messageId'],
            'READ',
            data['readAt'],
            data['chatId'],
          );

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
            if (isTyping) {
              typingUsers[userId] = true;
            } else {
              // Remove the key entirely when they stop typing
              typingUsers.remove(userId);
            }
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
  void _safeSubscribe(VoidCallback action) async{
    int retry = 0;
    while (!isConnected.value && retry < 10) {
      await Future.delayed(Duration(milliseconds: 200));
      retry++;
    }
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
  void sendDeliveryReceipt(int chatId, int messageId, int senderId) {
    final Map<String, dynamic> payload = {
      "chatId": chatId,
      "messageId": messageId,
      "senderId": senderId,
    };
    _client.send(
      destination: '/app/message.delivered',
      body: jsonEncode(payload),
    );
  }

  void sendReadReceipt(int chatId, int messageId, int senderId) {

    print("send receipt -------");
    final Map<String, dynamic> payload = {
      "chatId": chatId,
      "messageId": messageId,
      "senderId": senderId,
    };
    _client.send(
      destination: '/app/message.read.new',
      body: jsonEncode(payload),
    );
  }
  // void subscribeReadStatus(int messageId) {
  //   _safeSubscribe(() {
  //     _client.subscribe(
  //       destination: "/topic/message/$messageId/read",
  //       callback: (frame) {
  //         final data = jsonDecode(frame.body!);
  //         final readerId = data["userId"];
  //
  //         // Logic: Mark all messages sent by 'me' in this chat as 'read'
  //         // This usually involves updating your chatController.messages list
  //         debugPrint("📖 User $readerId read messages in chat $messageId");
  //       },
  //     );
  //   });
  // }

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Force a reconnection check when user opens the app again
      if (!isConnected.value || !_client.connected) {
        debugPrint("🔄 App resumed - Force Reconnecting Socket");
        connect();
      }
    }
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    // stopHeartbeat();
    super.onClose();
  }
}
