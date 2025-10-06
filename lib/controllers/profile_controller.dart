import 'dart:convert';
import 'dart:io';
import 'package:chatify/constants/apis.dart';
import 'package:chatify/models/chat_user.dart';
import 'package:chatify/widgets/zego_initializer.dart';
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

      final res = await http.get(
        Uri.parse("$baseUrl/api/user/me"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

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

      final res = await http.patch(
        Uri.parse("$baseUrl/api/user/me"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode(user.toJson()),
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
  Future<void> fetchUserProfile() async {
     user.value = await getProfile();
     await box.write("userId", user.value?.id.toString());
     await box.write("userName", user.value?.firstName);
  }


  Future<void> pickImage() async {
    final XFile? image =
    await _picker.pickImage(source: ImageSource.gallery); // or camera

    if (image != null) {
      pickedImage.value = File(image.path);
    }
  }

  @override
  void onInit() async{
    await fetchUserProfile();
    await initZego(box.read("userId"), box.read("userName"));

    // TODO: implement onInit
    super.onInit();
  }

}
