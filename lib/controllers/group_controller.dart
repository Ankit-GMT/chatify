import 'dart:convert';
import 'package:chatify/constants/apis.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

class GroupController extends GetxController {

  var isLoading = false.obs;
  final String baseUrl = APIs.url;

  final box = GetStorage();

  Future<void> createGroup({
    required String name,
    required String groupImageUrl,
    required List<int> memberIds,
    required int currentUserId,
  }) async {
    if (memberIds.isEmpty) {
      Get.snackbar("Error", "Select at least 1 contact");
      return;
    }

    final body = {
      "name": name,
      "groupImageUrl": groupImageUrl,
      "memberIds": memberIds
          .where((id) => id != currentUserId) // exclude yourself
          .toList(),
    };

    print("API Payload: $body");

    try {
      isLoading.value = true;
      final token = box.read("accessToken");
      final res = await http.post(
        Uri.parse("$baseUrl/api/groups"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(body),
      );

      isLoading.value = false;

      if (res.statusCode == 200 || res.statusCode == 201) {
        Get.snackbar("Success", "Group created successfully");

        print("Group Created: ${res.body}");
      } else {
        Get.snackbar("Error", "Failed: ${res.statusCode}");
        print("Error: ${res.body}");
      }
    } catch (e) {
      isLoading.value = false;
      Get.snackbar("Error", "Something went wrong");
      print("Exception: $e");
    }
  }
}
