import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:chatify/constants/apis.dart';
import 'package:chatify/controllers/chat_screen_controller.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

class SocketService extends GetxService with WidgetsBindingObserver{

  StreamSubscription? _connectivitySubscription;
  int _reconnectAttempts = 0;
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

  int? _currentActiveChatId;

  final Set<int> _deliveredCache = {};
  final Set<int> _readCache = {};
  final Set<String> _receiptCache = {};



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

  // void connect() {
  //   if (isConnected.value || _connecting) return;
  //
  //   final token = box.read("accessToken");
  //   if (token == null) {
  //     debugPrint("⛔ Socket connect skipped: no token");
  //     _connecting = false; // 🔴 RESET
  //     return;
  //   }
  //
  //   _connecting = true;
  //
  //   final wsUrl = "${APIs.url.replaceFirst("http", "ws")}/ws";
  //
  //   _client = StompClient(
  //     config: StompConfig(
  //       url: wsUrl,
  //       stompConnectHeaders: {"Authorization": "Bearer $token"},
  //       webSocketConnectHeaders: {"Authorization": "Bearer $token"},
  //       onConnect: (_) {
  //         _reconnectAttempts = 0;
  //         isConnected.value = true;
  //         _connecting = false;
  //         sendOnline(true);
  //
  //         startHeartbeat();
  //         subscribeToReceipts();
  //         for (final action in _pendingSubscriptions) {
  //           action();
  //         }
  //         _pendingSubscriptions.clear();
  //         debugPrint("✅ GLOBAL SOCKET CONNECTED");
  //       },
  //       heartbeatOutgoing: const Duration(seconds: 10), // Ping server every 10s
  //       heartbeatIncoming: const Duration(seconds: 10), // Expect pong from server every 10s
  //
  //       reconnectDelay: _calculateBackoff(),
  //       onDisconnect: (_) {
  //         _handleCleanup();
  //         Future.delayed(const Duration(seconds: 3), connect);
  //         debugPrint("🔌 GLOBAL SOCKET DISCONNECTED");
  //       },
  //       onWebSocketError: (e) {
  //         _handleCleanup();
  //         Future.delayed(const Duration(seconds: 3), connect);
  //         debugPrint("❌ WS ERROR $e");
  //       },
  //     ),
  //   );
  //
  //   _client.activate();
  // }
  void connect() {
    if (isConnected.value || _connecting) return;

    final token = box.read("accessToken");
    if (token == null) {
      debugPrint("⛔ Socket connect skipped: no token");
      _connecting = false;
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
          _reconnectAttempts = 0; // Reset counter on success
          isConnected.value = true;
          _connecting = false;
          sendOnline(true);
          startHeartbeat();
          subscribeToReceipts();

          // Check if we need to restore active chat state after a crash/drop
          if (_currentActiveChatId != null) {
            setActiveChat(_currentActiveChatId!);
          }

          for (final action in _pendingSubscriptions) {
            action();
          }
          _pendingSubscriptions.clear();
          debugPrint("✅ GLOBAL SOCKET CONNECTED");
        },
        heartbeatOutgoing: const Duration(seconds: 10),
        heartbeatIncoming: const Duration(seconds: 10),

        // Let the STOMP client handle the timing using your backoff function
        reconnectDelay: _calculateBackoff(),

        onDisconnect: (_) {
          _handleCleanup();
          debugPrint("🔌 GLOBAL SOCKET DISCONNECTED");

        },
        onWebSocketError: (e) {
          _handleCleanup();
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

  void _handleBulkReadUpdate(int chatId) {
    if (!Get.isRegistered<ChatScreenController>()) return;

    final ctrl = Get.find<ChatScreenController>();

    for (final msg in ctrl.messages) {
      if (msg.roomId == chatId && !msg.isRead.value) {
        msg.isRead.value = true;
      }
    }
  }


  void subscribeToReceipts() {

    _client.subscribe(
      destination: '/user/queue/messages/status',
      callback: (frame) {
        if (frame.body != null) {
          print('🟢 MESSAGE STATUS UPDATE received: ${frame.body}');
          final data = jsonDecode(frame.body!);
          _handleFullMessageUpdate(data);
        }
      },
    );

    _client.subscribe(
      destination: '/user/queue/receipts/chat-opened-confirmation',
      callback: (frame) {
        if (frame.body != null) {
          final data = jsonDecode(frame.body!);
          if (data['success'] == true) {
            final chatId = data['chatId'];
            _handleBulkReadUpdate(chatId);
          }
        }
      },
    );

    // Existing subscriptions for sender's receipts
    _client.subscribe(
      destination: '/user/queue/receipts/delivered',
      callback: (frame) {
        if (frame.body != null) {
          print('🟢 DELIVERY received: ${frame.body}');
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
          print('🟢 READ received: ${frame.body}');
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

  void _handleFullMessageUpdate(Map<String, dynamic> data) {
    final messageId = data['id'];

    if (!Get.isRegistered<ChatScreenController>()) return;

    final chatController = Get.find<ChatScreenController>();

    final msg = chatController.messages.firstWhereOrNull(
          (m) => m.id == messageId,
    );

    if (msg == null) return;

    // Update all status fields from the fresh message data
    msg.isDelivered.value = data['isDelivered'] ?? false;
    msg.isRead.value = data['isRead'] ?? false;

    if (data['deliveredAt'] != null) {
      msg.deliveredAt.value = DateTime.tryParse(data['deliveredAt']);
    }

    if (data['readAt'] != null) {
      msg.readAt.value = DateTime.tryParse(data['readAt']);
    }

    chatController.messages.refresh();

    print('✅ Message $messageId status updated: delivered=${msg.isDelivered.value}, read=${msg.isRead.value}');
  }


  void _handleReceiptUpdate(int messageId, String status, String timestamp,dynamic chatId) {

    final key = "$messageId-$status-$timestamp";
    if (_receiptCache.contains(key)) return;
    _receiptCache.add(key);
    if (_receiptCache.length > 2000) {
      _receiptCache.remove(_receiptCache.first);
    }

    print('🟡 _handleReceiptUpdate called: messageId=$messageId, timestamp=$timestamp, chatId=$chatId');
    final activeChatId = box.read("activeChatId");
    final isActive = activeChatId == chatId;
    if (!isActive) {
      debugPrint("📦 Receipt for background chat $chatId");
    }

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
    chatController.messages.refresh();

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

          final chatId = data['roomId'];
          final senderId = data['senderId'];
          final messageId = data['id'];

          onMessage(data);
          if (senderId == myId) {
            debugPrint("⚠️ Skipping receipt - this is my own message $messageId");
            return;
          }

          if (_currentActiveChatId == chatId) {
            if (!_deliveredCache.contains(messageId)) {
              _deliveredCache.add(messageId);
              sendDeliveryReceipt(chatId, messageId, senderId);
            }

            if (!_readCache.contains(messageId)) {
              _readCache.add(messageId);
              sendReadReceipt(chatId, messageId, senderId);
            }
          }
          else {
            if (!_deliveredCache.contains(messageId)) {
              _deliveredCache.add(messageId);
              sendDeliveryReceipt(chatId, messageId, senderId);
            }
          }

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
    _client.send(
      destination: '/app/message.read',
      body: jsonEncode({
        "chatId": chatId,
        "messageId": messageId,
        "senderId": senderId,
      }),
    );
  }


  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _startConnectivityListener();
  }

  void _startConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      // connectivity_plus v6 returns a list. Check if any are valid.
      bool hasInternet = !results.contains(ConnectivityResult.none);

      if (hasInternet) {
        debugPrint("🌐 Internet Restored: Attempting reconnect...");
        if (!isConnected.value) {
          connect();
        }
      } else {
        debugPrint("🚫 Internet Lost: Marking socket as disconnected");
        _handleCleanup(); // Use the cleanup method from previous step
      }
    });
  }
  void _handleCleanup() {
    isConnected.value = false;
    _connecting = false;
    stopHeartbeat();
  }

  // --- Point 3: Exponential Backoff Implementation ---
  Duration _calculateBackoff() {
    _reconnectAttempts++;
    // Calculation: 2^attempts (e.g., 2s, 4s, 8s, 16s...)
    // .clamp(2, 60) ensures it never waits less than 2s or more than 60s
    int seconds = math.pow(2, _reconnectAttempts).toInt().clamp(2, 60);
    debugPrint("⏳ Backoff: Waiting $seconds seconds before next retry (Attempt #$_reconnectAttempts)");
    return Duration(seconds: seconds);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      debugPrint("🔄 App resumed - checking connection...");
      // If client exists but isn't active, or isConnected is false, reconnect.
      if (!isConnected.value || !_client.connected) {
        connect();
      }
    } else if (state == AppLifecycleState.paused) {
      debugPrint("💤 App paused - closing socket to save battery/resources");
      // Optionally disconnect here if you want to rely on FCM for background push
      disconnect();
    }
  }

  // 04-02-2026

  void markChatAsOpened(int chatId) {
    _client.send(
      destination: '/app/chat.opened',
      body: jsonEncode({"chatId": chatId}),
    );
  }


  void setActiveChat(int chatId) {
    _currentActiveChatId = chatId;
    box.write("activeChatId", chatId);

    _client.send(
      destination: '/app/chat.setActive',
      body: jsonEncode({"chatId": chatId}),
    );

    markChatAsOpened(chatId);
  }

  void clearActiveChat() {
    _currentActiveChatId = null;
    box.remove("activeChatId");

    _client.send(destination: '/app/chat.clearActive');
  }


  @override
  void onClose() {
    _connectivitySubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    // stopHeartbeat();
    super.onClose();
  }
}
