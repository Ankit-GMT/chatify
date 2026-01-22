import 'package:chatify/constants/app_colors.dart';
import 'package:chatify/controllers/auth_controller.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class PasswordResetOtpScreen extends StatelessWidget {
  final String resetType;
  const PasswordResetOtpScreen({super.key, required this.resetType});

  @override
  Widget build(BuildContext context) {

    final controller = Get.find<AuthController>();

    String otpCode = "";

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
                  "assets/images/password_reset_otp.png",
                  fit: BoxFit.fitWidth,
                ),
              ),
              SizedBox(
                height: Get.height * 0.03,
              ),
              Text(
                "Password Reset OTP",
                style: GoogleFonts.poppins(
                    fontSize: 20, fontWeight: FontWeight.w600,color: AppColors.primary),
              ),
              SizedBox(
                height: Get.height * 0.01,
              ),
              Text(
                "Enter the 4 -digit OTP sent to your $resetType",
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w400,color: AppColors.primary),
              ),

              SizedBox(
                height: Get.height * 0.06,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 45,
                ),
                child: PinCodeTextField(
                  appContext: context,
                  length: 4,
                  textStyle: TextStyle(color: Colors.black),
                  onChanged: (value) {
                    otpCode = value;
                  },
                  onCompleted: (value) {
                    // print("OTP Entered: $value");
                  },
                  keyboardType: TextInputType.number,
                  cursorColor: AppColors.black,
                  cursorWidth: 0.5,
                  showCursor: true,
                  cursorHeight: 15,
                  autoFocus: true,
                  pinTheme: PinTheme(
                    fieldOuterPadding: EdgeInsets.symmetric(horizontal: 5),
                    shape: PinCodeFieldShape.box,
                    borderRadius: BorderRadius.circular(12),
                    fieldHeight: 50,
                    fieldWidth: 45,
                    activeFillColor: Colors.white,
                    inactiveFillColor: Colors.white,
                    selectedFillColor: Colors.white,
                    activeColor: Colors.grey.shade400,
                    inactiveColor: Colors.grey.shade300,
                    selectedColor: AppColors.primary,
                    activeBoxShadow: [
                      BoxShadow(
                        color: Color(0xff63636333).withAlpha(51),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  enableActiveFill: true,
                ),
              ),
              controller.timer.value > 0
                    ? Text(
                  "Time Remaining : ${controller.timer.value}",
                  style: TextStyle(color: AppColors.primary),
                )
                    :
              RichText(
                text: TextSpan(
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                  ),
                  children: [
                    TextSpan(
                      text: "Didn't receive code ?  ",
                      style: GoogleFonts.poppins(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    TextSpan(
                      text: "Resend Code",
                      style: GoogleFonts.poppins(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          controller.forgotPasswordResendOtp(value: controller.phoneOrEmail.value, resetType: resetType);
                        },
                    ),
                  ],
                ),
              ),
              SizedBox(height: Get.height*0.04,),

              Obx(() => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GestureDetector(
                  onTap:controller.isLoading.value ? null: () {
                    controller.verifyOtpPassword(value: controller.phoneOrEmail.value, resetType: resetType, otpCode: otpCode);
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
                      child:controller.isLoading.value ? CircularProgressIndicator(color: AppColors.white,) : Text(
                        "Verify OTP",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),),
              SizedBox(height: Get.height *0.01,),
              Obx(
                    () => Text(
                  controller.forgotOtp.value,
                  style: TextStyle(fontSize: 18, color: AppColors.primary),
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