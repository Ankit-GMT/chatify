import 'package:chatify/constants/app_colors.dart';
import 'package:chatify/constants/custom_snackbar.dart';
import 'package:chatify/controllers/auth_controller.dart';
import 'package:chatify/widgets/custom_textfield.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  ForgotType selectedType = ForgotType.email;

  final authController = Get.find<AuthController>();

  final _controller = TextEditingController();

  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
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
              Stack(
                children: [
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
                      "assets/images/forgot_password.jpg",
                      fit: BoxFit.fitWidth,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 15, top: Get.height * 0.055,),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        IconButton(
                          color: AppColors.iconGrey,
                          style: ButtonStyle(
                            backgroundColor:
                            WidgetStatePropertyAll(AppColors.white),
                            shape: WidgetStatePropertyAll(
                              RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side:
                                  BorderSide(color: Colors.grey.shade200)),
                            ),
                          ),
                          onPressed: () {
                            Get.back();
                          },
                          icon: Icon(Icons.arrow_left),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: Get.height * 0.03,
              ),
              Text(
                "Forgot Password",
                style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary),
              ),
              SizedBox(
                height: Get.height * 0.01,
              ),
              Text(
                "Enter your registered email or mobile number",
                style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: AppColors.primary),
              ),
              SizedBox(
                height: Get.height * 0.04,
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: Get.width * 0.2),
                child: Row(
                  children: [
                    _toggleButton(
                      title: 'Email',
                      isSelected: selectedType == ForgotType.email,
                      onTap: () {
                        setState(() {
                          selectedType = ForgotType.email;
                          _controller.clear();
                        });

                        _focusNode.unfocus();
                        Future.delayed(const Duration(milliseconds: 100), () {
                          _focusNode.requestFocus();
                        });
                      },
                    ),
                    SizedBox(width: Get.width * 0.04),
                    _toggleButton(
                      title: 'Mobile',
                      isSelected: selectedType == ForgotType.mobile,
                      onTap: () {
                        setState(() {
                          selectedType = ForgotType.mobile;
                          _controller.clear();
                        });

                        _focusNode.unfocus();
                        Future.delayed(const Duration(milliseconds: 100), () {
                          _focusNode.requestFocus();
                        });
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: Get.height * 0.02,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  spacing: Get.height * 0.013,
                  children: [
                    CustomTextfield(
                      controller: _controller,
                      focusNode: _focusNode,
                      inputFormatters: [
                        if (selectedType == ForgotType.mobile)
                          FilteringTextInputFormatter.digitsOnly,
                      ],
                      isEmail: selectedType == ForgotType.email,
                      isPhone: selectedType == ForgotType.mobile,
                      hintText: selectedType == ForgotType.email
                          ? 'Enter your email'
                          : 'Enter your mobile number',
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: Get.height * 0.02,
              ),
              Obx(
                () => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GestureDetector(
                    onTap: authController.isLoading.value
                        ? null
                        : () {
                            if (_controller.text.trim().isEmpty &&
                                selectedType == ForgotType.email) {
                              CustomSnackbar.error("Error", "Email is required");
                              return;
                            }

                            if (!GetUtils.isEmail(_controller.text.trim()) &&
                                selectedType == ForgotType.email) {
                              CustomSnackbar.error("Error", "Enter a valid email");
                              return;
                            }
                            if (_controller.text.trim().isEmpty &&
                                selectedType == ForgotType.mobile) {
                              CustomSnackbar.error(
                                  "Error", "Mobile number is required");
                              return;
                            }
                            if (_controller.text.trim().length != 10 &&
                                !GetUtils.isPhoneNumber(
                                    _controller.text.trim()) &&
                                selectedType == ForgotType.mobile) {
                              CustomSnackbar.error(
                                  "Error", "Enter a valid mobile number");
                              return;
                            }

                            authController.forgotPasswordSendOtp(
                                value: _controller.text.trim(),
                                resetType: selectedType == ForgotType.email
                                    ? 'email'
                                    : 'mobile');
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
                        child: authController.isLoading.value
                            ? CircularProgressIndicator(
                                color: AppColors.white,
                              )
                            : Text(
                                "Send OTP",
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

  Widget _toggleButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.primary),
          ),
          child: Text(
            title,
            style: TextStyle(
                color: isSelected ? AppColors.white : AppColors.black,
                fontWeight: FontWeight.w500,
                fontSize: 16),
          ),
        ),
      ),
    );
  }
}

enum ForgotType { email, mobile }
