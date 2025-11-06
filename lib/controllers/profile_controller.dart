import 'dart:convert';
import 'dart:io';
import 'package:chatify/constants/apis.dart';
import 'package:chatify/constants/app_colors.dart';
import 'package:chatify/models/chat_user.dart';
import 'package:chatify/api_service.dart';
import 'package:chatify/widgets/zego_initializer.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class ProfileController extends GetxController {

  final String baseUrl = APIs.url;

  var pickedImage = Rx<File?>(null);

  final ImagePicker _picker = ImagePicker();

  final box = GetStorage();

  String? get token => box.read("accessToken");

  Rx<ChatUser?> user = Rx<ChatUser?>(null);

  Future<ChatUser?> getProfile() async {
    try {
      final token = box.read("accessToken");

      // final res = await http.get(
      //   Uri.parse("$baseUrl/api/user/me"),
      //   headers: {
      //     "Authorization": "Bearer $token",
      //     "Content-Type": "application/json",
      //   },
      // );
      final res =
          await ApiService.request(url: "$baseUrl/api/user/me", method: "GET");

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        final user = ChatUser.fromJson(data);

        print("Profile fetched: ${user.firstName} ${user.lastName}");

        return user;
      } else {
        print("Failed to fetch profile: ${res.body}");
        return null;
      }
    } catch (e) {
      print("Error in getProfile: $e");
      return null;
    }
  }

  // Edit Profile
  Future<bool> editProfile(ChatUser user) async {
    try {
      final token = box.read("accessToken");

      // final res = await http.patch(
      //   Uri.parse("$baseUrl/api/user/me"),
      //   headers: {
      //     "Authorization": "Bearer $token",
      //     "Content-Type": "application/json",
      //   },
      //   body: jsonEncode(user.toJson()),
      // );

      final res = await ApiService.request(
        url: "$baseUrl/api/user/me",
        method: "PATCH",
        body: user.toJson(),
      );

      if (res.statusCode == 200) {
        print("Profile updated: ${res.body}");
        return true;
      } else {
        print("Failed to update profile: ${res.body}");
        return false;
      }
    } catch (e) {
      print("Error in editProfile: $e");
      return false;
    }
  }

  // fetch user profile
  Future<void> fetchUserProfile() async {
    user.value = await getProfile();
    await box.write("userId", user.value?.id.toString());
    await box.write("userName", user.value?.firstName);
  }

  Future<void> pickImage(ImageSource source) async {
    final XFile? image =
        await _picker.pickImage(source: source);

    if (image != null) {
      pickedImage.value = File(image.path);
    }
  }

  @override
  void onInit() async {
    await fetchUserProfile();

    // TODO: implement onInit
    super.onInit();
  }

 // for showing options to pick image

  void showPickerBottomSheet() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        decoration:  BoxDecoration(
          color: Get.isDarkMode? AppColors.primary:AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a Photo'),
              onTap: () {
                pickImage(ImageSource.camera);
                Get.back();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                pickImage(ImageSource.gallery);
                Get.back();
              },
            ),
          ],
        ),
      ),
    );
  }
}
