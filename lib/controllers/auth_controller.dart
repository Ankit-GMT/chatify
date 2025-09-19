import 'dart:convert';
import 'package:chatify/Screens/main_screen.dart';
import 'package:chatify/Screens/otp_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class AuthController extends GetxController {
  var isLoading = false.obs;
  var isOtpSent = false.obs;
  var phoneNumber = "".obs;
  var otp = "".obs;

  // final String baseUrl = "https://51506be3ed77.ngrok-free.app";
  final String baseUrl = "http://192.168.1.7:8080";

  // Request OTP
  Future<void> sendOtp(String phone) async {
    try {
      isLoading.value = true;
      phoneNumber.value = phone;

      final res = await http.post(
        Uri.parse("$baseUrl/api/auth/send-otp"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"phoneNumber": phone}),
      );

      final data = jsonDecode(res.body);

      print(data);
      if (data['success']) {
        isOtpSent.value = true;
        Get.snackbar("OTP Sent", "Check your phone for the code.");
        otp.value = data['otp'];

        Get.to(() => OtpScreen());
      } else {
        Get.snackbar("Error", data['error'] ?? "Something went wrong");
      }
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // Verify OTP
  Future<void> verifyOtp(String otpCode) async {
    try {
      isLoading.value = true;

      final res = await http.post(
        Uri.parse("$baseUrl/api/auth/verify-otp"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"phoneNumber": phoneNumber.value, "otp": otpCode}),
      );
      final data = jsonDecode(res.body);
      if (data['success']) {
        // Get.offAllNamed("/home");
        Get.off(MainScreen());
      } else {
        Get.snackbar("Invalid OTP", data['error'] ?? "Try again");
      }
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}
