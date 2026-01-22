import 'package:chatify/Screens/NewLoginUI/create_account_screen.dart';
import 'package:chatify/Screens/NewLoginUI/forgot_password_screen.dart';
import 'package:chatify/Screens/login_screen.dart';
import 'package:chatify/constants/app_colors.dart';
import 'package:chatify/controllers/auth_controller.dart';
import 'package:chatify/widgets/custom_textfield.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginEmailScreen extends StatelessWidget {
  const LoginEmailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    final _emailController = TextEditingController();
    final _passwordController = TextEditingController();

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
              SizedBox(height: Get.height * 0.05),
              Container(
                height: Get.height * 0.4,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(90),
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
                  "assets/images/login_email.jpg",
                  fit: BoxFit.fitWidth,
                ),
              ),
              SizedBox(
                height: Get.height * 0.04,
              ),
              Text(
                "Login",
                style: GoogleFonts.poppins(
                    fontSize: 24, fontWeight: FontWeight.w600),
              ),
              Text(
                "Enter your email to access your account",
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w400),
              ),
              SizedBox(
                height: Get.height * 0.03,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: CustomTextfield(
                    controller: _emailController,
                    hintText: "Email",
                    isEmail: true,
                    prefixIcon: Icons.email),
              ),
              SizedBox(
                height: Get.height * 0.01,
              ),
              Obx(() => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: CustomTextfield(
                  controller: _passwordController,
                  hintText: "Password",
                  isPassword: authController.isHide.value,
                  prefixIcon: Icons.lock,
                  suffixIcon: IconButton(
                    onPressed: () {
                      authController.isHide.value =
                          !authController.isHide.value;
                    },
                    icon: Icon(authController.isHide.value
                        ? Icons.visibility_off
                        : Icons.visibility)),
                  ),
                ),
              ),
              SizedBox(
                height: Get.height * 0.01,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: false,
                          onChanged: (value) {},
                          activeColor: AppColors.primary,
                        ),
                        Text(
                          "Remember Me",
                          style: GoogleFonts.poppins(
                              fontSize: 14, fontWeight: FontWeight.w400),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        Get.to(() => ForgotPasswordScreen());
                      },
                      child: Text(
                        "Forgot Password ?",
                        style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: Get.height * 0.01,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GestureDetector(
                  onTap:authController.isLoading.value ? null : () {
                    if (_emailController.text.trim().isEmpty) {
                      Get.snackbar("Error", "Email is required");
                      return;
                    }

                    if (!GetUtils.isEmail(_emailController.text.trim())) {
                      Get.snackbar("Error", "Enter a valid email");
                      return;
                    }

                    if (_passwordController.text.isEmpty) {
                      Get.snackbar("Error", "Password is required");
                      return;
                    }

                    if (_passwordController.text.length < 6) {
                      Get.snackbar(
                          "Error", "Password must be at least 6 characters");
                      return;
                    }
                    authController.loginWithEmail(
                      email: _emailController.text.trim(),
                      password: _passwordController.text.trim(),
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
                        () => authController.isLoading.value
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text(
                                "Login",
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
                height: Get.height * 0.02,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GestureDetector(
                  onTap: () {
                    Get.to(() => LoginScreen());
                  },
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      "Login with Mobile",
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: Get.height * 0.02,
              ),
              SizedBox(
                width: double.infinity,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 5,
                  children: [
                    Text(
                      "Don't have an account?",
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary),
                    ),
                    GestureDetector(
                      onTap: () {
                        Get.to(()=> CreateAccountScreen());
                      },
                      child: Text(
                        "Sign Up",
                        style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
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
