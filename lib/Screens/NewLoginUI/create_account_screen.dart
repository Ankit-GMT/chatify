import 'package:chatify/constants/app_colors.dart';
import 'package:chatify/controllers/auth_controller.dart';
import 'package:chatify/widgets/custom_textfield.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class CreateAccountScreen extends StatelessWidget {
  const CreateAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    final _firstNameController = TextEditingController();
    final _lastNameController = TextEditingController();
    final _phoneController = TextEditingController();
    final _dobController = TextEditingController();
    final _emailController = TextEditingController();
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
              Stack(
                children: [
                  Container(
                    height: Get.height * 0.25,
                    width: double.infinity,
                    padding: EdgeInsets.only(top: Get.height * 0.05),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(120),
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
                      "assets/images/create_account.jpg",
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
                "Create Account",
                style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary),
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
                        controller: _firstNameController,
                        hintText: "First Name"),
                    CustomTextfield(
                        controller: _lastNameController, hintText: "Last Name"),
                    CustomTextfield(
                        controller: _phoneController,
                        isPhone: true,
                        hintText: "Mobile Number"),
                    CustomTextfield(
                      controller: _dobController,
                      hintText: "Date of Birth (YYYY-MM-DD)",
                      onTap: () async {
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );

                        if (pickedDate != null) {
                          // format date as DD/MM/YYYY
                          String formattedDate = "${pickedDate.year}-"
                              "${pickedDate.month.toString().padLeft(2, '0')}-"
                              "${pickedDate.day.toString().padLeft(2, '0')}";

                          _dobController.text =
                              formattedDate; // save to controller
                        }
                      },
                    ),
                    CustomTextfield(
                      controller: _emailController,
                      hintText: "Email",
                      isEmail: true,
                    ),
                    Obx(
                      () => CustomTextfield(
                        controller: _passwordController,
                        hintText: "Create Password",
                        isPassword: authController.isHide2.value,
                        suffixIcon: IconButton(
                          onPressed: () {
                            authController.isHide2.value =
                                !authController.isHide2.value;
                          },
                          icon: Icon(authController.isHide2.value
                              ? Icons.visibility_off
                              : Icons.visibility),
                        ),
                      ),
                    ),
                    Obx(
                      () => CustomTextfield(
                        controller: _confirmPasswordController,
                        hintText: "Confirm Password",
                        isPassword: authController.isHide.value,
                        suffixIcon: IconButton(
                          onPressed: () {
                            authController.isHide.value =
                                !authController.isHide.value;
                          },
                          icon: Icon(authController.isHide.value
                              ? Icons.visibility_off
                              : Icons.visibility),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: Get.height * 0.02,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GestureDetector(
                  onTap: authController.isLoading.value
                      ? null
                      : () {
                          //email validation
                          if (!GetUtils.isEmail(_emailController.text.trim())) {
                            Get.snackbar("Error", "Enter a valid email");
                            return;
                          }
                          if (_phoneController.text.trim().length != 10 &&
                              !GetUtils.isPhoneNumber(
                                  _phoneController.text.trim())) {
                            Get.snackbar(
                                "Error", "Enter a valid mobile number");
                            return;
                          }

                          if (_firstNameController.text.isNotEmpty &&
                              _lastNameController.text.isNotEmpty &&
                              _dobController.text.isNotEmpty &&
                              _phoneController.text.isNotEmpty &&
                              _emailController.text.isNotEmpty &&
                              _passwordController.text.isNotEmpty &&
                              _confirmPasswordController.text.isNotEmpty) {
                            authController.createAccount(
                              firstName: _firstNameController.text.trim(),
                              lastName: _lastNameController.text.trim(),
                              phoneNumber: _phoneController.text.trim(),
                              email: _emailController.text.trim(),
                              dateOfBirth: _dobController.text,
                              password: _passwordController.text.trim(),
                              confirmPassword:
                                  _confirmPasswordController.text.trim(),
                              // profileImageFile: authController.pickedImage.value!
                            );
                          } else {
                            Get.snackbar(
                                "Error", "Please fill all the required fields");
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
                        ]),
                    child: Center(
                      child: Obx(
                        () => authController.isLoading.value
                            ? CircularProgressIndicator(
                                color: AppColors.white,
                              )
                            : Text(
                                "Submit",
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
