import 'package:chatify/Screens/otp_screen.dart';
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

    final authController = Get.put(AuthController());

    TextEditingController _mobileController = TextEditingController();

    String selectedCode = "+91";

    String? mobileNumber;
    return Scaffold(
      // backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                IconButton(
                  color: AppColors.iconGrey,
                  style: ButtonStyle(
                    backgroundColor: WidgetStatePropertyAll(AppColors.white),
                    shape: WidgetStatePropertyAll(
                      RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(color: Colors.grey.shade200)),
                    ),
                  ),
                  onPressed: () {},
                  icon: Icon(Icons.arrow_left),
                ),
              ],
            ),
            SizedBox(
              height: Get.height * 0.15,
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
              child: Text(
                "Phone Number",
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w400),
              ),
            ),
            SizedBox(
              height: Get.height * 0.01,
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xff63636333).withAlpha(51),
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
                      hintStyle: GoogleFonts.poppins(color: AppColors.grey),
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
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
            SizedBox(
              height: Get.height * 0.04,
            ),
            GestureDetector(
              onTap: () {
                print(mobileNumber);
                if(mobileNumber?.length == 10){
                  authController.sendOtp(mobileNumber!);
                }
              },
              child: Container(
                width: double.infinity,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xff63636333).withAlpha(51),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: authController.isLoading.value
                      ? CircularProgressIndicator(
                          color: AppColors.primary,
                        )
                      : Text(
                          "Continue",
                          style: GoogleFonts.poppins(
                              color: AppColors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w400),
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
    );
  }
}
