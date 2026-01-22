import 'dart:convert';
import 'dart:io';
import 'package:chatify/Screens/chat_background_preview.dart';
import 'package:chatify/constants/app_colors.dart';
import 'package:chatify/services/api_service.dart';
import 'package:chatify/constants/apis.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import '../models/chat_background.dart';
import '../controllers/chat_screen_controller.dart';
import 'package:http_parser/http_parser.dart';

class ChatBackgroundController extends GetxController {
  final int chatId;

  ChatBackgroundController(this.chatId);

  final box = GetStorage();
  final picker = ImagePicker();
  final viewMode = BackgroundViewMode.home.obs;


  final categories = <String>['All'].obs;
  final backgrounds = <ChatBackground>[].obs;
  final selectedCategory = "".obs;

  final isLoading = false.obs;

  @override
  void onInit() {
    fetchGallery();
    print("CATegories:- $categories");
    super.onInit();
  }

  // Background Gallery

  Future<void> fetchGallery() async {
    try {
      isLoading.value = true;

      final res = await ApiService.request(
        url: "${APIs.url}/api/backgrounds/gallery",
        method: "GET",
      );

      if (res.statusCode != 200) {
        throw Exception("Failed to load backgrounds");
      }

      final data = jsonDecode(res.body);

      categories.clear();
      backgrounds.clear();

      for (var cat in data['categories']) {
        categories.add(cat['category']);

        for (var bg in cat['backgrounds']) {
          backgrounds.add(ChatBackground.fromJson(bg));
        }
      }

      if (categories.isNotEmpty) {
        selectedCategory.value = categories.first;
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        "Unable to load wallpapers",
        snackPosition: SnackPosition.BOTTOM,
      );
      print("fetchGallery error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // Backgrounds by Category

  Future<void> fetchByCategory(String category) async {
    try {
      isLoading.value = true;
      selectedCategory.value = category;
      viewMode.value = BackgroundViewMode.category;

      final res = await ApiService.request(
        url: "${APIs.url}/api/backgrounds/category/$category",
        method: "GET",
      );

      if (res.statusCode != 200) {
        throw Exception("Failed to load category backgrounds");
      }

      final List list = jsonDecode(res.body);

      backgrounds.assignAll(
        list.map((e) => ChatBackground.fromJson(e)).toList(),
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "Unable to load $category wallpapers",
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }


  // Apply Background to Chat

  Future<void> applyBackground(ChatBackground bg) async {
    try {
      isLoading.value = true;

      final res = await ApiService.request(
        url: "${APIs.url}/api/backgrounds/set-for-chat/$chatId",
        method: "POST",
        body: {
          "backgroundId": bg.id,
        },
      );

      if (res.statusCode != 200 &&
          res.statusCode != 201) {
        throw Exception("Failed to set background");
      }

      final updatedChat = jsonDecode(res.body);

      final imageUrl = updatedChat['backgroundImageUrl'];

      // Cache locally
      box.write("chat_bg_$chatId", imageUrl);

      // Live update ChatScreen
      final chatController = Get.find<ChatScreenController>();
      chatController.chatType.update((c) {
        c?.backgroundImageUrl = imageUrl;
      });

      Get.back(); // close picker
      Get.snackbar("Success", "Chat Background Applied");
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to apply wallpaper",
        snackPosition: SnackPosition.BOTTOM,
      );
      print("applyBackground error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // Custom Gallery Image

  Future<void> uploadGalleryBackground(File file) async {
    try {
      isLoading.value = true;

      final accessToken = box.read("accessToken");

      final uri =
      Uri.parse("${APIs.url}/api/chats/$chatId/background");

      final request = http.MultipartRequest("POST", uri);

      request.headers["Authorization"] = "Bearer $accessToken";
      final mimeType = lookupMimeType(file.path);
      if (mimeType == null || !mimeType.startsWith("image/")) {
        throw Exception("Selected file is not an image");
      }

      final parts = mimeType.split("/");

      // request.files.add(
      //   http.MultipartFile.fromString(
      //     "data",
      //     jsonEncode({}),
      //     // contentType: MediaType("application", "json"),
      //   ),
      // );

      request.files.add(
        await http.MultipartFile.fromPath("file", file.path,contentType: MediaType(parts[0], parts[1]),),
      );

      final streamedResponse = await request.send();
      final response =
      await http.Response.fromStream(streamedResponse);
      print("Status: ${response.statusCode}");
      print("Headers: ${response.headers}");
      print("Body: ${response.body}");
      print(file.path);

      if (response.statusCode != 200 &&
          response.statusCode != 201) {
        throw Exception("Failed to upload background");
      }

      final updatedChat = jsonDecode(response.body);
      final imageUrl = updatedChat["backgroundImageUrl"];



      // Cache locally
      box.write("chat_bg_$chatId", imageUrl);

      // Live update ChatScreen
      final chatController = Get.find<ChatScreenController>();
      chatController.chatType.update((c) {
        c?.backgroundImageUrl = imageUrl;
      });

      Get.back(); // preview
      Get.back(); // picker
      Get.snackbar("Success", "Custom Chat Background Applied");
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to upload background",colorText: AppColors.white,
        backgroundColor: Colors.red
      );
      // print("uploadGalleryBackground error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> pickFromGallery() async {
    final XFile? file =
    await picker.pickImage(source: ImageSource.gallery);

    if (file == null) return;

    Get.to(
          () => ChatBackgroundPreview(
        galleryFile: File(file.path),
      ),
    );
  }



  Future<void> resetToDefaultBackground() async {
    try {
      isLoading.value = true;

      final res = await ApiService.request(
        url: "${APIs.url}/api/chats/$chatId/background",
        method: "DELETE",
      );

      if (res.statusCode != 200 && res.statusCode != 201) {
        throw Exception("Failed to reset background");
      }

      // Remove local cache
      box.remove("chat_bg_$chatId");

      // Live update ChatScreen → null background
      final chatController = Get.find<ChatScreenController>();
      chatController.chatType.update((c) {
        c?.backgroundImageUrl = null;
      });

      Get.back(); // close preview
      Get.back(); // close picker
      Get.snackbar("Success", "Default Chat Background Applied");
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to reset chat background",
        snackPosition: SnackPosition.BOTTOM,
      );
      // print("resetToDefaultBackground error: $e");
    } finally {
      isLoading.value = false;
    }
  }

}

enum BackgroundViewMode {
  home,       // Default + Gallery + Categories
  category    // Category chips + wallpapers
}
