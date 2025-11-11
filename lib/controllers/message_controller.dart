import 'dart:convert';

import 'package:chatify/Screens/group_video_screen.dart';
import 'package:chatify/Screens/group_voice_screen.dart';
import 'package:chatify/Screens/video_call_screen.dart';
import 'package:chatify/Screens/video_call_screen1.dart';
import 'package:chatify/Screens/voice_call_screen_1.dart';
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

  Future<void> startCall(String name,String receiverId, String channelId, bool isVideo,
      BuildContext context) async {
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

      // 2️⃣ End local Agora session
      // await AgoraRtcEngine.instance.leaveChannel();
      // await AgoraRtcEngine.instance.release();
      //
      // // 3️⃣ Close CallKit UI
      // await FlutterCallkitIncoming.endAllCalls();
      //
      // // 4️⃣ Navigate back to chat or home screen
      // if (navigatorKey.currentState != null) {
      //   navigatorKey.currentState!.popUntil((route) => route.isFirst);
      // }
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
    required String callType, // "groupvoice" or "groupvideo"
    required List<String> receiverIds,
  }) async {
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
        if (callType == "groupVideo") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GroupVideoCallScreen(
                  channelId: channel,
                  token: agoraToken,
                  callerId: callerId,
                  receiverIds: receiverIds),
            ),
          );
        } else if (callType == "groupVoice") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GroupVoiceCallScreen(
                  channelId: channel,
                  token: agoraToken,
                  callerId: callerId,
                  receiverIds: receiverIds),
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
}
