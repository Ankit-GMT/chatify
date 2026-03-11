import 'dart:convert';
import 'package:chatify/constants/apis.dart';
import 'package:chatify/constants/custom_snackbar.dart';
import 'package:chatify/controllers/chat_screen_controller.dart';
import 'package:chatify/controllers/profile_controller.dart';
import 'package:chatify/controllers/tabBar_controller.dart';
import 'package:chatify/models/chat_type.dart';
import 'package:chatify/models/chat_user.dart';
import 'package:chatify/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class UserController extends GetxController {
  var isLoading = false.obs;
  final String baseUrl = APIs.url;
  final profileController = Get.put(ProfileController());
  final tabController = Get.put(TabBarController());

  final box = GetStorage();

  // for first time if user chat
  Future<dynamic> createChat(int otherUserId) async {
    final token = box.read("accessToken");

    final body = {
      "participantIds": [otherUserId],
      "type": "PRIVATE"
    };

    try {
      isLoading.value = true;

      final res = await ApiService.request(
        url: "$baseUrl/api/chats",
        method: "POST",
        body: body,
      );

      isLoading.value = false;

      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body);
        // debugPrint("Chat Created, data: $data");
        tabController.getAllChats();
        return ChatType.fromJson(data);
      } else {
        // debugPrint("Failed to create chat: ${res.statusCode} ${res.body}");
        return null;
      }
    } catch (e) {
      isLoading.value = false;
      // debugPrint("Exception while creating chat: $e");
      return null;
    }
  }

  var user = ChatUser().obs;

  Future<void> fetchUserProfile(int userId) async {
    try {
      final box = GetStorage();
      final token = box.read("accessToken");

      final res = await ApiService.request(
          url: "$baseUrl/api/user/$userId", method: "GET");

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);

        final Map<String, dynamic> userJson =
            body is Map && (body['id'] != null)
                ? body
                : (body['user'] ?? body['data'] ?? body);
        // debugPrint(userJson);

        user.value = ChatUser.fromJson(Map<String, dynamic>.from(userJson));
      } else {
        debugPrint("Failed to fetch profile: ${res.statusCode} ${res.body}");
      }
    } catch (e) {
      debugPrint("Error fetchUserProfile: $e");
    }
  }

  //Block user

  Future<void> blockUser({required int targetUserId}) async {
    final chatController = Get.find<ChatScreenController>();

    final chat = chatController.chatType;
    try {
      final body = {
        "targetUserId": targetUserId,
      };
      final response = await ApiService.request(
          url: '$baseUrl/api/users/block', method: 'POST', body: body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // isBlocked.value = true;
        chat.value?.isBlocked.value = true;
        chat.value?.isBlockedByMe.value = true;

        Get.back(); // close dialog
        CustomSnackbar.success("Blocked", "User has been blocked");
      } else {
        CustomSnackbar.error("Error", "Failed to block user");
      }
    } catch (e) {
      CustomSnackbar.error("Error", e.toString());
    }
  }

  //Unblock User

  Future<void> unblockUser({required int targetUserId}) async {
    final chatController = Get.find<ChatScreenController>();
    final chat = chatController.chatType;
    try {
      final response = await ApiService.request(
          url: '$baseUrl/api/users/block/$targetUserId', method: 'DELETE');

      if (response.statusCode == 200) {
        chat.value?.isBlocked.value = false;
        chat.value?.isBlockedByMe.value = false;
        Get.back();
        CustomSnackbar.success("Unblocked", "User has been unblocked");
      } else {
        CustomSnackbar.error("Error", "Failed to unblock user");
      }
    } catch (e) {
      CustomSnackbar.error("Error", e.toString());
    }
  }

// Report User

  final RxBool isReportLoading = false.obs;

  Future<void> reportUser({
    required int reportedUserId,
    required String reason,
    String? description,
  }) async {
    isReportLoading.value = true;

    final body = {
      "reportedUserId": reportedUserId,
      "reason": reason,
      "description": description ?? "",
    };
    try {
      final response = await ApiService.request(
          url: "$baseUrl/api/reports/user", method: 'POST', body: body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        Get.back(); // close bottom sheet
        CustomSnackbar.success(
            "Reported", "User has been reported successfully");
      } else {
        CustomSnackbar.error("Error", "Failed to submit report");
      }
    } catch (e) {
      CustomSnackbar.error("Error", e.toString());
    } finally {
      isReportLoading.value = false;
    }
  }

  @override
  void onInit() {
    super.onInit();
    // getAllChats();
    // _loadContacts();
  }
}
