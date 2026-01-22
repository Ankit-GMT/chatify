import 'dart:convert';
import 'dart:io';
import 'package:chatify/constants/apis.dart';
import 'package:chatify/constants/app_colors.dart';
import 'package:chatify/models/chat_user.dart';
import 'package:chatify/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';


class ProfileController extends GetxController {

  final String baseUrl = APIs.url;
  var isLoading = false.obs;

  var pickedImage = Rx<File?>(null);

  final ImagePicker _picker = ImagePicker();

  final box = GetStorage();

  String? get token => box.read("accessToken");

  Rx<ChatUser?> user = Rx<ChatUser?>(null);

  Future<ChatUser?> getProfile() async {
    try {
      final res =
          await ApiService.request(url: "$baseUrl/api/user/me", method: "GET");

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        final user = ChatUser.fromJson(data);

        debugPrint("Profile fetched: ${user.firstName} ${user.lastName}");

        return user;
      } else {
        debugPrint("Failed to fetch profile: ${res.body}");
        return null;
      }
    } catch (e) {
      debugPrint("Error in getProfile: $e");
      return null;
    }
  }

  // Edit Profile
  Future<bool> editProfile(ChatUser user) async {
    try {

      var uri = Uri.parse("$baseUrl/api/user/me");
      var request = http.MultipartRequest("PATCH", uri);

      // Add authorization header
      request.headers['Authorization'] = "Bearer $token";
      request.headers['Accept'] = "application/json";

      final jsonString = jsonEncode(user.toJson());

      request.files.add(
        http.MultipartFile.fromString(
          "data",
          jsonString,
          contentType: MediaType("application", "json"),
        ),
      );

      var res = await request.send();
      var responseData = await http.Response.fromStream(res);


      if (res.statusCode == 200) {
        debugPrint("Profile updated: ${responseData.body}");
        return true;
      } else {
        debugPrint("Failed to update profile: ${responseData.body}");
        return false;
      }
    } catch (e) {
      debugPrint("Error in editProfile: $e");
      return false;
    }
  }

  // fetch user profile
  Future<void> fetchUserProfile() async {
    user.value = await getProfile();
    await box.write("userId", user.value?.id);
  }

  // for profile image update
  Future<void> updateUserProfileImage(File imageFile) async {
    try {
      isLoading.value = true;

      final url = Uri.parse("$baseUrl/api/user/me");

      var request = http.MultipartRequest("PATCH", url);

      // Add authorization header
      request.headers["Authorization"] = "Bearer ${box.read("accessToken")}";

      request.files.add(
        http.MultipartFile.fromString(
          "data",
          jsonEncode({}),
          contentType: MediaType("application", "json"),
        ),
      );

      // Attach image
      request.files.add(
        await http.MultipartFile.fromPath(
          "profileImage",
          imageFile.path,
        ),
      );

      // Send request
      final streamedRes = await request.send();
      final response = await http.Response.fromStream(streamedRes);

      final data = jsonDecode(response.body);
      debugPrint("Profile image update response: $data");

      if (response.statusCode == 200) {
        Get.snackbar("Success", "Profile image updated!");
      } else {
        Get.snackbar("Error", data["message"] ?? "Could not update image");
      }
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }


  Future<void> pickImage(ImageSource source) async {
    final XFile? image =
        await _picker.pickImage(source: source,imageQuality: 20);

    if (image != null) {
      pickedImage.value = File(image.path);
    }
    await updateUserProfileImage(pickedImage.value!);
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
