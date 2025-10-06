import 'dart:convert';

import 'package:chatify/constants/apis.dart';
import 'package:chatify/models/message.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

class MessageController extends GetxController {
  final String baseUrl = APIs.url;
  final box = GetStorage();

  // for load messages
  Future<List<Message>> fetchMessages(int chatId) async {
    try {
      final token = box.read("accessToken");

      final res = await http.get(
        Uri.parse("$baseUrl/api/chats/$chatId/messages"),
        headers: {
          "Authorization": "Bearer $token",
        },
      );

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        return data.map((e) => Message.fromJson(e)).toList();
      } else {
        print("Failed to load: ${res.statusCode} ${res.body}");
        return [];
      }
    } catch (e) {
      print("Error: $e");
      return [];
    }
  }

  // for send message
  Future<bool> sendMessage({
    required int chatId,
    required String content,
    String type = "TEXT",
  }) async {
    try {
      final token = box.read("accessToken");

      final res = await http.post(
        Uri.parse("$baseUrl/api/chats/$chatId/messages"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "content": content,
          "type": type,
        }),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        print("Message sent: ${res.body}");
        return true;
      } else {
        print("Failed to send: ${res.statusCode} ${res.body}");
        return false;
      }
    } catch (e) {
      print("Error: $e");
      return false;
    }
  }

  Future<bool> deleteMessage(int chatId, int messageId) async {
    try {
      final token = box.read("accessToken");

      final res = await http.delete(
        Uri.parse("$baseUrl/api/chats/$chatId/messages/$messageId"),
        headers: {
          "Authorization": "Bearer $token",
        },
      );

      if (res.statusCode == 200 || res.statusCode == 204) {
        print("Message deleted");
        return true;
      } else {
        print("Failed to delete: ${res.statusCode} ${res.body}");
        return false;
      }
    } catch (e) {
      print("Error: $e");
      return false;
    }
  }

  // Update

  Future<bool> updateMessage({
    required int chatId,
    required int messageId,
    required String newContent,
  }) async {
    try {
      final token = box.read("accessToken");

      final res = await http.patch(
        Uri.parse("$baseUrl/api/chats/$chatId/messages/$messageId"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "content": newContent,
        }),
      );

      if (res.statusCode == 200) {
        print("Message updated: ${res.body}");
        return true;
      } else {
        print("Failed to update: ${res.statusCode} ${res.body}");
        return false;
      }
    } catch (e) {
      print("Error: $e");
      return false;
    }
  }
}
