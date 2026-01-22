import 'package:chatify/constants/app_colors.dart';
import 'package:chatify/controllers/auth_controller.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class OtpScreen extends StatelessWidget {
  const OtpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    String otpCode = "";

    return Scaffold(
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
              Stack(
                children: [
                  Container(
                    height: Get.height * 0.35,
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
                      "assets/images/otp_screen.jpg",
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 15, top: Get.height * 0.05,),
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
                height: Get.height * 0.04,
              ),
              Text(
                "OTP Verification",
                style: GoogleFonts.poppins(
                    fontSize: 20, fontWeight: FontWeight.w500),
              ),
              SizedBox(
                height: Get.height * 0.02,
              ),
              Text(
                "Enter 4 Digit Code",
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w400),
              ),
              Obx(
                () => authController.timer.value > 0
                    ? Text(
                        "Time Remaining : ${authController.timer.value}",
                        style: TextStyle(color: AppColors.primary),
                      )
                    : RichText(
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
                                  authController.reSendOtp(
                                      authController.phoneNumber.value);
                                },
                            ),
                          ],
                        ),
                      ),
              ),
              SizedBox(
                height: Get.height * 0.06,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 45,
                ),
                child:
                PinCodeTextField(
                  appContext: context,
                  length: 4,
                  textStyle: TextStyle(color: Colors.black),
                  onChanged: (value) {
                    otpCode = value;
                  },
                  onCompleted: (value) {
                    debugPrint("OTP Entered: $value");
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
              SizedBox(
                height: Get.height * 0.03,
              ),
              Obx(
                () => authController.isLoading.value
                    ? CircularProgressIndicator(
                        color: AppColors.primary,
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: GestureDetector(
                          onTap: () {
                            authController.verifyOtp(otpCode);
                          },
                          child: Container(
                            height: Get.height * 0.06,
                            width: Get.width * 0.8,
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
                              child: Text(
                                "Verify",
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
                height: Get.height * 0.1,
              ),
              Obx(
                () => Text(
                  "${authController.otp}",
                  style: TextStyle(fontSize: 18, color: AppColors.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
