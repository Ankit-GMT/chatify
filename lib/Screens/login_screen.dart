import 'package:chatify/constants/app_colors.dart';
import 'package:chatify/controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    TextEditingController _mobileController = TextEditingController();

    String selectedCode = "+91";

    String? mobileNumber;
    return Scaffold(
      // backgroundColor: Colors.white,
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(Get.isDarkMode?"assets/images/dark_background.jpg":"assets/images/background.jpg"),
            fit: BoxFit.cover
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: Get.height*0.05),
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
              "assets/images/login_screen.jpg",
            ),
          ),
              SizedBox(
                height: Get.height*0.04,
              ),
              Text(
                "Lets Join With us",
                style: GoogleFonts.poppins(
                    fontSize: 20, fontWeight: FontWeight.w500),
              ),
              Text(
                "Enter Your Mobile Number",
                style: GoogleFonts.poppins(
                    fontSize: 20, fontWeight: FontWeight.w400),
              ),
              SizedBox(
                height: Get.height * 0.06,
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    "Phone Number",
                    style: GoogleFonts.poppins(
                        fontSize: 16, fontWeight: FontWeight.w400),
                  ),
                ),
              ),
              SizedBox(
                height: Get.height * 0.01,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xff636363).withAlpha(51),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: IntlPhoneField(
                      controller: _mobileController,
                      showDropdownIcon: true,
                      flagsButtonMargin: EdgeInsets.only(left: Get.width * 0.02),
                      dropdownIconPosition: IconPosition.trailing,
                      showCountryFlag: false,
                      initialCountryCode: 'IN',
                      autofocus: true,
                      cursorWidth: 1,
                      keyboardType: TextInputType.phone,
                      dropdownTextStyle: TextStyle(
                          color: AppColors.black.withAlpha(180),
                          fontWeight: FontWeight.bold),
                      style: TextStyle(color: AppColors.black),
                      dropdownIcon: Icon(
                        Icons.arrow_drop_down,
                        color: AppColors.black.withAlpha(180),
                      ),
                      decoration: InputDecoration(
                          fillColor: Colors.white,
                          filled: true,
                          hintText: "9876543210",
                          errorStyle: TextStyle(
                              color: Colors.red
                          ),
                          hintStyle: GoogleFonts.poppins(color: AppColors.grey),
                          contentPadding: EdgeInsets.symmetric(vertical: 10,horizontal: 10),
                          counterText: "",
                          border: InputBorder.none),
                      languageCode: "en",
                      onChanged: (phone) {
                        mobileNumber = phone.number.toString();
                      },
                      onCountryChanged: (country) {
                        // print('Country changed to: ' + country.name);
                      },
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: Get.height * 0.04,
              ),
              Obx(() =>  authController.isLoading.value ?  CircularProgressIndicator(
                color: AppColors.primary,
              ) : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GestureDetector(
                  onTap: () {
                    print(mobileNumber);
                    if(mobileNumber?.length == 10){
                      authController.sendOtp(mobileNumber!);
                    }
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
                        ]
                    ),
                    child: Center(
                      child: Text(
                        "Continue",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500,color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),),
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
