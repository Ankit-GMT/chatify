import 'dart:convert';
import 'dart:io';

import 'package:chatify/constants/apis.dart';
import 'package:chatify/models/status_user.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

class StatusController extends GetxController {
  final String baseUrl = APIs.url;
  final box = GetStorage();

  String? get token => box.read("accessToken");

  var myStatuses = <StatusUser>[].obs;
  RxList<ScheduledStatus> scheduledStatuses = <ScheduledStatus>[].obs;

  var recentStatuses = <StatusUser>[].obs;
  var viewedStatuses = <StatusUser>[].obs;

  Future<void> loadStatuses() async {
    final res = await http.get(
      Uri.parse("$baseUrl/api/statuses"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (res.statusCode != 200) return;

    final data = jsonDecode(res.body);

    print("Status data: $data");

    myStatuses.clear();
    recentStatuses.clear();
    viewedStatuses.clear();


    // MY STATUSES

    for (final u in data['myStatuses']) {
      myStatuses.add(_mapStatusUser(u, isMine: true));
    }

    // CONTACT STATUSES

    for (final u in data['contactStatuses']) {
      final user = _mapStatusUser(u);

      if ((u['unviewedCount'] ?? 0) > 0) {
        recentStatuses.add(user);
      } else {
        viewedStatuses.add(user);
      }
    }
    // print("Recent Status :- $recentStatuses");
  }

  // MAPPER

  StatusUser _mapStatusUser(Map<String, dynamic> u, {bool isMine = false}) {
    return StatusUser(
      userId: u['userId'].toString(),
      firstName: u['firstName'],
      lastName: u['lastName'],
      profilePic: u['profileImageUrl'],
      isOnline: u['isOnline'] ?? false, // backend not sending yet
      statuses: (u['statuses'] as List).map<Status>((s) {
        return Status(
          id: s['id'],
          type: s['type'], // IMAGE / VIDEO / TEXT
          mediaUrl: s['mediaUrl'],
          caption: s['content'] ?? "",
          createdAt: DateTime.parse(s['createdAt']),
          viewed: s['isViewed'] ?? false,
          isMine: s['isMine'] ?? false,
          backgroundColor: s['backgroundColor'],
          font: s['font'],
          viewCount: s['viewCount'],
          replyCount: s['replyCount'],
        );
      }).toList(),
    );
  }

  Future<bool> uploadMediaStatus({
    required File file,
    required String type, // IMAGE or VIDEO
    String? caption,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/statuses/media'),
    );

    request.headers['Authorization'] = "Bearer $token";
    request.fields['type'] = type;

    if (caption != null && caption.isNotEmpty) {
      request.fields['caption'] = caption;
    }

    request.files.add(
      await http.MultipartFile.fromPath('file', file.path),
    );

    final response = await request.send();
    return response.statusCode == 200 || response.statusCode == 201;
  }

  Future<bool> deleteStatus(int statusId) async {
    try {
      final res = await http.delete(
        Uri.parse(
          "$baseUrl/api/statuses/$statusId",
        ),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (res.statusCode == 200 || res.statusCode == 204) {
        //  Remove locally for instant UI update
        removeStatusLocally(statusId);
        return true;
      }

      debugPrint(
        "Failed to delete status: ${res.statusCode} ${res.body}",
      );
      return false;
    } catch (e, stack) {
      debugPrint("delete Status exception: $e");
      debugPrintStack(stackTrace: stack);
      return false;
    }
  }

  void removeStatusLocally(int statusId) {
    for (int i = 0; i < myStatuses.length; i++) {
      final user = myStatuses[i];

      final beforeLength = user.statuses.length;

      user.statuses.removeWhere((s) => s.id == statusId);

      // If something was actually removed
      if (user.statuses.length != beforeLength) {

        // Remove user if no statuses left
        if (user.statuses.isEmpty) {
          myStatuses.removeAt(i);
        }

        break; // stop after successful deletion
      }
    }

    update(); // GetX / notifyListeners
  }

  Future<bool> replyToStatus({
    required int statusId,
    required String content,
  }) async {
    try {
      final res = await http.post(
        Uri.parse("${APIs.url}/api/statuses/reply"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "statusId": statusId,
          "content": content,
        }),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        print("Reply Succeed:- ${res.body}");
        return true;
      }

      debugPrint("Reply failed: ${res.statusCode} ${res.body}");
      return false;
    } catch (e, stack) {
      debugPrint("replyToStatus exception: $e");
      debugPrintStack(stackTrace: stack);
      return false;
    }
  }





  // For Scheduled Status

  Future<void> loadScheduledStatuses() async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/api/statuses/scheduled"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (res.statusCode != 200) {
        debugPrint("Failed to load scheduled statuses: ${res.statusCode}");
        return;
      }

      final List<dynamic> data = jsonDecode(res.body);

      print("Scheduled status data: $data");

      scheduledStatuses.clear();

      for (final item in data) {
        final status = ScheduledStatus.fromJson(item);

        // only future scheduled ones
        if (status.state == "PENDING") {
          scheduledStatuses.add(status);
        }
      }
    } catch (e, stack) {
      debugPrint("loadScheduledStatuses exception: $e");
      debugPrintStack(stackTrace: stack);
    }
  }



  Future<bool> uploadScheduledMediaStatus({
    required File file,
    required String type, // IMAGE or VIDEO
    required DateTime scheduledAt,
    String? caption,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/statuses/schedule/media'),
    );

    request.headers['Authorization'] = "Bearer $token";

    request.fields['type'] = type;

    if (caption != null && caption.isNotEmpty) {
      request.fields['caption'] = caption;
    }

    //  Scheduled time (ISO 8601)
    request.fields['scheduledAt'] = scheduledAt.toIso8601String();

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        file.path,
      ),
    );

    final response = await request.send();
    return response.statusCode == 200 || response.statusCode == 201;
  }

  Future<bool> deleteScheduledStatus(int scheduledStatusId) async {
    try {
      final res = await http.delete(
        Uri.parse(
          "$baseUrl/api/statuses/scheduled/$scheduledStatusId",
        ),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (res.statusCode == 200 || res.statusCode == 204) {
        //  Remove locally for instant UI update
        scheduledStatuses.removeWhere(
              (s) => s.id == scheduledStatusId,
        );
        return true;
      }

      debugPrint(
        "Failed to delete scheduled status: ${res.statusCode} ${res.body}",
      );
      return false;
    } catch (e, stack) {
      debugPrint("deleteScheduledStatus exception: $e");
      debugPrintStack(stackTrace: stack);
      return false;
    }
  }



  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
    loadStatuses();
    loadScheduledStatuses();
  }
}
