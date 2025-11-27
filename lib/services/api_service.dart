import 'dart:convert';
import 'dart:io';
import 'package:chatify/Screens/login_screen.dart';
import 'package:chatify/constants/apis.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';

class ApiService {

  static const baseUrl = APIs.url;
  static final box = GetStorage();

  static Future<http.Response> request({
    required String url,
    required String method,
    Map<String, String>? headers,
    dynamic body,
  }) async {
    final accessToken = box.read("accessToken");

    // base headers
    final defaultHeaders = {
      "Authorization": "Bearer $accessToken",
      "Content-Type": "application/json",
    };

    final mergedHeaders = {...defaultHeaders, ...?headers};

    http.Response response;

    try {
      // Choose method
      if (method == "GET") {
        response = await http.get(Uri.parse(url), headers: mergedHeaders);
      } else if (method == "POST") {
        response = await http.post(Uri.parse(url),
            headers: mergedHeaders, body: jsonEncode(body));
      } else if (method == "PATCH") {
        response = await http.patch(Uri.parse(url),
            headers: mergedHeaders, body: jsonEncode(body));
      } else if (method == "DELETE") {
        response = await http.delete(Uri.parse(url), headers: mergedHeaders, body: jsonEncode(body));
      } else {
        throw Exception("Unsupported method: $method");
      }

      // If token expired, try to refresh it
      if (response.statusCode == 401 || response.statusCode == 403) {
        bool refreshed = await _refreshToken();
        if (refreshed) {
          print("Retrying API after refresh...");
          return await request(
              url: url, method: method, headers: headers, body: body);
        } else {
          print("Refresh token failed. Logging out.");
          _logoutUser();
        }
      }
      print('status Code :- ${response.statusCode}');

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Refresh token API
  static Future<bool> _refreshToken() async {
    final refreshToken = box.read("refreshToken");

    if (refreshToken == null) return false;

    try {
      final res = await http.post(
        Uri.parse("$baseUrl/api/auth/refresh"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"refreshToken": refreshToken}),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        box.write("accessToken", data["accessToken"]);
        print("Token refreshed successfully");
        return true;
      } else {
        print("Failed to refresh token: ${res.body}");
        return false;
      }
    } catch (e) {
      print("Error in refresh token: $e");
      return false;
    }
  }

  static Future<http.Response> sendMediaMessage({
    required String chatId,
    required File file,
    required String type, // IMAGE / VIDEO / AUDIO / DOCUMENT
    String? caption,
    int? duration,       // for audio/video
  }) async {
    final accessToken = box.read("accessToken");

    var uri = Uri.parse("$baseUrl/api/chats/$chatId/messages/media");

    var request = http.MultipartRequest("POST", uri);

    // AUTH HEADER
    request.headers["Authorization"] = "Bearer $accessToken";

    // ADD TEXT FIELDS
    request.fields["type"] = type;
    if (caption != null) request.fields["caption"] = caption;
    if (duration != null) request.fields["duration"] = duration.toString();

    // ADD FILE
    request.files.add(
      await http.MultipartFile.fromPath("file", file.path),
    );

    // SEND REQUEST
    final streamed = await request.send();
    return await http.Response.fromStream(streamed);
  }


  static void _logoutUser() {
    box.erase();
    Get.off(()=> LoginScreen());
  }
}
