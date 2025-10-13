import 'dart:convert';
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
        response = await http.delete(Uri.parse(url), headers: mergedHeaders);
      } else {
        throw Exception("Unsupported method: $method");
      }

      // If token expired, try to refresh it
      if (response.statusCode == 401) {
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

  static void _logoutUser() {
    box.erase();
    Get.off(()=> LoginScreen());
  }
}
