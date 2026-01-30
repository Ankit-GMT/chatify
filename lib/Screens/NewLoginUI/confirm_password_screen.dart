import 'package:chatify/constants/app_colors.dart';
import 'package:chatify/constants/custom_snackbar.dart';
import 'package:chatify/controllers/auth_controller.dart';
import 'package:chatify/widgets/custom_textfield.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class ConfirmPasswordScreen extends StatelessWidget {
  final String resetType;

  const ConfirmPasswordScreen({super.key, required this.resetType});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AuthController>();
    final _passwordController = TextEditingController();
    final _confirmPasswordController = TextEditingController();

    return Scaffold(
      // backgroundColor: Colors.white,
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
              image: AssetImage(Get.isDarkMode
                  ? "assets/images/dark_background.jpg"
                  : "assets/images/background.jpg"),
              fit: BoxFit.cover),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // SizedBox(height: Get.height * 0.05),
              Container(
                height: Get.height * 0.5,
                width: double.infinity,
                padding: EdgeInsets.only(top: Get.height * 0.05),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(125),
                  ),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 8,
                      offset: Offset(0, 2),
                      color: AppColors.grey.withAlpha(100),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  "assets/images/confirm_password.jpg",
                  fit: BoxFit.fitWidth,
                ),
              ),
              SizedBox(
                height: Get.height * 0.03,
              ),
              Text(
                "Create New Password",
                style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary),
              ),
              SizedBox(
                height: Get.height * 0.01,
              ),
              Text(
                "Create a strong password for your account",
                style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: AppColors.primary),
              ),
              SizedBox(
                height: Get.height * 0.04,
              ),
              Obx(
                () => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    spacing: Get.height * 0.013,
                    children: [
                      CustomTextfield(
                        controller: _passwordController,
                        hintText: "New Password",
                        isPassword: controller.isHide2.value,
                        suffixIcon: IconButton(
                          onPressed: () {
                            controller.isHide2.value =
                                !controller.isHide2.value;
                          },
                          icon: Icon(controller.isHide2.value
                              ? Icons.visibility_off
                              : Icons.visibility),
                        ),
                      ),
                      CustomTextfield(
                        controller: _confirmPasswordController,
                        hintText: "Confirm Password",
                        isPassword: controller.isHide.value,
                        suffixIcon: IconButton(
                          onPressed: () {
                            controller.isHide.value = !controller.isHide.value;
                          },
                          icon: Icon(controller.isHide.value
                              ? Icons.visibility_off
                              : Icons.visibility),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: Get.height * 0.03,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GestureDetector(
                  onTap: controller.isLoading.value
                      ? null
                      : () {
                          if (_passwordController.text.trim().length < 8) {
                            CustomSnackbar.error("Error",
                                "Password must be at least 8 characters");
                            return;
                          }
                          if (_passwordController.text.isEmpty ||
                              _confirmPasswordController.text.isEmpty) {
                            CustomSnackbar.error("Error", "Please fill in all fields");
                            return;
                          }
                          if (_passwordController.text.trim() !=
                              _confirmPasswordController.text.trim()) {
                            CustomSnackbar.error("Error", "Passwords do not match");
                            return;
                          }
                          controller.resetPassword(
                            resetType: resetType,
                            newPassword: _passwordController.text.trim(),
                            confirmPassword:
                                _confirmPasswordController.text.trim(),
                          );
                        },
                  child: Container(
                    height: Get.height * 0.06,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.primary.withAlpha(150),
                            AppColors.primary
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.black.withAlpha(70),
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ]),
                    child: Center(
                      child: Obx(
                        () => controller.isLoading.value
                            ? CircularProgressIndicator(
                                color: AppColors.white,
                              )
                            : Text(
                                "Reset Password",
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white),
                              ),
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(
                height: Get.height * 0.04,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
