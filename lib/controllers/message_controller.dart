import 'dart:convert';

import 'package:chatify/Screens/video_call_screen.dart';
import 'package:chatify/Screens/voice_call_screen.dart';
import 'package:chatify/constants/apis.dart';
import 'package:chatify/controllers/profile_controller.dart';
import 'package:chatify/models/message.dart';
import 'package:chatify/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

class MessageController extends GetxController {
  final String baseUrl = APIs.url;
  final box = GetStorage();
  final profileController = Get.find<ProfileController>();


  // for load messages
  Future<List<Message>> fetchMessages(int chatId) async {
    try {
      final token = box.read("accessToken");

      // final res = await http.get(
      //   Uri.parse("$baseUrl/api/chats/$chatId/messages"),
      //   headers: {
      //     "Authorization": "Bearer $token",
      //   },
      // );

      final res = await ApiService.request(
          url: "$baseUrl/api/chats/$chatId/messages", method: "GET");

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        return data.map((e) => Message.fromJson(e)).toList();
      } else {
        print("Failed to load: ${res.statusCode} ${res.body}");
        return [];
      }
    } catch (e) {
      print("Error: $e");
      return [];
    }
  }

  // for send message
  Future<bool> sendMessage({
    required int chatId,
    required String content,
    String type = "TEXT",
  }) async {
    try {
      final token = box.read("accessToken");

      // final res = await http.post(
      //   Uri.parse("$baseUrl/api/chats/$chatId/messages"),
      //   headers: {
      //     "Authorization": "Bearer $token",
      //     "Content-Type": "application/json",
      //   },
      //   body: jsonEncode({
      //     "content": content,
      //     "type": type,
      //   }),
      // );

      final res = await ApiService.request(
          url: "$baseUrl/api/chats/$chatId/messages",
          method: "POST",
          body: {
            "content": content,
            "type": type,
          });

      if (res.statusCode == 200 || res.statusCode == 201) {
        print("Message sent: ${res.body}");
        return true;
      } else {
        print("Failed to send: ${res.statusCode} ${res.body}");
        return false;
      }
    } catch (e) {
      print("Error: $e");
      return false;
    }
  }

  Future<bool> deleteMessage(int chatId, int messageId) async {
    try {
      final token = box.read("accessToken");

      // final res = await http.delete(
      //   Uri.parse("$baseUrl/api/chats/$chatId/messages/$messageId"),
      //   headers: {
      //     "Authorization": "Bearer $token",
      //   },
      // );

      final res = await ApiService.request(
          url: "$baseUrl/api/chats/$chatId/messages/$messageId",
          method: "DELETE");

      if (res.statusCode == 200 || res.statusCode == 204) {
        print("Message deleted");
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

  // Update

  Future<bool> updateMessage({
    required int chatId,
    required int messageId,
    required String newContent,
  }) async {
    try {
      final token = box.read("accessToken");

      // final res = await http.patch(
      //   Uri.parse("$baseUrl/api/chats/$chatId/messages/$messageId"),
      //   headers: {
      //     "Authorization": "Bearer $token",
      //     "Content-Type": "application/json",
      //   },
      //   body: jsonEncode({
      //     "content": newContent,
      //   }),
      // );
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

  @override
  void onInit() {
    super.onInit();

    // When keyboard opens, hide emoji picker
    focusNode.addListener(() {
      if (focusNode.hasFocus) {
        isEmojiVisible.value = false;
      }
    });
  }

  // for call start

  Future<void> startCall(String receiverId, String channelId, bool isVideo, BuildContext context) async {
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

    final data = jsonDecode(response.body);
    print('scSDcsDcSD$data');

    if (response.statusCode == 200) {
      // Navigate immediately to call screen
      if (callType == "video") {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VideoCallScreen(
              channelId: data['channelId'],
              token: data['token'],
            ),
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VoiceCallScreen(
              channelId: data['channelId'],
              token: data['token'],
            ),
          ),
        );
      }
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
}
