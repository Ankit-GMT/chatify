import 'dart:convert';
import 'dart:io';

import 'package:chatify/Screens/group_video_screen.dart';
import 'package:chatify/Screens/group_voice_screen.dart';
import 'package:chatify/Screens/media_preview_screen.dart';
import 'package:chatify/Screens/video_call_screen1.dart';
import 'package:chatify/Screens/voice_call_screen_1.dart';
import 'package:chatify/constants/apis.dart';
import 'package:chatify/controllers/profile_controller.dart';
import 'package:chatify/models/message.dart';
import 'package:chatify/services/api_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:media_scanner/media_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MessageController extends GetxController {
  final String baseUrl = APIs.url;
  final box = GetStorage();
  var isLoading = false.obs;
  final profileController = Get.find<ProfileController>();


  // for send message
  Future<bool> sendMessage({
    required int chatId,
    required String content,
    String type = "TEXT",
  }) async {
    try {
      isLoading.value = true;
      final res = await ApiService.request(
          url: "$baseUrl/api/chats/$chatId/messages",
          method: "POST",
          body: {
            "content": content,
            "type": type,
          });

      isLoading.value = false;

      if (res.statusCode == 200 || res.statusCode == 201) {
        print("Message sent: ${res.body}");

        return true;
      } else {
        print("Failed to send: ${res.statusCode} ${res.body}");
        return false;
      }
    } catch (e) {
      isLoading.value = false;
      print("Error: $e");
      return false;
    }
  }

  Future<bool> deleteMessage(int chatId, int messageId) async {
    try {

      final res = await ApiService.request(
          url: "$baseUrl/api/chats/$chatId/messages/$messageId",
          method: "DELETE");

      if (res.statusCode == 200 || res.statusCode == 204) {
        print("Message deleted");
        await removeSavedPath(messageId);
        return true;
      } else {
        print("Failed to delete: ${res.statusCode} ${res.body}");
        return false;
      }
    } catch (e) {
      print("Error: $e");
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
        print("Message updated: ${res.body}");
        return true;
      } else {
        print("Failed to update: ${res.statusCode} ${res.body}");
        return false;
      }
    } catch (e) {
      print("Error: $e");
      return false;
    }
  }

  // for emoji

  final FocusNode focusNode = FocusNode();

  var isEmojiVisible = false.obs;

  // for call start

  Future<void> startCall(String name, String receiverId, String channelId,
      bool isVideo, BuildContext context) async {
    final callType = isVideo ? "video" : "voice";

    final response = await http.post(
      Uri.parse("$baseUrl/api/call/invite"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "channelId": channelId,
        "receiverId": receiverId,
        "callerId": profileController.user.value!.id.toString(),
        "callerName": profileController.user.value!.firstName,
        "callType": callType,
      }),
    );
    print(
        "resquested:-  $channelId - $receiverId - ${profileController.user.value!.id.toString()}");
    final data = jsonDecode(response.body);
    print('scSDcsDcSD$data');

    if (response.statusCode == 200) {
      // Navigate immediately to call screen
      if (callType == "video") {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VideoCallScreen1(
              channelId: data['channelId'],
              token: data['agoraToken'],
              callerId: profileController.user.value!.id.toString(),
              receiverId: receiverId,
              name: name,
            ),
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VoiceCallScreen1(
              channelId: data['channelId'],
              token: data['agoraToken'],
              callerId: profileController.user.value!.id.toString(),
              receiverId: receiverId,
              name: name,
            ),
          ),
        );
      }
    }
  }

  // for call end

  Future<void> endCall({
    required String channelId,
    required String callerId,
    required String receiverId,
  }) async {
    try {
      //Tell backend to end the call for both users
      final response = await http.post(
        Uri.parse("$baseUrl/api/call/end"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "channelId": channelId,
          "receiverId": receiverId,
          "callerId": callerId
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

  Future<void> startGroupCall({
    required BuildContext context,
    required String channelId,
    required String callerId,
    required String callerName,
    required bool isVideo,
    required List<String> receiverIds,
  }) async {
    final callType = isVideo ? "VIDEO" : "VOICE";
    try {
      final url = Uri.parse("$baseUrl/api/call/group/invite");

      final body = {
        "channelId": channelId,
        "callerId": callerId,
        "callerName": callerName,
        "callType": callType,
        "receiverIds": receiverIds,
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
              builder: (_) => GroupVideoCallScreen(
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
              builder: (_) => GroupVoiceCallScreen(
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
      print("⚠️ Exception while ending group call: $e");
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
}
