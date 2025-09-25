import 'dart:convert';
import 'package:chatify/constants/apis.dart';
import 'package:chatify/models/chat_type.dart';
import 'package:chatify/models/chat_user.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

class UserController extends GetxController {

  var searchResults = <ChatUser>[].obs;
  var isLoading = false.obs;
  final String baseUrl = APIs.url;

  final box = GetStorage();

  Future<void> searchUsers(String phone) async {
    try {
      isLoading.value = true;

      final token = box.read("accessToken"); // Get stored JWT

      final res = await http.get(
        Uri.parse("$baseUrl/api/users/search?q=$phone"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      final data = jsonDecode(res.body);
      print("search... $data");

      if (res.statusCode==200) {
        List users = data ?? [];
        searchResults.value = users.map((u) => ChatUser.fromJson(u)).toList();
      } else {
        searchResults.clear();
        Get.snackbar("Error", data['error'] ?? "No users found");
      }
    } catch (e) {
      Get.snackbar("Error--", e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // All users
  var allChats = <ChatType>[].obs;
  var groupChats = <ChatType>[].obs;


  Future<void> getAllChats() async {
    try {
      isLoading.value = true;

      final token = box.read("accessToken"); // Get stored JWT

      final res = await http.get(
        Uri.parse("$baseUrl/api/chats"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      final data = jsonDecode(res.body);
      print("All chats... $data");

      if (res.statusCode==200) {
        List users = data ?? [];
        allChats.value = users.map((u) => ChatType.fromJson(u)).toList();
        groupChats.value = allChats.where((chat) => chat.type == "GROUP").toList();
      } else {
        searchResults.clear();
        Get.snackbar("Error", data['error'] ?? "No chats found");
      }
    } catch (e) {
      Get.snackbar("Error--", e.toString());
    } finally {
      isLoading.value = false;
    }
  }
  @override
  void onInit() {
    super.onInit();
    getAllChats();
  }
}
