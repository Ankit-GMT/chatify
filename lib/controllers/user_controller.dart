import 'dart:convert';
import 'package:chatify/constants/apis.dart';
import 'package:chatify/controllers/profile_controller.dart';
import 'package:chatify/controllers/tabBar_controller.dart';
import 'package:chatify/models/chat_type.dart';
import 'package:chatify/models/chat_user.dart';
import 'package:chatify/models/contact_model.dart';
import 'package:chatify/api_service.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
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

    // print("Create Chat Payload: $body");

    try {
      isLoading.value = true;

      // final res = await http.post(
      //   Uri.parse("$baseUrl/api/chats"),
      //   headers: {
      //     "Authorization": "Bearer $token",
      //     "Content-Type": "application/json",
      //   },
      //   body: jsonEncode(body),
      // );

      final res = await ApiService.request(
        url: "$baseUrl/api/chats",
        method: "POST",
        body: body,
      );

      isLoading.value = false;

      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body);
        // print("Chat Created, data: $data");
        tabController.getAllChats();
        return ChatType.fromJson(data);
      } else {
        // print("Failed to create chat: ${res.statusCode} ${res.body}");
        return null;
      }
    } catch (e) {
      isLoading.value = false;
      // print("Exception while creating chat: $e");
      return null;
    }
  }

  var user = ChatUser().obs;

  Future<void> fetchUserProfile(int userId) async {
    try {
      final box = GetStorage();
      final token = box.read("accessToken");

      // final res = await http.get(
      //   Uri.parse("$baseUrl/api/user/$userId"),
      //   headers: {
      //     "Authorization": "Bearer $token",
      //     "Content-Type": "application/json",
      //   },
      // );

      final res = await ApiService.request(
          url: "$baseUrl/api/user/$userId", method: "GET");

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);

        final Map<String, dynamic> userJson =
            body is Map && (body['id'] != null)
                ? body
                : (body['user'] ?? body['data'] ?? body);
        // print(userJson);

        user.value = ChatUser.fromJson(Map<String, dynamic>.from(userJson));
      } else {
        print("Failed to fetch profile: ${res.statusCode} ${res.body}");
      }
    } catch (e) {
      print("Error fetchUserProfile: $e");
    }
  }




  @override
  void onInit() {
    super.onInit();
    // getAllChats();
    // _loadContacts();
  }
}
