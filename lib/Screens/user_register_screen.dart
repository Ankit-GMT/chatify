import 'package:chatify/constants/app_colors.dart';
import 'package:chatify/controllers/auth_controller.dart';
import 'package:chatify/controllers/profile_controller.dart';
import 'package:chatify/widgets/custom_textfield.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class UserRegisterScreen extends StatelessWidget {
  const UserRegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final profileController = Get.put(ProfileController());

    TextEditingController firstNameController = TextEditingController();
    TextEditingController lastNameController = TextEditingController();
    TextEditingController emailController = TextEditingController();
    TextEditingController dobController = TextEditingController();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          spacing: 10,
          children: [
            SizedBox(height: Get.height * 0.01),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // IconButton(
                //   color: AppColors.iconGrey,
                //   style: ButtonStyle(
                //     backgroundColor: WidgetStatePropertyAll(AppColors.white),
                //     shape: WidgetStatePropertyAll(
                //       RoundedRectangleBorder(
                //           borderRadius: BorderRadius.circular(20),
                //           side: BorderSide(color: Colors.grey.shade200)),
                //     ),
                //   ),
                //   onPressed: () {
                //     Get.back();
                //   },
                //   icon: Icon(Icons.arrow_left),
                // ),
                // SizedBox(width: Get.width * 0.24),
                Text(
                  "Enter Your Details",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            SizedBox(height: Get.height * 0.01),
            Stack(
              children: [
                Obx(
                  () => profileController.pickedImage.value != null
                      ? CircleAvatar(
                          radius: 56,
                          backgroundImage:
                              FileImage(profileController.pickedImage.value!),
                        )
                      : CircleAvatar(
                          radius: 56,
                          backgroundImage:
                              NetworkImage("https://i.sstatic.net/l60Hf.png"),
                        ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () {
                      profileController.showPickerBottomSheet();
                    },
                    child: CircleAvatar(
                      radius: 13,
                      backgroundColor: AppColors.primary,
                      child: Container(
                        height: 24,
                        width: 24,
                        decoration: BoxDecoration(
                            border: Border.all(
                                width: 1,
                                color: Get.isDarkMode
                                    ? AppColors.black
                                    : AppColors.white),
                            shape: BoxShape.circle),
                        child: Icon(
                          Icons.edit_rounded,
                          size: 14,
                          color: Get.isDarkMode
                              ? AppColors.black
                              : AppColors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(
              height: Get.height * 0.01,
            ),
            Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  "First Name",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                )),
            CustomTextfield(controller: firstNameController, hintText: "Ankit"),
            SizedBox(
              height: Get.height * 0.005,
            ),
            Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  "Last Name",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                )),
            CustomTextfield(controller: lastNameController, hintText: "Patel"),
            SizedBox(
              height: Get.height * 0.005,
            ),
            Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  "Email (optional)",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                )),
            CustomTextfield(
                controller: emailController,
                hintText: "ankitpatel@example.com"),
            SizedBox(
              height: Get.height * 0.005,
            ),
            Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  "Date Of Birth",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                )),
            CustomTextfield(
              controller: dobController,
              hintText: "YYYY-MM-DD",
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

                  dobController.text = formattedDate; // save to controller
                }
              },
            ),
            SizedBox(
              height: Get.height * 0.01,
            ),
            Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Color(0xff959DA5).withAlpha(51),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  minimumSize: Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  if (firstNameController.text.isNotEmpty &&
                      lastNameController.text.isNotEmpty &&
                      dobController.text.isNotEmpty) {
                    authController.registerUser(
                        firstName: firstNameController.text,
                        lastName: lastNameController.text,
                        phoneNumber: authController.phoneNumber.value,
                        dateOfBirth: dobController.text,
                        profileImageUrl: "https://i.sstatic.net/l60Hf.png");
                  } else {
                    Get.snackbar(
                        "Error", "Please fill all the required fields");
                  }
                },
                child: Text("Continue"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
