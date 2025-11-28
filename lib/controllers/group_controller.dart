import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:http_parser/http_parser.dart'; // <= Important

import 'package:chatify/Screens/main_screen.dart';
import 'package:chatify/constants/apis.dart';
import 'package:chatify/services/api_service.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class GroupController extends GetxController {
  var isLoading = false.obs;
  final String baseUrl = APIs.url;

  final box = GetStorage();

  final RxSet<int> selectedContacts = <int>{}.obs;
  final RxSet<int> currentGroupMembers = <int>{}.obs;

  void loadCurrentMembers(List<int> memberIds) {
    currentGroupMembers.assignAll(memberIds);
  }

  // for create group

  Future<void> createGroup({
    required String name,
    required File? groupImageFile,
    required List<int> memberIds,
    required int currentUserId,
  }) async {
    if (memberIds.isEmpty) {
      Get.snackbar("Error", "Select at least 1 contact");
      return;
    }

    try {
      isLoading.value = true;
      final token = box.read("accessToken");

      var request = http.MultipartRequest(
        "POST",
        Uri.parse("$baseUrl/api/groups"),
      );

      request.headers.addAll({
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      });

      final jsonString = jsonEncode({
        "name": name,
        "memberIds": memberIds.where((id) => id != currentUserId).toList(),
      });

      print("JSON DATA: $jsonString");

      request.files.add(
        http.MultipartFile.fromString(
          "data",
          jsonString,
          contentType: MediaType("application", "json"),
        ),
      );

      if (groupImageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            "groupImage",
            groupImageFile.path,
          ),
        );
      } else {
        final byteData =
            await rootBundle.load('assets/images/group_default.png');
        final bytes = byteData.buffer.asUint8List();

        request.files.add(
          http.MultipartFile.fromBytes(
            'groupImage',
            bytes,
            filename: 'group_default.png',
            contentType: MediaType('image', 'png'),
          ),
        );
      }

      print("HEADERS: ${request.headers}");
      print("FILES: ${request.files}");

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      isLoading.value = false;

      print("STATUS: ${response.statusCode}");
      print("BODY: $responseBody");

      if (response.statusCode == 200 || response.statusCode == 201) {
        Get.snackbar("Success", "Group created successfully");
        Get.offAll(() => MainScreen());
      } else {
        Get.snackbar("Error", "Failed: ${response.statusCode}");
      }
    } catch (e) {
      isLoading.value = false;
      print("EXCEPTION: $e");
    }
  }

  // for edit group name or image

  Future<void> updateGroup({
    required int groupId,
    String? newName,
    File? newGroupImageFile,
  }) async {
    final token = box.read("accessToken");
    try {
      var uri = Uri.parse("$baseUrl/api/groups/$groupId");
      var request = http.MultipartRequest("PATCH", uri);

      // Add authorization header
      request.headers['Authorization'] = "Bearer $token";
      request.headers['Accept'] = "application/json";

      final jsonString = jsonEncode({
        "name": newName,
      });

      request.files.add(
        http.MultipartFile.fromString(
          "data",
          jsonString,
          contentType: MediaType("application", "json"),
        ),
      );

      /// Add image file only if provided
      if (newGroupImageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            "groupImage",
            newGroupImageFile.path,
          ),
        );
      }

      print("FIELDS: ${request.fields}");
      print("HEADERS: ${request.headers}");

      var response = await request.send();
      var responseData = await http.Response.fromStream(response);

      print("STATUS: ${response.statusCode}");
      print("BODY: ${responseData.body}");
      if (response.statusCode == 200) {
        Get.snackbar(
          "Success",
          "Group updated successfully",
        );
      } else {
        Get.snackbar(
          "Error",
          "Failed to update group",
        );
      }
    } catch (e) {
      print("EXCEPTION: $e");

      Get.snackbar(
        "Error",
        e.toString(),
      );
    }
  }

  var pickedImage = Rx<File?>(null);

  final ImagePicker _picker = ImagePicker();

  Future<void> pickImage(ImageSource source) async {
    final XFile? image =
        await _picker.pickImage(source: source, imageQuality: 20);

    if (image != null) {
      pickedImage.value = File(image.path);
    }
  }

  Future<void> editImage(ImageSource source, int groupId) async{
    final XFile? image =
    await _picker.pickImage(source: source, imageQuality: 20);
    if (image != null) {
      pickedImage.value = File(image.path);
      await updateGroup(groupId: groupId, newGroupImageFile: pickedImage.value);
    }
  }

  // for add member

  Future<void> addMembers({
    required int groupId,
    required List<int> memberIds,
  }) async {
    final body = {"memberIds": memberIds};

    try {
      isLoading.value = true;
      final response = await ApiService.request(
          url: "$baseUrl/api/groups/$groupId/members",
          method: "POST",
          body: body);

      isLoading.value = false;
      if (response.statusCode == 200) {
        Get.snackbar("Success", "Members added successfully");
        selectedContacts.clear();
        Navigator.pop(Get.context!);
      } else {
        print("Failed to add members: ${response.body}");
      }
    } catch (e) {
      isLoading.value = false;
      Get.snackbar("Error", "Something went wrong");
    }
  }

  // for delete group (admin)

  Future<void> deleteGroup({
    required int groupId,
  }) async {
    try {
      isLoading.value = true;
      final response = await ApiService.request(
          url: "$baseUrl/api/groups/$groupId", method: "DELETE");

      isLoading.value = false;
      if (response.statusCode == 200) {
        Get.snackbar("Success", "Group deleted successfully");
        Get.offAll(() => MainScreen());
      } else {
        Get.snackbar("Error", "Failed to delete group: ${response.body}");
      }
    } catch (e) {
      isLoading.value = false;
      Get.snackbar("Error", "Something went wrong");
    }
  }

  // for remove member (admin only)

  Future<void> removeMember({required int groupId, required int memberId}) async {
    try {
      isLoading.value = true;
      final response = await ApiService.request(
       method: "DELETE",
        url: "$baseUrl/api/groups/$groupId/members/$memberId"
      );

      isLoading.value = false;

      if (response.statusCode == 200) {
        Get.snackbar("Success", "Member removed");
        Navigator.pop(Get.context!);
        // Get.offAll(() => MainScreen());
      } else {
        Get.snackbar("Error", "Failed to remove member");
      }
    } catch (e) {
      isLoading.value = false;
      print("Delete Member Error: $e");
      Get.snackbar("Error", "Something went wrong");
    }
  }


  // For exit group (except admin)

  Future<void> exitGroup({
    required int groupId,
  }) async {
    try {
      isLoading.value = true;
      final response = await ApiService.request(
          url: "$baseUrl/api/groups/$groupId/exit", method: "POST");

      isLoading.value = false;
      if (response.statusCode == 200) {
        Get.snackbar("Success", "You have left the group successfully");
        Get.offAll(() => MainScreen());
      } else {
        Get.snackbar("Error", "Failed to exit group: ${response.body}");
      }
    } catch (e) {
      isLoading.value = false;
      Get.snackbar("Error", "Something went wrong");
    }
  }

  void onTap(int id) {
    if (selectedContacts.contains(id)) {
      selectedContacts.remove(id);
    } else {
      selectedContacts.add(id);
    }
    update();
  }

  @override
  void onClose() {
    // TODO: implement onClose
    super.onClose();
    selectedContacts.clear();
  }
}
