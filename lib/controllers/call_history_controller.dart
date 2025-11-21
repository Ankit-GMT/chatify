import 'dart:convert';
import 'package:chatify/constants/apis.dart';
import 'package:chatify/models/call_history.dart';
import 'package:chatify/services/api_service.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class CallHistoryController extends GetxController {
  RxBool isLoading = false.obs;
  RxBool isMoreLoading = false.obs;

  RxList<CallHistory> voiceCallHistoryList = <CallHistory>[].obs;
  RxList<CallHistory> videoCallHistoryList = <CallHistory>[].obs;

  final box = GetStorage();

  final String baseUrl = APIs.url;

  int page = 0;
  int size = 20;

  // 🔹 Load Initial Call History
  Future<void> loadCallHistory(String type) async {
    final userId = box.read("userId");

    if (userId == null) {
      print("ERROR: userId is NULL. Cannot fetch call history.");
      return;
    }

    try {
      isLoading.value = true;

      final result = await ApiService.request(
        url:
            "$baseUrl/api/call/history/$type?userId=$userId&page=$page&size=$size",
        method: "GET",
      );

      print( "$baseUrl/api/call/history/$type?userId=$userId&page=$page&size=$size");
      final data = jsonDecode(result.body);
      print("history:- $data");

      List<dynamic> calls = data["calls"] ?? [];

      if (type == "voice") {
        voiceCallHistoryList.value =
            calls.map((e) => CallHistory.fromJson(e)).toList();
      } else if (type == "video") {
        videoCallHistoryList.value =
            calls.map((e) => CallHistory.fromJson(e)).toList();
        print('videoCallHistoryList:- $videoCallHistoryList');

      }
    } catch (e) {
      print("Error loading call history: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // 🔹 Load More Call History
  Future<void> loadMore(String type) async {
    final userId = box.read("userId");

    if (userId == null) return;

    if (isMoreLoading.value) return;

    try {
      isMoreLoading.value = true;
      page++;

      final result = await ApiService.request(
        url:
            "$baseUrl/api/call/history/$type?userId=$userId&page=$page&size=$size",
        method: "GET",
      );

      final data = jsonDecode(result.body);
      List<dynamic> calls = data["calls"] ?? [];

      if (calls.isNotEmpty) {
        if (type == "voice") {
          voiceCallHistoryList.addAll(
            calls.map((e) => CallHistory.fromJson(e)).toList(),
          );
        } else if (type == "video") {
          videoCallHistoryList.addAll(
            calls.map((e) => CallHistory.fromJson(e)).toList(),
          );

        }
      }
    } catch (e) {
      print("Error loading more call history: $e");
    } finally {
      isMoreLoading.value = false;
    }
  }

  @override
  Future<void> onInit() async {
    // TODO: implement onInit
    super.onInit();
   await loadCallHistory("voice");
    print("voice done");
   await loadCallHistory("video");
    print("video done");
  }
}
