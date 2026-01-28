import 'dart:convert';
import 'dart:io';

import 'package:chatify/Screens/group_video_screen1.dart';
import 'package:chatify/Screens/group_voice_screen1.dart';
import 'package:chatify/Screens/media_preview_screen.dart';
import 'package:chatify/Screens/video_call_screen1.dart';
import 'package:chatify/Screens/voice_call_screen_1.dart';
import 'package:chatify/constants/apis.dart';
import 'package:chatify/controllers/chat_screen_controller.dart';
import 'package:chatify/controllers/profile_controller.dart';
import 'package:chatify/models/message.dart';
import 'package:chatify/services/api_service.dart';
import 'package:chatify/services/notification_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:media_scanner/media_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

class MessageController extends GetxController {
  final String baseUrl = APIs.url;
  final box = GetStorage();
  var isLoading = false.obs;

  //For  web sockets

  late StompClient stompClient;

  var isSocketConnected = false.obs;
  var typingUsers = <int, bool>{}.obs;

  void connectSocket() {
    final token = box.read("accessToken");

    final wsUrl = "${baseUrl.replaceFirst("http", "ws")}/ws";

    stompClient = StompClient(
      config: StompConfig(
        url: wsUrl,
        stompConnectHeaders: {
          "Authorization": "Bearer $token",
        },
        webSocketConnectHeaders: {
          "Authorization": "Bearer $token",
        },
        onConnect: onSocketConnected,
        onWebSocketError: (error) {
          debugPrint("❌ Socket error: $error");
        },
        onStompError: (frame) {
          debugPrint("❌ STOMP error: ${frame.body}");
        },
        onDisconnect: (frame) {
          debugPrint("🔌 Socket disconnected");
        },
      ),
    );

    stompClient.activate();
  }



  void onSocketConnected(StompFrame frame) {
    isSocketConnected.value = true;
    debugPrint("✅ Socket connected");

    stompClient.subscribe(
      destination: "/user/queue/messages",
      callback: (frame) {
        final data = jsonDecode(frame.body!);
        final message = Message.fromJson(data);

        final chatController = Get.find<ChatScreenController>();

        //  add only if belongs to current chat
        if (message.roomId == chatController.chatId) {
          // prevent duplicates
          if (!chatController.messages.any((m) => m.id == message.id)) {
            chatController.messages.add(message);
            chatController.messages.refresh();
          }
        }
      },
    );
  }



  Future<bool> sendMessageWs({
    required int chatId,
    required int recipientId,
    required String content,
    String type = "TEXT",
  }) async {
    if (!isSocketConnected.value) return false;

    stompClient.send(
      destination: "/app/send",
      body: jsonEncode({
        "roomId": chatId,
        "recipientId": recipientId,
        "content": content,
        "type": type,
      }),
    );

    return true;
  }


  void sendTyping(int chatId) {
    if (!isSocketConnected.value) return;

    stompClient.send(
      destination: "/app/chat.typing/$chatId",
      body: jsonEncode({"typing": true}),
    );
  }



  // for send message
  // Future<bool> sendMessage({
  //   required int chatId,
  //   required String content,
  //   String type = "TEXT",
  // }) async {
  //   try {
  //     isLoading.value = true;
  //     final res = await ApiService.request(
  //         url: "$baseUrl/api/chats/$chatId/messages",
  //         method: "POST",
  //         body: {
  //           "content": content,
  //           "type": type,
  //         });
  //
  //     isLoading.value = false;
  //
  //     if (res.statusCode == 200 || res.statusCode == 201) {
  //       debugPrint("Message sent: ${res.body}");
  //
  //       return true;
  //     } else {
  //       debugPrint("Failed to send: ${res.statusCode} ${res.body}");
  //       return false;
  //     }
  //   } catch (e) {
  //     isLoading.value = false;
  //     debugPrint("Error: $e");
  //     return false;
  //   }
  // }

  Future<bool> deleteMessage(int chatId, int messageId) async {
    try {
      final res = await ApiService.request(
          url: "$baseUrl/api/chats/$chatId/messages/$messageId",
          method: "DELETE");

      if (res.statusCode == 200 || res.statusCode == 204) {
        debugPrint("Message deleted");
        await removeSavedPath(messageId);
        return true;
      } else {
        debugPrint("Failed to delete: ${res.statusCode} ${res.body}");
        return false;
      }
    } catch (e) {
      debugPrint("Error: $e");
      return false;
    }
  }

  Future<void> removeSavedPath(int messageId) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove("msgFile_$messageId");
  }

  // Update

  Future<bool> updateMessage({
    required int chatId,
    required int messageId,
    required String newContent,
  }) async {
    try {
      final res = await ApiService.request(
          url: "$baseUrl/api/chats/$chatId/messages/$messageId",
          method: "PATCH",
          body: {
            "content": newContent,
          });

      if (res.statusCode == 200) {
        debugPrint("Message updated: ${res.body}");
        return true;
      } else {
        debugPrint("Failed to update: ${res.statusCode} ${res.body}");
        return false;
      }
    } catch (e) {
      debugPrint("Error: $e");
      return false;
    }
  }

  // for emoji

  final FocusNode focusNode = FocusNode();

  var isEmojiVisible = false.obs;

  // for call start
  var isVoiceCallOn = false.obs;
  var isVideoCallOn = false.obs;

  Future<void> startCall(
    String name,
    String receiverId,
    String channelId,
    bool isVideo,
    BuildContext context,
  ) async {

    if (isVoiceCallOn.value || isVideoCallOn.value) return;
    final profileController = Get.find<ProfileController>();

    if(isVideo){
      isVideoCallOn.value = true;
    }else{
      isVoiceCallOn.value = true;
    }


    final callType = isVideo ? "video" : "voice";
    final Uri url = Uri.parse("$baseUrl/api/call/invite");


    try {
      final user = profileController.user.value;
      if (user == null) return;

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "channelId": channelId,
          "receiverId": receiverId,
          "callerId": user.id.toString(),
          "callerName": user.firstName,
          "callType": callType,
        }),
      );

      if (response.statusCode != 200) {
        debugPrint("Call API failed: ${response.body}");
        return;
      }

      final data = jsonDecode(response.body);

      NotificationService().showCallerOngoingCallNotification({
        "callerId": user.id.toString(),
        "receiverId": receiverId,
        "callerName": user.firstName,
        "receiverName": name,
        "channelId": channelId,
        "token": data['agoraToken'],
        "callType": callType,
      });

      _navigateToCallScreen(
        context: context,
        isVideo: isVideo,
        name: name,
        userId: user.id.toString(),
        receiverId: receiverId,
        channelId: data['channelId'],
        token: data['agoraToken'],
      );
    } catch (e) {
      debugPrint("Error starting call: $e");
    }
    finally{
      isVideoCallOn.value = false;
      isVoiceCallOn.value = false;
    }
  }

  Future<void> retryCall({
    required String name,
    required String receiverId,
    required String channelId,
    required bool isVideo,
  }) async {
    final profileController = Get.find<ProfileController>();
    final user = profileController.user.value;
    if (user == null) return;

    final callType = isVideo ? "video" : "voice";

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/api/call/invite"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "channelId": channelId,
          "receiverId": receiverId,
          "callerId": user.id.toString(),
          "callerName": user.firstName,
          "callType": callType,
        }),
      );

      if (response.statusCode != 200) {
        debugPrint("Retry call failed: ${response.body}");
        return;
      }

      final data = jsonDecode(response.body);

      // Update ongoing notification
      NotificationService().showCallerOngoingCallNotification({
        "callerId": user.id.toString(),
        "receiverId": receiverId,
        "callerName": user.firstName,
        "receiverName": name,
        "channelId": data['channelId'],
        "token": data['agoraToken'],
        "callType": callType,
      });

      // DO NOT navigate again
      // You are already on call screen
    } catch (e) {
      debugPrint("Retry call error: $e");
    }
  }


  void _navigateToCallScreen({
    required BuildContext context,
    required bool isVideo,
    required String name,
    required String userId,
    required String receiverId,
    required String channelId,
    required String token,
  }) {
    final Widget screen = isVideo
        ? VideoCallScreen1(
            channelId: channelId,
            token: token,
            callerId: userId,
            receiverId: receiverId,
            name: name,
          )
        : VoiceCallScreen1(
            channelId: channelId,
            token: token,
            callerId: userId,
            receiverId: receiverId,
            name: name,
          );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  // for call end

  Future<void> endCall({
    required String channelId,
    // required int userId,
    required String endReason,
  }) async {
    final profileController = Get.find<ProfileController>();
    try {
      final user = profileController.user.value;
      if (user == null) return;
      //Tell backend to end the call for both users
      final response = await http.post(
        Uri.parse("$baseUrl/api/call/end"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "channelId": channelId,
          "userId": user.id,
          "reason": endReason
        }),
      );

      if (response.statusCode == 200) {
        print("✅ Call end request sent to backend");
      } else {
        print("⚠️ Failed to end call: ${response.body}");
      }
    } catch (e) {
      print("❌ Error ending call: $e");
    }
  }

  // for group call

  Future<void> startGroupCall(
      {required BuildContext context,
      required String channelId,
      required String callerId,
      required String callerName,
      required bool isVideo,
      required List<String> receiverIds,
      required int groupId}) async {
    final callType = isVideo ? "VIDEO" : "VOICE";
    try {
      final url = Uri.parse("$baseUrl/api/call/group/invite");

      final body = {
        "channelId": channelId,
        "callerId": callerId,
        "callerName": callerName,
        "callType": callType,
        "receiverIds": receiverIds,
        "groupId": groupId,
      };

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print(" Group call started: $data");

        final agoraToken = data["agoraToken"];
        final channel = data["channelId"];

        // Navigate to call screen
        if (callType == "VIDEO") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GroupVideoCallScreen1(
                  channelId: channel,
                  token: agoraToken,
                  callerId: callerId,
                  receiverIds: data["participants"]),
            ),
          );
        } else if (callType == "VOICE") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GroupVoiceCallScreen1(
                  channelId: channel,
                  token: agoraToken,
                  callerId: callerId,
                  receiverIds: data["participants"]),
            ),
          );
        }
      } else {
        print("⚠️ Failed to start group call: ${response.body}");
      }
    } catch (e) {
      print("❌ Error starting group call: $e");
    }
  }

  // for end group call
  Future<Map<String, dynamic>> endGroupCall({
    required String channelId,
    required String callerId,
    required List<String> receiverIds,
  }) async {
    final String apiUrl = '$baseUrl/api/call/group/end';

    final body = {
      "channelId": channelId,
      "callerId": callerId,
      "receiverIds": receiverIds,
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print(" Group call ended successfully: ${data['status']}");
        print(" Notified users: ${data['notifiedUsers']}");
        return data;
      } else {
        print(" Failed to end group call: ${response.body}");
        return {"error": "Failed to end group call"};
      }
    } catch (e) {
      print(" Exception while ending group call: $e");
      return {"error": e.toString()};
    }
  }

  void toggleEmojiPicker() {
    if (isEmojiVisible.value) {
      focusNode.requestFocus();
    } else {
      focusNode.unfocus();
    }
    isEmojiVisible.toggle();
  }

  // for send Media
  var isSending = false.obs;

  Future<void> sendMedia(
    String chatId,
    File file, {
    required String type, // "IMAGE", "VIDEO", "AUDIO", "DOCUMENT"
    String? caption,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      isSending.value = true;

      final res = await ApiService.sendMediaMessage(
        chatId: chatId,
        file: file,
        type: type,
        caption: caption ?? "",
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final message = Message.fromJson(data);

        await scanFileToGallery(file.path);

        //for storing local
        message.localPath = file.path;
        await prefs.setString("msgFile_${message.id}", file.path);

        print("$type SEND SUCCESS: $data");
        // Optionally update chat messages list
      } else {
        print("$type SEND FAILED: ${res.body}");
        Get.snackbar("Error", "Failed to send $type");
      }
    } catch (e) {
      print("SEND $type ERROR: $e");
      Get.snackbar("Error", e.toString());
    } finally {
      isSending.value = false;
    }
  }

  // For Image Picker

  final ImagePicker _picker = ImagePicker();

  Future<void> pickImage(ImageSource source, int chatId) async {
    final XFile? image =
        await _picker.pickImage(source: source, imageQuality: 20);

    if (image != null) {
      Navigator.push(
          Get.context!,
          MaterialPageRoute(
            builder: (context) => MediaPreviewScreen(
              filePath: image.path,
              chatId: chatId,
              type: "IMAGE",
            ),
          ));
    }
  }

  // For Video Picker

  Future<void> pickVideo(int chatId) async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);

    if (video != null) {
      Get.to(() => MediaPreviewScreen(
            filePath: video.path,
            chatId: chatId,
            type: "VIDEO",
          ));
    }
  }

  // For Audio Pick

  Future<void> pickAudio(int chatId) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
    );

    if (result != null) {
      Get.to(() => MediaPreviewScreen(
            filePath: result.files.single.path!,
            chatId: chatId,
            type: "AUDIO",
          ));
    }
  }

  // For Document Pick

  Future<void> pickDocument(int chatId) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'zip'],
    );

    if (result != null) {
      Get.to(() => MediaPreviewScreen(
            filePath: result.files.single.path!,
            chatId: chatId,
            type: "DOCUMENT",
          ));
    }
  }

  Future<void> scanFileToGallery(String path) async {
    try {
      await MediaScanner.loadMedia(path: path);
      print("Media scanned to gallery: $path");
    } catch (e) {
      print("Gallery scan failed: $e");
    }
  }

  @override
  void onInit() {
    super.onInit();
    connectSocket();
    // int chatId = Get.arguments ?? 10;
    // fetchChatType(chatId);
    // loadMessages(chatId);

    // When keyboard opens, hide emoji picker
    focusNode.addListener(() {
      if (focusNode.hasFocus) {
        isEmojiVisible.value = false;
      }
    });
  }

  @override
  void onClose() {
    // TODO: implement onClose
    stompClient.deactivate();
    super.onClose();
  }
}
