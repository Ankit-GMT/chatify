import 'dart:convert';

import 'package:chatify/Screens/main_screen.dart';
import 'package:chatify/constants/apis.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

class BroadCastController extends GetxController{

  final String baseUrl = APIs.url;
  final isLoading = false.obs;
  final box = GetStorage();

  final isScheduled = false.obs;
  final scheduledAt = Rxn<DateTime>();


  final messageController = TextEditingController();

  /// Selected users
  final selectedUserIds = <int>[].obs;

  void toggleUser(int userId) {
    if (selectedUserIds.contains(userId)) {
      selectedUserIds.remove(userId);
    } else {
      selectedUserIds.add(userId);
    }
  }

  void clearBroadcast() {
    selectedUserIds.clear();
    messageController.clear();
    isScheduled.value = false;
    scheduledAt.value = null;
    recordedFilePath.value = "";
    recordedDuration.value = 0;
  }


  Future<void> sendBroadcastMessage({
    required String content,
    required List<int> recipientIds,
  }) async {
    try {
      isLoading.value = true;

      final token = box.read("accessToken");

      final res = await http.post(
        Uri.parse("$baseUrl/api/broadcasts/text"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "content": content,
          "recipientIds": recipientIds,
        }),
      );

      final data = jsonDecode(res.body);
      debugPrint("Broadcast Response: $data");

      if (res.statusCode == 200) {
        Get.snackbar(
          "Broadcast Sent",
          "Message sent to ${recipientIds.length} recipients",
        );

        // Optional: clear input / navigate back
        messageController.clear();
        Navigator.pop(Get.context!);
      } else {
        Get.snackbar(
          "Error",
          data['message'] ?? "Failed to send broadcast",
        );
      }
    } catch (e) {
      debugPrint("Broadcast Error: $e");
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // Voice Broadcast

  final recordedFilePath = "".obs;
  final recordedDuration = 0.obs;

  void setVoiceRecording(String path, int duration) {
    recordedFilePath.value = path;
    recordedDuration.value = duration;
  }


  Future<void> sendVoiceBroadcast({
    required String filePath,
    required List<int> recipientIds,
    required int duration,
  }) async {
    try {
      isLoading.value = true;

      final token = box.read("accessToken");

      final uri = Uri.parse("$baseUrl/api/broadcasts/voice");
      final request = http.MultipartRequest("POST", uri);

      request.headers.addAll({
        "Authorization": "Bearer $token",
      });

      /// Attach voice file
      request.files.add(
        await http.MultipartFile.fromPath(
          "file",
          filePath,
        ),
      );

      /// Add recipients (same key multiple times)
      for (final id in recipientIds) {
        request.fields.addAll({
          "recipientIds": id.toString(),
        });
      }

      /// Duration in seconds
      request.fields["duration"] = duration.toString();

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      final data = jsonDecode(response.body);
      debugPrint("Voice Broadcast Response: $data");

      if (response.statusCode == 200) {
        Get.snackbar(
          "Voice Broadcast Sent",
          "Sent to ${recipientIds.length} recipients",
        );

        clearBroadcast();
        Navigator.pop(Get.context!);
      } else {
        Get.snackbar(
          "Error",
          data['message'] ?? "Failed to send voice broadcast",
        );
      }
    } catch (e) {
      debugPrint("Voice Broadcast Error: $e");
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // Scheduled broadcast text

  Future<void> sendScheduledBroadcast({
    required String content,
    required List<int> recipientIds,
    required DateTime scheduledAt,
  }) async {
    try {
      isLoading.value = true;

      final token = box.read("accessToken");

      final res = await http.post(
        Uri.parse("$baseUrl/api/broadcasts/schedule/text"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "content": content,
          "recipientIds": recipientIds,
          "scheduledAt": scheduledAt.toIso8601String(),
        }),
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 200) {
        Get.snackbar("Scheduled", "Broadcast scheduled successfully");
        clearBroadcast();
        Navigator.pop(Get.context!);
      } else {
        Get.snackbar("Error", data['message'] ?? "Failed to schedule broadcast");
      }
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // Scheduled Broadcast Voice

  Future<void> sendScheduledVoiceBroadcast({
    required String filePath,
    required List<int> recipientIds,
    required int duration,
    required DateTime scheduledAt,
  }) async {
    try {
      isLoading.value = true;

      final token = box.read("accessToken");

      final uri = Uri.parse("$baseUrl/api/broadcasts/schedule/voice");
      final request = http.MultipartRequest("POST", uri);

      request.headers.addAll({
        "Authorization": "Bearer $token",
      });

      /// Attach voice file
      request.files.add(
        await http.MultipartFile.fromPath(
          "file",
          filePath,
        ),
      );

      /// Add recipients (same key multiple times)
      for (final id in recipientIds) {
        request.fields.addAll({
          "recipientIds": id.toString(),
        });
      }

      /// Duration in seconds
      request.fields["duration"] = duration.toString();
      request.fields["scheduledAt"] = scheduledAt.toIso8601String();


      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      final data = jsonDecode(response.body);
      debugPrint("Scheduled Voice Broadcast Response: $data");

      if (response.statusCode == 200) {
        Get.snackbar(
          "Scheduled", "Broadcast scheduled successfully",
        );

        clearBroadcast();
        Navigator.pop(Get.context!);
      } else {
        Get.snackbar(
          "Error",
          data['message'] ?? "Failed to schedule broadcast",
        );
      }
    } catch (e) {
      debugPrint("Scheduled Voice Broadcast Error: $e");
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // Media Broadcast

  Future<void> sendMediaBroadcast({
    required String filePath,
    required String type, // IMAGE or VIDEO
    String? caption,
    required List<int> recipientIds,
  }) async {
    try {
      isLoading.value = true;

      final token = box.read("accessToken");

      final uri = Uri.parse("$baseUrl/api/broadcasts/media");
      final request = http.MultipartRequest("POST", uri);

      request.headers.addAll({
        "Authorization": "Bearer $token",
      });

      /// Attach media file
      request.files.add(
        await http.MultipartFile.fromPath(
          "file",
          filePath,
        ),
      );

      /// Media type
      request.fields["type"] = type;

      /// Caption (optional)
      if (caption != null && caption.trim().isNotEmpty) {
        request.fields["caption"] = caption.trim();
      }

      /// Add recipients (same key multiple times)
      for (final id in recipientIds) {
        request.fields["recipientIds"] = id.toString();
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      final data = jsonDecode(response.body);
      debugPrint("Media Broadcast Response: $data");

      if (response.statusCode == 200) {
        Get.snackbar(
          "Broadcast Sent",
          "${type.toLowerCase()} sent to ${recipientIds.length} users",
        );

        clearBroadcast();
        Get.offAll(()=> MainScreen());
      } else {
        Get.snackbar(
          "Error",
          data['message'] ?? "Failed to send media broadcast",
        );
      }
    } catch (e) {
      debugPrint("Media Broadcast Error: $e");
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // Scheduled Media Broadcast

  Future<void> sendScheduledMediaBroadcast({
    required String filePath,
    required String type, // IMAGE or VIDEO
    String? caption,
    required List<int> recipientIds,
    required DateTime scheduledAt,
  }) async {
    try {
      isLoading.value = true;

      final token = box.read("accessToken");

      final uri = Uri.parse("$baseUrl/api/broadcasts/schedule/media");
      final request = http.MultipartRequest("POST", uri);

      request.headers.addAll({
        "Authorization": "Bearer $token",
      });

      /// Attach media file
      request.files.add(
        await http.MultipartFile.fromPath(
          "file",
          filePath,
        ),
      );

      /// Media type
      request.fields["type"] = type;
      request.fields["scheduledAt"] = scheduledAt.toIso8601String();


      /// Caption (optional)
      if (caption != null && caption.trim().isNotEmpty) {
        request.fields["caption"] = caption.trim();
      }

      /// Add recipients (same key multiple times)
      for (final id in recipientIds) {
        request.fields["recipientIds"] = id.toString();
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      final data = jsonDecode(response.body);
      debugPrint("Media Broadcast Response: $data");

      if (response.statusCode == 200) {
        Get.snackbar(
          "Scheduled", "Broadcast scheduled successfully",
        );

        clearBroadcast();
        Get.offAll(()=> MainScreen());
      } else {
        Get.snackbar(
          "Error",
          data['message'] ?? "Failed to scheduled media broadcast",
        );
      }
    } catch (e) {
      debugPrint("Scheduled Media Broadcast Error: $e");
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // List of all Scheduled broadcasts

  final scheduledBroadcasts = [].obs;
  final isFetchingScheduled = false.obs;

  Future<void> fetchScheduledBroadcasts() async {
    try {
      isFetchingScheduled.value = true;

      final token = box.read("accessToken");

      final res = await http.get(
        Uri.parse("$baseUrl/api/broadcasts/scheduled"),
        headers: {
          "Authorization": "Bearer $token",
        },
      );

      debugPrint("Scheduled Broadcasts RAW: ${res.body}");

      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);

        /// API returns DIRECT LIST
        scheduledBroadcasts.value = data;
      } else {
        Get.snackbar("Error", "Failed to load scheduled broadcasts");
      }
    } catch (e) {
      debugPrint("Fetch Scheduled Error: $e");
      Get.snackbar("Error", e.toString());
    } finally {
      isFetchingScheduled.value = false;
    }
  }

  Future<bool> deleteScheduledBroadcast(int broadcastId) async {
    try {
      final token = box.read("accessToken");

      final res = await http.delete(
        Uri.parse("$baseUrl/api/broadcasts/$broadcastId"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (res.statusCode == 200 || res.statusCode == 204) {
        // Remove locally for instant UI update
        scheduledBroadcasts.removeWhere(
              (b) => b['id'] == broadcastId,
        );
        return true;
      }

      debugPrint(
        "Failed to delete scheduled broadcast: ${res.statusCode} ${res.body}",
      );
      return false;
    } catch (e, stack) {
      debugPrint("deleteScheduledBroadcast exception: $e");
      debugPrintStack(stackTrace: stack);
      return false;
    }
  }



}