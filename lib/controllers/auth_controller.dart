import 'dart:async';
import 'dart:convert';
import 'package:chatify/Screens/login_screen.dart';
import 'package:chatify/Screens/main_screen.dart';
import 'package:chatify/Screens/otp_screen.dart';
import 'package:chatify/Screens/user_register_screen.dart';
import 'package:chatify/constants/apis.dart';
import 'package:chatify/controllers/profile_controller.dart';
import 'package:chatify/controllers/user_controller.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;

import 'bottom_controller.dart';

class AuthController extends GetxController {
  final String baseUrl = APIs.url;

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  //for token storing
  final box = GetStorage();
  late final String fcmToken;

  String? get token => box.read("accessToken");
  final bottomController = Get.put(BottomController());

  var isLoading = false.obs;
  var isOtpSent = false.obs;
  var phoneNumber = "".obs;
  var otp = "".obs;
  var timer = 60.obs;
  Timer? _countdownTimer;

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
        startTimer();
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

    print('token---------$fcmToken');
    try {
      isLoading.value = true;

      final res = await http.post(
        Uri.parse("$baseUrl/api/auth/verify-otp"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "phoneNumber": phoneNumber.value,
          "otp": otpCode,
          "fcmToken": fcmToken,
        }),
      );
      final data = jsonDecode(res.body);

      print("---verify $data -- verify");

      if (data['accessToken'] != null) {
        // Save tokens locally
        await box.write("accessToken", data['accessToken']);
        await box.write("refreshToken", data['refreshToken']);

        Get.snackbar("Success", "Login successful!");
        Get.offAll(() => MainScreen());
      } else if (data['message'] == "OTP verified. Please register.") {
        Get.off(() => UserRegisterScreen());
      } else {
        Get.snackbar("Invalid OTP", data['error'] ?? "Try again");
      }
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // Request OTP
  Future<void> reSendOtp(String phone) async {
    try {
      isLoading.value = true;
      phoneNumber.value = phone;

      final res = await http.post(
        Uri.parse("$baseUrl/api/auth/resend-otp"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"phoneNumber": phone}),
      );

      final data = jsonDecode(res.body);
      print(data);
      if (data['success']) {
        isOtpSent.value = true;
        startTimer();
        Get.snackbar("OTP Sent", "Check your phone for the code.");
        otp.value = data['otp'];
      } else {
        Get.snackbar("Error", data['error'] ?? "Something went wrong");
      }
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // Timer
  void startTimer() {
    timer.value = 60; // reset to 60 seconds
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (timer.value > 0) {
        timer.value--;
      } else {
        t.cancel();
      }
    });
  }

  @override
  void onClose() {
    _countdownTimer?.cancel();
    super.onClose();
  }

  Future<void> registerUser({
    required String firstName,
    required String lastName,
    String? email, //  optional
    required String phoneNumber,
    required String dateOfBirth,
    required String profileImageUrl,
  }) async {
    try {
      isLoading.value = true;

      final body = {
        "firstName": firstName,
        "lastName": lastName,
        "phoneNumber": phoneNumber,
        "dateOfBirth": dateOfBirth,
        "profileImageUrl": profileImageUrl,
      };

      // only add email if user entered it
      if (email != null && email.isNotEmpty) {
        body["email"] = email;
      }

      final res = await http.post(
        Uri.parse("$baseUrl/api/auth/register"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      final data = jsonDecode(res.body);
      print(data);
      if (data['accessToken'] != null) {
        // Save tokens locally
        await box.write("accessToken", data['accessToken']);
        await box.write("refreshToken", data['refreshToken']);

        Get.snackbar("Success", "Registration successful!");
        Get.offAll(() => MainScreen());
      } else {
        Get.snackbar("Error", data['error'] ?? "Something went wrong");
      }
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // Logout user

  Future<void> logoutUser() async {
    try {
      isLoading.value = true;

      final token = box.read("accessToken");
      final refreshToken = box.read("refreshToken");

      final res = await http.post(
        Uri.parse("$baseUrl/api/auth/logout"),
        headers: {
          "Content-Type": "application/json",
          // "Authorization": "Bearer $token",
        },
        body: jsonEncode(
            {"phoneNumber": phoneNumber.value}), // send refresh token
      );

      final data = jsonDecode(res.body);

      if (data['success'] == true) {
        // Clear tokens
        await box.remove("accessToken");
        await box.remove("refreshToken");
        await box.remove(registeredKey);
        await box.remove(notRegisteredKey);


        Get.snackbar("Logged out", "You have been logged out successfully.");

        Get.delete<UserController>();
        Get.delete<ProfileController>();
        Get.delete<BottomController>();

        Get.offAll(() => LoginScreen());
      } else {
        Get.snackbar("Error", data['error'] ?? "Logout failed");
      }
    } catch (e) {
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onInit() async {
    // TODO: implement onInit
    super.onInit();
    fcmToken = (await _fcm.getToken())!;
    print("FCM:- $fcmToken");
  }
}
