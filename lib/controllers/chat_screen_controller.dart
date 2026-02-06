import 'dart:convert';
import 'dart:io';
import 'package:chatify/constants/apis.dart';
import 'package:chatify/constants/custom_snackbar.dart';
import 'package:chatify/controllers/message_controller.dart';
import 'package:chatify/models/chat_type.dart';
import 'package:chatify/models/message.dart';
import 'package:chatify/services/api_service.dart';
import 'package:chatify/services/presence_socket_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:media_scanner/media_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatScreenController extends GetxController {
  final int chatId;

  ChatScreenController({required this.chatId});

  final String baseUrl = APIs.url;

  var chatType = Rxn<ChatType>();
  var type = ''.obs;

  final socket = Get.find<SocketService>();
  final box = GetStorage();

  RxList<Message> messages = <Message>[].obs;

  var isLoading = true.obs;

  int? get otherUserId {
    final members = chatType.value?.members;
    if (members == null || members.length < 2) return null;
    final myId = box.read("userId");
    return (myId == members[0].userId) ? members[1].userId : members[0].userId;
  }

  Future<void> loadMessages(int id) async {
    final data = await fetchMessages(id);
    messages.value = data;

    // Trigger receipts for the other user for any message they sent that I haven't read
    final myId = box.read("userId");
    for (var msg in messages) {
      if (msg.senderId != myId && !msg.isRead.value) {
        socket.sendReadReceipt(chatId, msg.id, msg.senderId);
      }
    }

    await markChatAsRead(id);
    await initializeDownloads();
  }

  void fetchChatType(int id) async {
    final data = await fetchChatTypeDetails(id);
    chatType.value = data;
    type.value = chatType.value?.type ?? '';
  }

  Future<ChatType?> fetchChatTypeDetails(int chatId) async {
    try {
      isLoading.value = true;
      final res = await ApiService.request(
          url: "$baseUrl/api/chats/$chatId", method: "GET");

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return ChatType.fromJson(data);
      } else {
        print("Failed to load: ${res.statusCode} ${res.body}");
        return null;
      }
    } catch (e) {
      print("Error: $e");
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  // for load messages
  Future<List<Message>> fetchMessages(int chatId) async {
    try {
      final res = await ApiService.request(
          url: "$baseUrl/api/chats/$chatId/messages", method: "GET");

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        print("-=-= $data");
        // log(data.toString());
        return data.map((e) => Message.fromJson(e)).toList();
      } else {
        print("Failed to load: ${res.statusCode} ${res.body}");
        return [];
      }
    } catch (e) {
      print("Error:-= $e");
      return [];
    }
  }


  Future<Directory> getDownloadFolder() async {
    final storage = await Permission.storage.request();
    final manage = await Permission.manageExternalStorage.request();

    if (!storage.isGranted && !manage.isGranted) {
      throw Exception("Storage permission denied");
    }

    final folder = Directory("/storage/emulated/0/Chatify/Download");
    if (!folder.existsSync()) {
      folder.createSync(recursive: true);
    }
    return folder;
  }


  Future<void> downloadMedia(Message message) async {
    message.downloadProgress.value = 0;
    messages.refresh();

    final folder = await getDownloadFolder();

    final request = http.Request('GET', Uri.parse(message.fileUrl!));
    final response = await request.send();

    // Extract file name from Content-Disposition if available
    String? contentDisposition = response.headers['content-disposition'];
    String fileName;

    if (contentDisposition != null &&
        contentDisposition.contains('filename=')) {
      fileName = contentDisposition
          .split('filename=')[1]
          .replaceAll('"', '')
          .trim();
    } else {
      // Fallback to URL file name
      fileName = message.fileUrl!.split('/').last.split('?').first;
    }

    final savePath = "${folder.path}/$fileName";
    final file = File(savePath);

    if (file.existsSync()) {
      message.localPath.value = savePath;
      messages.refresh();
      return;
    }

    final totalBytes = response.contentLength ?? 0;
    int received = 0;
    final sink = file.openWrite();

    await response.stream.listen((chunk) {
      received += chunk.length;
      message.downloadProgress.value = received / totalBytes;
      messages.refresh();
      sink.add(chunk);
    }).asFuture();

    await sink.close();

    print("FILE SAVED: $savePath");
    message.localPath.value = savePath;

    //For gallary
    await scanFileToGallery(savePath);

    // for local save
    await saveLocalPath(message.id, savePath);

    messages.refresh();
  }


  Future<void> initializeDownloads() async {
    for (var msg in messages) {
      // Check SharedPreferences first
      final savedPath = await getLocalSavedPath(msg.id);

      if (savedPath != null && File(savedPath).existsSync()) {
        msg.localPath.value = savedPath;
        continue;
      }

      // Fallback to detect file by filename in folder
      if (msg.fileUrl != null) {
        final folder = Directory("/storage/emulated/0/Chatify/Download");
        final fileName = msg.fileUrl!.split('/').last.split('?').first;
        final localPath = "${folder.path}/$fileName";

        if (File(localPath).existsSync()) {
          msg.localPath.value = localPath;
          await saveLocalPath(msg.id, localPath); // save to preferences
        }
      }
    }

    messages.refresh();
  }


  Future<void> saveLocalPath(int messageId, String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("msgFile_$messageId", path);
  }

  Future<String?> getLocalSavedPath(int messageId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("msgFile_$messageId");
  }

  Future<void> scanFileToGallery(String path) async {
    try {
      await MediaScanner.loadMedia(path: path);
      print("Media scanned to gallery: $path");
    } catch (e) {
      print("Gallery scan failed: $e");
    }
  }

  // For chat lock individually

  Future<void> lockChat({
    required String chatId,
    required String pin,
  }) async {
    try {
      isLoading.value = true;
      final body = {
        "pin": pin,
      };

      final res = await ApiService.request(url: "$baseUrl/api/chats/$chatId/lock", method: "POST", body: body );


      final data = jsonDecode(res.body);
      debugPrint("Lock Chat Response: $data");

      if (res.statusCode == 200 && data['success'] == true) {
        CustomSnackbar.success(
          "Chat Locked",
          "This chat is now protected with a PIN",
        );

        // Optional: update local state
        chatType.value?.locked.value = true;
        chatType.refresh();

        Navigator.pop(Get.context!);

      } else {
        CustomSnackbar.error(
          "Error",
          data['message'] ?? "Failed to lock chat",
        );
      }
    } catch (e) {
      debugPrint("Lock Chat Error: $e");
      CustomSnackbar.error("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // For unlock

  Future<void> unlockChat({
    required String chatId,
  }) async {
    try {
      isLoading.value = true;

      final res = await ApiService.request(url: "$baseUrl/api/chats/$chatId/lock", method: 'DELETE');


      final data = jsonDecode(res.body);
      debugPrint("Unlock Chat Response: $data");

      if (res.statusCode == 200 && data['success'] == true) {
        CustomSnackbar.success("Chat Unlocked", "Chat lock removed successfully");

        // Update local state if needed
        chatType.value?.locked.value = false;
        chatType.refresh();

        Navigator.of(Get.context!).pop();
      } else {
        CustomSnackbar.error(
          "Error",
          data['message'] ?? "Failed to unlock chat",
        );
      }
    } catch (e) {
      CustomSnackbar.error("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> markChatAsRead(int chatId) async {
    try {
      final res = await ApiService.request(url: "$baseUrl/api/chats/$chatId/mark-read", method: "POST");

      if (res.statusCode == 200 || res.statusCode == 204) {
        return true;
      } else {
        debugPrint(
            "Mark Read Failed: ${res.statusCode} - ${res.body}");
        return false;
      }
    } catch (e) {
      debugPrint("Error in markChatAsRead: $e");
      return false;
    }
  }

  void onIncomingMessage(Message message) {
    if (message.roomId != chatId) return;

    if (!messages.any((m) => m.id == message.id)) {
      messages.add(message);
      messages.refresh();

      final myId = box.read("userId");
      if (message.senderId != myId) {
        socket.sendDeliveryReceipt(chatId, message.id, message.senderId);
        socket.sendReadReceipt(chatId, message.id, message.senderId);
      }
    }
  }




  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
    socket.setActiveChat(chatId);
    ever(chatType, (value) {
      if (value != null && otherUserId != null) {
        socket.subscribeToUserStatus(otherUserId!);
        socket.subscribeTyping(chatId);
        socket.subscribeToReceipts();
        // Subscribe to receipts from the OTHER person
      }
    });

    // 2. Logic to send READ receipts when new messages arrive
    debounce(messages, (List<Message> messageList) {
      if (messageList.isNotEmpty) {
        final lastMessage = messageList.last;
        final myId = box.read("userId");

        if (lastMessage.senderId != myId && !lastMessage.isRead.value) {
          socket.sendReadReceipt(chatId, lastMessage.id, lastMessage.senderId);
          socket.sendDeliveryReceipt(chatId, lastMessage.id, lastMessage.senderId);
        }
      }
    }, time: const Duration(milliseconds: 300));

    Get.find<MessageController>().subscribeToTyping(chatId);

    fetchChatType(chatId);
    loadMessages(chatId);
  }


  @override
  void onClose() {
    // TODO: implement onClose
    // socket.unsubscribeFromTyping();
    socket.clearActiveChat();
    super.onClose();
  }
}
