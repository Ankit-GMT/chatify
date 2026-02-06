import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:chatify/Screens/NewLoginUI/confirm_password_screen.dart';
import 'package:chatify/Screens/NewLoginUI/email_verification_screen.dart';
import 'package:chatify/Screens/NewLoginUI/login_email_screen.dart';
import 'package:chatify/Screens/NewLoginUI/mobile_verification_screen.dart';
import 'package:chatify/Screens/NewLoginUI/password_reset_otp_screen.dart';
import 'package:chatify/Screens/login_screen.dart';
import 'package:chatify/Screens/main_screen.dart';
import 'package:chatify/Screens/otp_screen.dart';
import 'package:chatify/constants/apis.dart';
import 'package:chatify/constants/custom_snackbar.dart';
import 'package:chatify/controllers/message_controller.dart';
import 'package:chatify/controllers/profile_controller.dart';
import 'package:chatify/controllers/user_controller.dart';
import 'package:chatify/services/presence_socket_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'bottom_controller.dart';

class AuthController extends GetxController {
  final String baseUrl = APIs.url;

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;


  //for token storing
  final box = GetStorage();
  late final String fcmToken;

  String? get token => box.read("accessToken");
  final bottomController = Get.put(BottomController());
  final socket = Get.find<SocketService>();

  var isLoading = false.obs;
  var isHide = true.obs;
  var isHide2 = true.obs;
  var isOtpSent = false.obs;
  var phoneNumber = "".obs;
  var otp = "".obs;
  var forgotOtp = ''.obs;
  var createOtp = ''.obs;
  var phoneOrEmail = "".obs;
  var mobileNumber = ''.obs;
  var emailId = ''.obs;
  var timer = 60.obs;
  Timer? _countdownTimer;

  // Request OTP
  Future<void> sendOtp(String phone) async {
    try {
      isLoading.value = true;
      phoneNumber.value = phone;

      final res = await http.post(
        Uri.parse("$baseUrl/api/auth/mobile/send-otp"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"phoneNumber": phone}),
      )
          // .timeout(const Duration(seconds: 10))
      ;

      final data = jsonDecode(res.body);
      debugPrint("Send-OTP $data");

      if (data['success']) {
        startTimer();
        CustomSnackbar.normal("OTP Sent", "Check your phone for the code.");
        otp.value = data['otp'];

        Get.to(() => OtpScreen());
      } else {
        if (data['newUser']) {
          CustomSnackbar.normal("Not Registered", "Please create an account first");
        } else {
          CustomSnackbar.error("Error", data['error'] ?? "Something went wrong");
        }
      }
    } catch (e) {
      CustomSnackbar.error("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // Verify OTP
  Future<void> verifyOtp(String otpCode) async {
    debugPrint('token---------$fcmToken');
    try {
      isLoading.value = true;

      final res = await http.post(
        Uri.parse("$baseUrl/api/auth/mobile/verify-otp"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "phoneNumber": phoneNumber.value,
          "otp": otpCode,
          "fcmToken": fcmToken,
        }),
      )
          // .timeout(const Duration(seconds: 10))
      ;
      final data = jsonDecode(res.body);

      debugPrint("---verify $data -- verify");

      if (data['accessToken'] != null) {
        // Save tokens locally
        await box.write("accessToken", data['accessToken']);
        await box.write("refreshToken", data['refreshToken']);
        await box.write("userId", data['userId']);
        final msgController = Get.find<MessageController>();
        msgController.onUserLoggedIn(data['userId']);

        CustomSnackbar.success("Success", "Login successful!");
        Get.offAll(() => MainScreen());
      }
      // else if (data['message'] == "OTP verified. Please register.") {
      //   Get.off(() => UserRegisterScreen());
      // }
      else {
        CustomSnackbar.error("Invalid OTP", data['error'] ?? "Try again");
      }
    } catch (e) {
      CustomSnackbar.error("Error", e.toString());
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
        Uri.parse("$baseUrl/api/auth/mobile/resend-otp"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"phoneNumber": phone}),
      );

      final data = jsonDecode(res.body);
      debugPrint(data);
      if (data['success']) {

        startTimer();
        CustomSnackbar.normal("OTP Sent", "Check your phone for the code.");
        otp.value = data['otp'];
      } else {
        CustomSnackbar.error("Error", data['error'] ?? "Something went wrong");
      }
    } catch (e) {
      CustomSnackbar.error("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // Login with email

  Future<void> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      isLoading.value = true;

      final response = await http.post(
        Uri.parse("$baseUrl/api/auth/email/login"),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "email": email,
          "password": password,
          "fcmToken": fcmToken,
        }),
      )
          // .timeout(const Duration(seconds: 10))
      ;


      final data = jsonDecode(response.body);

      if (data['success']) {
        // success
        await box.write("accessToken", data['accessToken']);
        await box.write("refreshToken", data['refreshToken']);
        await box.write("userId", data['userId']);
        final msgController = Get.find<MessageController>();
        msgController.onUserLoggedIn(data['userId']);

        CustomSnackbar.success("Success", "Login successful");
        Get.offAll(() => MainScreen());
      }
      else {

        CustomSnackbar.error(
          "Login Failed",
          data["message"] ?? "Invalid credentials",
        );
      }
    } catch (e) {
      CustomSnackbar.error(
        "Error",
        "Something went wrong. Please try again.",
      );
      debugPrint("Login Error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // For saving email and password locally

  RxBool rememberMe = false.obs;

  void toggleRemember(bool value) {
    rememberMe.value = value;
    box.write('remember_me', value);
  }

  void saveLogin(String email, String password) {
    if (rememberMe.value) {
      box.write('saved_email', email);
      box.write('saved_password', password);
    }
  }

  void clearSavedLogin() {
    box.remove('saved_email');
    box.remove('saved_password');
    box.write('remember_me', false);
  }

  // Forgot Password

  Future<void> forgotPasswordSendOtp({
    required String value,
    required String resetType,
  }) async {
    try {
      isLoading.value = true;

      phoneOrEmail.value = value;

      final Map<String, String> body ;
      if(resetType == 'mobile'){
        body = {
          "resetType": resetType,
          "phoneNumber": value,
        };
      }
      else{
        body = {
          "resetType": resetType,
          "email": value,
        };
      }

      final response = await http.post(
        Uri.parse("$baseUrl/api/auth/password/forgot"),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (data['success']) {
        forgotOtp.value = data['otp'];
        startTimer();
        CustomSnackbar.success(
          "Success",
          data["message"] ?? "OTP sent to your mobile number",
        );
        Get.to(()=> PasswordResetOtpScreen(resetType: resetType));
      } else {
        CustomSnackbar.error(
          "Failed",
          data["message"] ?? "Unable to send OTP",
        );
      }
    } catch (e) {
      CustomSnackbar.error(
        "Error",
        "Something went wrong. Please try again.",
      );
      debugPrint("Forgot Password (Mobile) Error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // Re-send Otp for forgot password

  Future<void> forgotPasswordResendOtp({
    required String value,
    required String resetType,
  }) async {
    try {
      isLoading.value = true;

      final Map<String, String> body ;
      if(resetType == 'mobile'){
        body = {
          "resetType": resetType,
          "phoneNumber": value,
        };
      }
      else{
        body = {
          "resetType": resetType,
          "email": value,
        };
      }

      final response = await http.post(
        Uri.parse("$baseUrl/api/auth/password/resend-otp"),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (data['success']) {
        forgotOtp.value = data['otp'];
        startTimer();
        CustomSnackbar.success(
          "Success",
          data["message"] ?? "OTP sent to your mobile number",
        );
      } else {
        CustomSnackbar.error(
          "Failed",
          data["message"] ?? "Unable to send OTP",
        );
      }
    } catch (e) {
      CustomSnackbar.error(
        "Error",
        "Something went wrong. Please try again.",
      );
      debugPrint("Forgot Password (Mobile) Error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> verifyOtpPassword({
    required String value,
    required String resetType,
    required String otpCode
  }) async {

    try {
      isLoading.value = true;

      final Map<String, String> body ;

      if(resetType == 'mobile'){
        body = {
          "resetType": resetType,
          "phoneNumber": value,
          "otp": otpCode
        };
      }
      else {
        body = {
          "resetType": resetType,
          "email": value,
          "otp": otpCode
        };
      }

      final res = await http.post(
        Uri.parse("$baseUrl/api/auth/password/verify-otp"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );
      final data = jsonDecode(res.body);

      debugPrint("verify $data -- verify");

      if (data['success']) {

        CustomSnackbar.success("OTP verified successfully", "You can now reset your password");
        Get.off(() => ConfirmPasswordScreen(resetType: resetType,));
      }
      else {
        CustomSnackbar.error(
          "Failed",
          data["message"] ?? "Invalid OTP",
        );
      }
    } catch (e) {
      CustomSnackbar.error("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // Create and confirm password

  Future<void> resetPassword({
    required String resetType,      // "mobile" or "email"
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      isLoading.value = true;

      final Map<String, String> body;

      if (resetType == 'mobile') {
        body = {
          "resetType": resetType,
          "phoneNumber": phoneOrEmail.value,
          "otp": forgotOtp.value,
          "newPassword": newPassword,
          "confirmPassword": confirmPassword,
        };
      } else {
        body = {
          "resetType": resetType,
          "email": phoneOrEmail.value,
          "otp": forgotOtp.value,
          "newPassword": newPassword,
          "confirmPassword": confirmPassword,
        };
      }

      final res = await http.post(
        Uri.parse("$baseUrl/api/auth/password/reset"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      final data = jsonDecode(res.body);

      debugPrint("reset password response: $data");

      if (data['success']) {
        CustomSnackbar.success(
          "Success",
          data["message"] ?? "Password reset successfully",
        );

        // Navigate to login screen
        Get.offAll(() => LoginEmailScreen());
      } else {
        CustomSnackbar.error(
          "Failed",
          data["message"] ?? "Unable to reset password",
        );
      }
    } catch (e) {
      CustomSnackbar.error(
        "Error",
        "Something went wrong. Please try again.",
      );
      debugPrint("Reset Password Error: $e");
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

  var pickedImage = Rx<File?>(null);

  final ImagePicker _picker = ImagePicker();

  Future<void> pickImage(ImageSource source) async {
    final XFile? image =
        await _picker.pickImage(source: source, imageQuality: 20);

    if (image != null) {
      pickedImage.value = File(image.path);
    }
  }

  Future<void> createAccount({
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String dateOfBirth,
    required String password,
    required String confirmPassword,
    // required File profileImageFile,
  }) async {
    try {
      isLoading.value = true;

      mobileNumber.value = phoneNumber;
      emailId.value = email;

      var request = http.MultipartRequest(
        "POST",
        Uri.parse("$baseUrl/api/auth/account/create"),
      );

      // text fields
      request.fields['firstName'] = firstName;
      request.fields['lastName'] = lastName;
      request.fields['phoneNumber'] = phoneNumber;
      request.fields['dateOfBirth'] = dateOfBirth;
      request.fields['email'] = email;
      request.fields['password'] = password;
      request.fields['confirmPassword'] = confirmPassword;

      // image file (multipart)
      // request.files.add(
      //   await http.MultipartFile.fromPath(
      //     'profileImage',
      //     profileImageFile.path,
      //   ),
      // );

      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      final data = jsonDecode(response.body);
      debugPrint("Create Account response:- $data");

      if (data['success']) {
        Get.to(()=> MobileVerificationScreen());
        CustomSnackbar.success("Success", data['message'] ?? 'Account Created Successfully, Please verify mobile number');
      } else {
        CustomSnackbar.error("Error", data['message'] ?? "Something went wrong");
      }
    } catch (e) {
      CustomSnackbar.error("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // after submit details - send mobile otp

  Future<void> sendMobileOtp({
    required String phoneNumber,
  }) async {
    try {
      if (isLoading.value) return;

      isLoading.value = true;

      final res = await http.post(
        Uri.parse("$baseUrl/api/auth/account/send-mobile-otp"),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "phoneNumber": phoneNumber,
        }),
      );

      final data = jsonDecode(res.body);

      print("send mobile otp response: $data");

      if (data['success']) {
        startTimer();
        isOtpSent.value = true;
        CustomSnackbar.success(
          "Success",
          data["message"] ?? "OTP sent successfully",
        );
        createOtp.value = data['otp'];
      } else {
        CustomSnackbar.error(
          "Failed",
          data["message"] ?? "Failed to send OTP",
        );
      }
    } catch (e) {
      CustomSnackbar.error(
        "Error",
        "Something went wrong. Please try again.",
      );
      print("Send Mobile OTP Error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> verifyMobileOtp({
    required String phoneNumber,
    required String otp,
  }) async {
    try {
      if (isLoading.value) return;

      isLoading.value = true;

      final res = await http.post(
        Uri.parse("$baseUrl/api/auth/account/verify-mobile-otp"),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "phoneNumber": phoneNumber,
          "otp": otp,
        }),
      );

      final data = jsonDecode(res.body);

      print("verify mobile otp response: $data");

      if (data['success']) {
        CustomSnackbar.success(
          "Success",
          data["message"] ?? "Mobile number verified successfully",
        );
        isOtpSent.value = false;
        Get.off(()=> EmailVerificationScreen());

      } else {
        CustomSnackbar.error(
          "Failed",
          data["message"] ?? "Invalid OTP",
        );
      }
    } catch (e) {
      CustomSnackbar.error(
        "Error",
        "Something went wrong. Please try again.",
      );
      print("Verify Mobile OTP Error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> reSendMobileOtp({
    required String phoneNumber,
  }) async {
    try {
      if (isLoading.value) return;

      isLoading.value = true;

      final res = await http.post(
        Uri.parse("$baseUrl/api/auth/account/resend-mobile-otp"),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "phoneNumber": phoneNumber,
        }),
      );

      final data = jsonDecode(res.body);

      print("resend mobile otp response: $data");

      if (data['success']) {
        startTimer();
        CustomSnackbar.success(
          "Success",
          data["message"] ?? "OTP sent successfully",
        );
        createOtp.value = data['otp'];
      } else {
        CustomSnackbar.error(
          "Failed",
          data["message"] ?? "Failed to resend OTP",
        );
      }
    } catch (e) {
      CustomSnackbar.error(
        "Error",
        "Something went wrong. Please try again.",
      );
      print("ReSend Mobile OTP Error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // after submit details - send email otp

  Future<void> sendEmailOtp({
    required String email,
  }) async {
    try {
      if (isLoading.value) return;

      isLoading.value = true;

      final res = await http.post(
        Uri.parse("$baseUrl/api/auth/account/send-email-otp"),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "email": email,
        }),
      );

      final data = jsonDecode(res.body);

      print("send email otp response: $data");

      if (data['success']) {
        startTimer();
        isOtpSent.value = true;
        CustomSnackbar.success(
          "Success",
          data["message"] ?? "OTP sent successfully",
        );
        createOtp.value = data['otp'];
      } else {
        CustomSnackbar.error(
          "Failed",
          data["message"] ?? "Failed to send OTP",
        );
      }
    } catch (e) {
      CustomSnackbar.error(
        "Error",
        "Something went wrong. Please try again.",
      );
      print("Send Email OTP Error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> verifyEmailOtp({
    required String email,
    required String otp,
  }) async {
    try {
      if (isLoading.value) return;

      isLoading.value = true;

      final res = await http.post(
        Uri.parse("$baseUrl/api/auth/account/verify-email-otp"),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "email": email,
          "otp": otp,
          "fcmToken": fcmToken
        }),
      );

      final data = jsonDecode(res.body);

      print("verify email otp response: $data");

      if (data['success']) {
        CustomSnackbar.success(
          "Success",
          data["message"] ?? "Email verified successfully",
        );
        await box.write("accessToken", data['accessToken']);
        await box.write("refreshToken", data['refreshToken']);
        await box.write("userId", data['userId']);
        final msgController = Get.find<MessageController>();
        msgController.onUserLoggedIn(data['userId']);
        Get.offAll(()=> MainScreen());
        isOtpSent.value = false;
      } else {
        CustomSnackbar.error(
          "Failed",
          data["message"] ?? "Invalid OTP",
        );
      }
    } catch (e) {
      CustomSnackbar.error(
        "Error",
        "Something went wrong. Please try again.",
      );
      print("Verify Email OTP Error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> reSendEmailOtp({
    required String email,
  }) async {
    try {
      if (isLoading.value) return;

      isLoading.value = true;

      final res = await http.post(
        Uri.parse("$baseUrl/api/auth/account/resend-email-otp"),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "email": email,
        }),
      );

      final data = jsonDecode(res.body);

      print("resend email otp response: $data");

      if (data['success']) {
        startTimer();
        CustomSnackbar.success(
          "Success",
          data["message"] ?? "OTP sent successfully",
        );
        createOtp.value = data['otp'];
      } else {
        CustomSnackbar.error(
          "Failed",
          data["message"] ?? "Failed to resend OTP",
        );
      }
    } catch (e) {
      CustomSnackbar.error(
        "Error",
        "Something went wrong. Please try again.",
      );
      print("Send Email OTP Error: $e");
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
        await box.remove("userId");
        await box.remove("userName");
        socket.disconnect();


        CustomSnackbar.success("Logged out", "You have been logged out successfully.");

        Get.delete<UserController>();
        Get.delete<ProfileController>();
        Get.delete<BottomController>();

        Get.offAll(() => LoginScreen());
      } else {
        CustomSnackbar.error("Error", data['error'] ?? "Logout failed");
      }
    } catch (e) {
      CustomSnackbar.error("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onInit() async {
    // TODO: implement onInit
    super.onInit();
    rememberMe.value = box.read('remember_me') ?? false;
    fcmToken = (await _fcm.getToken())!;
  }
}
